
import os
import re

def reconstruct_env():
    env_path = ".env"
    if not os.path.exists(env_path):
        print("No .env found")
        return

    # Read binary
    with open(env_path, "rb") as f:
        data = f.read()
    
    # Extract strings using regex (K=V)
    # We look for alphanumeric keys and any printable value
    # This is a VERY aggressive clean
    extracted = {}
    
    # Try to decode what we can
    text = data.decode('ascii', errors='ignore')
    
    # Simple line parsing
    for line in text.replace('\r', '\n').split('\n'):
        line = line.strip()
        if "=" in line and not line.startswith("#"):
            k, v = line.split("=", 1)
            k = k.strip()
            v = v.strip()
            # If key starts with weird chars, fix it
            # Relaxed regex to allow lowecase and common env chars
            k = re.sub(r'[^a-zA-Z0-9_]', '', k)
            if k:
                # Remove ANY internal whitespace from keys that should be tokens/passwords
                if any(x in k for x in ["KEY", "TOKEN", "PASSWORD"]):
                    v = "".join(v.split())
                extracted[k] = v

    # Write back in a clean format
    lines = []
    for k in sorted(extracted.keys()):
        lines.append(f"{k}={extracted[k]}")
    
    with open(env_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    
    print(f"Reconstructed .env with {len(extracted)} variables.")

if __name__ == "__main__":
    reconstruct_env()
