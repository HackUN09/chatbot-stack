import subprocess
import os
import sys
import shutil
import json
import argparse

# --- CONFIGURATION ---
ENV_FILE = ".env"
CONTAINER_NAME = "db_core"
ROOT_USER = "root_admin"
CHATWOOT_DATA_VOLUME = "chatwoot_data"
EVOLUTION_CONTAINER = "app_evolution"

def sanitize_env(silent=False):
    if not silent: print("\n🧹 [1/5] Vigilancia Sentinel: Blindando .env (Modo Dios)...")
    if not os.path.exists(ENV_FILE):
        if not silent: print("   ⚠️ Archivo .env no encontrado!")
        return

    # Deep Scrubbing Logic
    shutil.copy(ENV_FILE, f"{ENV_FILE}.bak")
    
    clean_lines = []
    clean_env = {}
    try:
        with open(ENV_FILE, "rb") as f:
            content = f.read().replace(b'\x00', b'')
            text = content.decode('utf-8', errors='ignore')
            
        for line in text.splitlines():
            line = line.strip()
            if not line:
                clean_lines.append("")
                continue
            if line.startswith("#"):
                clean_lines.append(line)
                continue
                
            if "=" in line:
                key, val = line.split("=", 1)
                val_clean = val.split("#")[0].strip()
                if (val_clean.startswith('"') and val_clean.endswith('"')) or \
                   (val_clean.startswith("'") and val_clean.endswith("'")):
                    val_clean = val_clean[1:-1]
                
                key_clean = key.strip()
                clean_env[key_clean] = val_clean
                clean_lines.append(f"{key_clean}={val_clean}")

        # Auto-Sync Critical Keys
        evo_key = clean_env.get("EVOLUTION_API_KEY")
        if evo_key:
            clean_env["VITE_EVOLUTION_API_KEY"] = evo_key
            
            final_output = []
            keys_in_output = set()
            for line in clean_lines:
                if "=" in line:
                    k = line.split("=")[0]
                    if k in clean_env:
                        final_output.append(f"{k}={clean_env[k]}")
                        keys_in_output.add(k)
                    else:
                        final_output.append(line)
                else:
                    final_output.append(line)
            
            if "VITE_EVOLUTION_API_KEY" not in keys_in_output:
                final_output.append(f"VITE_EVOLUTION_API_KEY={evo_key}")

            with open(ENV_FILE, "w", encoding="utf-8") as f:
                for line in final_output:
                    f.write(f"{line}\n")
        
        if not silent: print("   ✅ Archivo .env blindado y sincronizado.")
    except Exception as e:
        if not silent: print(f"   ❌ Error fatal sanitizando .env: {e}")

def clean_stale_pids(silent=False):
    if not silent: print("\n💀 [2/5] Buscando PIDs Zombis (Auto-Heal)...")
    cmd = [
        "docker", "run", "--rm", 
        "-v", f"{CHATWOOT_DATA_VOLUME}:/app/storage", 
        "busybox", "rm", "-f", 
        "/app/storage/pids/server.pid", 
        "/app/tmp/pids/server.pid"
    ]
    try:
        subprocess.run(cmd, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if not silent: print("   ✅ Limpieza de PIDs completada.")
    except Exception as e:
        if not silent: print(f"   ⚠️ No se pudo limpiar PIDs: {e}")

def fix_db_permissions(env, silent=False):
    if not silent: print("\n🔐 [3/5] Reparando Permisos y Extensiones DB (Autónomo)...")
    root_pass = env.get("POSTGRES_ROOT_PASSWORD")
    if not root_pass:
        return

    extensions = ["pg_trgm", "pgcrypto", "pg_stat_statements", "btree_gin"]
    for ext in extensions:
        run_sql("chatwoot", f"CREATE EXTENSION IF NOT EXISTS {ext};", root_pass)
    
    apps = {
        "chatwoot": "chatwoot_user",
        "evolution": "evolution_user",
        "n8n": "n8n_user"
    }
    for db, user in apps.items():
        run_sql(db, f"GRANT ALL ON SCHEMA public TO {user};", root_pass)
    
    if not silent: print("   ✅ Mantenimiento DB finalizado.")

def verify_and_heal_evolution(env, force_heal=False, silent=False):
    if not silent: print("\n🔬 [4/5] Escaneo Quirúrgico de Instancias Evolution API...")
    api_key = env.get("EVOLUTION_API_KEY")
    port = env.get("EVOLUTION_PORT") or "8080"
    
    try:
        cmd = [
            "docker", "exec", EVOLUTION_CONTAINER, 
            "curl", "-s", "-X", "GET", 
            "-H", f"apikey: {api_key}",
            f"http://localhost:{port}/instance/fetchInstances"
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            try:
                instances = json.loads(result.stdout)
                for inst in instances:
                    name = inst.get("instanceName")
                    status = inst.get("status")
                    if not silent: print(f"      - [{name}]: {status}")
                    
                    # God Mode: Auto-purge if status is problematic
                    if status in ["ERROR", "DISCONNECTED", "CLOSED"] or force_heal:
                        if not silent: print(f"      🚨 Curando instancia '{name}' (Purga de Sesión)...")
                        purge_cmd = ["docker", "exec", EVOLUTION_CONTAINER, "rm", "-rf", f"/evolution/instances/{name}"]
                        subprocess.run(purge_cmd, check=False)
                        if not silent: print(f"      ✅ Instancia '{name}' restaurada a estado virgen.")
            except:
                if not silent: print(f"   ⚠️ Respuesta de API inválida.")
        else:
            if not silent: print(f"   ⚠️ No se pudo conectar a la API interna.")
    except Exception as e:
        if not silent: print(f"   ⚠️ Error verificando instancias: {e}")

def final_report(silent=False):
    if not silent:
        print("\n✨ STATUS: HIPER-INTEGRIDAD AL 100%. MODO DIOS ACTIVO.")

def load_env():
    env_vars = {}
    if not os.path.exists(ENV_FILE):
        return {}
    with open(ENV_FILE, 'r', encoding="utf-8", errors="ignore") as f:
        for line in f:
            if '=' in line and not line.startswith('#'):
                parts = line.strip().split('=', 1)
                if len(parts) == 2:
                    env_vars[parts[0]] = parts[1].split("#")[0].strip()
    return env_vars

def run_sql(db, sql, password):
    cmd = [
        "docker", "exec", "-e", f"PGPASSWORD={password}", 
        CONTAINER_NAME, "psql", "-U", ROOT_USER, "-d", db, 
        "-c", sql
    ]
    return subprocess.run(cmd, capture_output=True, text=True)

def main():
    parser = argparse.ArgumentParser(description="Sentinel God Mode Fixer")
    parser.add_argument("--force", action="store_true", help="Force deep healing of all instances")
    parser.add_argument("--silent", action="store_true", help="Run without output")
    args = parser.parse_args()

    if not args.silent:
        print("⚕️  SENTINEL FIXER v5.0 [GOD MODE]: Curación Autónoma en Proceso...")
    
    sanitize_env(args.silent)
    clean_stale_pids(args.silent)
    
    env = load_env()
    
    db_check = subprocess.run(["docker", "ps", "-q", "-f", f"name={CONTAINER_NAME}"], capture_output=True, text=True)
    if db_check.stdout.strip():
        fix_db_permissions(env, args.silent)
    
    evo_check = subprocess.run(["docker", "ps", "-q", "-f", f"name={EVOLUTION_CONTAINER}"], capture_output=True, text=True)
    if evo_check.stdout.strip():
        verify_and_heal_evolution(env, args.force, args.silent)
    
    final_report(args.silent)

if __name__ == "__main__":
    main()
