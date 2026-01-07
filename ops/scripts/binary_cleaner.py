
import os

def sanitize_env_binary():
    env_path = ".env"
    if not os.path.exists(env_path):
        print("No .env found")
        return

    with open(env_path, "rb") as f:
        raw_content = f.read()

    # Filter: Keep only ASCII 32-126 (printable), 10 (\n), 13 (\r), and 9 (\t)
    # Also remove any NULL bytes (0)
    clean_bytes = bytearray()
    for b in raw_content:
        if b == 0: continue # Skip Nulls
        if 32 <= b <= 126 or b in [9, 10, 13]:
            clean_bytes.append(b)

    # Convert to string and split into lines to normalize endings
    content_str = clean_bytes.decode('ascii', errors='ignore')
    lines = content_str.replace('\r\n', '\n').replace('\r', '\n').split('\n')
    
    final_lines = []
    for line in lines:
        line = line.strip()
        if not line:
            final_lines.append("")
            continue
        if "=" in line:
            parts = line.split("=", 1)
            k = parts[0].strip()
            v = parts[1].strip()
            # If it's one of the problematic keys, ensure NO internal spaces
            if any(x in k for x in ["KEY", "TOKEN", "PASSWORD"]):
                v = "".join(v.split())
            final_lines.append(f"{k}={v}")
        else:
            final_lines.append(line)

    with open(env_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(final_lines))
    
    print("Sanitized .env file (Binary Fix Applied)")

if __name__ == "__main__":
    sanitize_env_binary()
