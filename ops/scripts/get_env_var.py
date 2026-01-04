import os
import sys

def get_var(key, filepath=".env"):
    if not os.path.exists(filepath):
        return ""
    
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            # Skip comments or empty lines
            if not line or line.startswith("#"):
                continue
            
            # Check for key
            if line.startswith(f"{key}="):
                # Split only on first =
                val = line.split("=", 1)[1]
                # Strip inline comments (anything after #)
                val = val.split("#")[0].strip()
                return val
    return ""

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("")
        sys.exit(1)
    
    key = sys.argv[1]
    # Default to .env in current directory or parent logic if needed
    # Assuming script is called from project root
    print(get_var(key))
