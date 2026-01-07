
import os
import subprocess

def get_env_file_key():
    try:
        with open('.env', 'r', encoding='utf-8') as f:
            for line in f:
                if line.startswith('EVOLUTION_API_KEY='):
                    return line.strip().split('=', 1)[1]
    except Exception as e:
        return f"Error reading .env: {e}"
    return "Not Found in .env"

def get_container_key():
    try:
        # PowerShell might mess up encoding, so we decode carefully
        result = subprocess.run(['docker', 'exec', 'app_evolution', 'printenv', 'AUTHENTICATION_API_KEY'], capture_output=True)
        return result.stdout.decode('utf-8').strip()
    except Exception as e:
        return f"Error reading container: {e}"

def get_container_vite_key():
    try:
        result = subprocess.run(['docker', 'exec', 'app_evolution', 'printenv', 'VITE_EVOLUTION_API_KEY'], capture_output=True)
        return result.stdout.decode('utf-8').strip()
    except Exception as e:
        return f"Error reading container VITE key: {e}"

def main():
    env_key = get_env_file_key()
    cont_key = get_container_key()
    vite_key = get_container_vite_key()
    
    print(f"ENV File Key Length: {len(env_key)}")
    print(f"Container Auth Key Length: {len(cont_key)}")
    print(f"Container VITE Key Length: {len(vite_key)}")
    
    if env_key == cont_key == vite_key:
        print("✅ ALL Keys MATCH perfectly.")
    else:
        print("❌ Key MISMATCH detected.")
        if env_key != cont_key: print(f"ENV vs AUTH mismatch.")
        if cont_key != vite_key: print(f"AUTH vs VITE mismatch (Critical for Frontend!).")
        
        print(f"ENV Key:  [{repr(env_key)}]")
        print(f"AUTH Key: [{repr(cont_key)}]")
        print(f"VITE Key: [{repr(vite_key)}]")

if __name__ == '__main__':
    main()
