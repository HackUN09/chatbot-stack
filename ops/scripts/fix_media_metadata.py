"""
fix_media_metadata.py — Fixes audio/video metadata in MinIO chatwoot-storage bucket.
Run from the chatbot-stack root directory.
"""
import subprocess
import json
import sys

BUCKET = "chatwoot-storage"

def get_objects_with_metadata():
    """Get all objects from chatwoot-storage with their metadata."""
    cmd = ["docker", "exec", "core_minio", "mc", "stat", f"local/{BUCKET}/", "--recursive", "--json"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    objects = []
    for line in result.stdout.splitlines() + result.stderr.splitlines():
        line = line.strip()
        if not line or not line.startswith('{'):
            continue
        try:
            obj = json.loads(line)
            if obj.get("status") == "success" and obj.get("metadata"):
                objects.append(obj)
        except json.JSONDecodeError:
            continue
    return objects

def fix_object(name, content_type, content_disposition):
    """Fix an object's metadata using mc cp --attr."""
    src = f"local/{BUCKET}/{name}"
    cmd = [
        "docker", "exec", "core_minio", "mc", "cp",
        "--attr", f"Content-Type={content_type};Content-Disposition={content_disposition}",
        src, src
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.returncode == 0

def main():
    print("[MEDIA-FIX] Scanning chatwoot-storage for audio/video files...")
    objects = get_objects_with_metadata()
    print(f"   Found {len(objects)} total objects in bucket")

    audio_fixed = 0
    video_fixed = 0
    errors = 0

    for obj in objects:
        name = obj["name"]
        meta = obj.get("metadata", {})
        ct = meta.get("Content-Type", "")
        cd = meta.get("Content-Disposition", "")

        needs_fix = False

        # Fix audio files: audio/opus → audio/ogg, attachment → inline
        if "audio/" in ct:
            if ct != "audio/ogg" or "attachment" in cd:
                needs_fix = True
                print(f"   [FIX] Audio: {name[:20]}... ({ct} -> audio/ogg, inline)")
                if fix_object(name, "audio/ogg", "inline"):
                    audio_fixed += 1
                else:
                    errors += 1
                    print(f"   [ERR] Failed to fix {name}")

        # Fix video files: keep video/mp4, attachment → inline
        elif "video/" in ct:
            if "attachment" in cd:
                needs_fix = True
                print(f"   [FIX] Video: {name[:20]}... (inline)")
                if fix_object(name, ct, "inline"):
                    video_fixed += 1
                else:
                    errors += 1
                    print(f"   [ERR] Failed to fix {name}")

    print(f"\n[MEDIA-FIX] Complete!")
    print(f"   Audio fixed:  {audio_fixed}")
    print(f"   Video fixed:  {video_fixed}")
    print(f"   Errors:       {errors}")

if __name__ == "__main__":
    main()
