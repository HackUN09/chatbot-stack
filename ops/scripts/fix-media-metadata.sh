#!/bin/sh
# ================================================================
# fix-media-metadata.sh — Run INSIDE core_minio container
# Fixes Content-Type and Content-Disposition on all audio/video
# files in the chatwoot-storage bucket.
# ================================================================

ALIAS="local"
BUCKET="chatwoot-storage"

echo "🔧 [MEDIA-FIX] Scanning for audio/video files..."

# Get all objects as JSON and process audio files (audio/opus → audio/ogg, inline)
AUDIO_COUNT=0
for key in $(mc stat ${ALIAS}/${BUCKET}/ --recursive --json 2>/dev/null | \
  grep '"Content-Type":"audio/' | \
  sed 's/.*"name":"\([^"]*\)".*/\1/'); do
    mc cp --attr "Content-Type=audio/ogg;Content-Disposition=inline" \
        "${ALIAS}/${BUCKET}/${key}" "${ALIAS}/${BUCKET}/${key}" 2>/dev/null && \
        AUDIO_COUNT=$((AUDIO_COUNT + 1))
done
echo "  ✅ Fixed ${AUDIO_COUNT} audio files (audio/ogg + inline)"

# Fix video files (keep video/mp4, set inline)
VIDEO_COUNT=0
for key in $(mc stat ${ALIAS}/${BUCKET}/ --recursive --json 2>/dev/null | \
  grep '"Content-Type":"video/' | \
  sed 's/.*"name":"\([^"]*\)".*/\1/'); do
    mc cp --attr "Content-Type=video/mp4;Content-Disposition=inline" \
        "${ALIAS}/${BUCKET}/${key}" "${ALIAS}/${BUCKET}/${key}" 2>/dev/null && \
        VIDEO_COUNT=$((VIDEO_COUNT + 1))
done
echo "  ✅ Fixed ${VIDEO_COUNT} video files (inline)"

echo "🎉 Total: ${AUDIO_COUNT} audio + ${VIDEO_COUNT} video files fixed!"
