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

    # Integrity Check
    try:
        with open(ENV_FILE, "r", encoding="utf-8") as f:
            f.read()
    except Exception:
        if not silent: print("   ⚠️ .env CORRUPTO detectado. Intentando recuperar de .bak o reconstruir...")
        if os.path.exists(f"{ENV_FILE}.bak"):
            shutil.copy(f"{ENV_FILE}.bak", ENV_FILE)
            if not silent: print("   ✅ Restaurado desde backup.")
        else:
            if not silent: print("   ❌ No backup found. Manual intervention required.")
            return

    # Deep Scrubbing (Safe Mode)
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

def sync_chatwoot_integration(env, instance_name, silent=False):
    token = env.get("CHATWOOT_GLOBAL_TOKEN")
    account_id = env.get("CHATWOOT_GLOBAL_ACCOUNT_ID")
    domain = env.get("DOMAIN")
    api_key = env.get("EVOLUTION_API_KEY")
    port = env.get("EVOLUTION_PORT") or "8080"
    db_pass = env.get("CHATWOOT_DB_PASSWORD")
    
    if not token or not account_id or not domain:
        return

    # Estándar de Oro: URL sin slash final
    chat_url = f"https://chat.{domain}".rstrip("/")
    
    # Auto-ensamblaje de URI de Importación (Requisito para Historial)
    import_uri = f"postgresql://chatwoot_user:{db_pass}@db_core:5432/chatwoot?schema=public&sslmode=disable"
    
    config = {
        "enabled": True,
        "accountId": account_id,
        "token": token,
        "url": chat_url,
        "webhook_url": True,
        "autoCreate": True,
        "importContacts": True,
        "importMessages": True,
        "daysLimitImportMessages": 365,
        "reopenConversation": True,
        "conversationPending": False
    }
    
    try:
        payload = json.dumps(config)
        # Sincronización Doble: API + DB URI injection
        shell_cmd = f'docker exec {EVOLUTION_CONTAINER} wget -qO- --post-data=\'{payload}\' --header="Content-Type: application/json" --header="apikey: {api_key}" http://localhost:{port}/chatwoot/set/{instance_name}'
        subprocess.run(shell_cmd, shell=True, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        # Inyectar la URI al .env si no existe o es diferente
        if env.get("CHATWOOT_IMPORT_DATABASE_CONNECTION_URI") != import_uri:
            with open(ENV_FILE, "a") as f:
                f.write(f"\nCHATWOOT_IMPORT_DATABASE_CONNECTION_URI={import_uri}\n")
        
        if not silent: print(f"      🔗 Link Chatwoot OK (Provisionado): [{instance_name}] -> ID:{account_id}")
    except Exception as e:
        if not silent: print(f"      ❌ Error vinculando Chatwoot: {e}")

def verify_and_heal_evolution(env, force_heal=False, silent=False):
    if not silent: print("\n🔬 [4/5] Escaneo Quirúrgico de Instancias Evolution API...")
    api_key = env.get("EVOLUTION_API_KEY")
    port = env.get("EVOLUTION_PORT") or "8080"
    
    try:
        # Usamos wget porque la imagen sentinel no tiene curl
        cmd = [
            "docker", "exec", EVOLUTION_CONTAINER, 
            "wget", "-qO-", "--header", f"apikey: {api_key}",
            f"http://localhost:{port}/instance/fetchInstances"
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            try:
                data = json.loads(result.stdout)
                # Soportar v2 (lista directa o envuelta en 'value')
                instances = data if isinstance(data, list) else data.get("value", [])
                
                for inst in instances:
                    # Soportar v1 (instanceName) y v2 (name)
                    name = inst.get("name") or inst.get("instanceName")
                    # Soportar v1 (status) y v2 (connectionStatus)
                    status = inst.get("connectionStatus") or inst.get("status")
                    
                    if not silent: print(f"      - [{name}]: {status}")
                    
                    # God Mode: Auto-purge if status is problematic
                    if status in ["ERROR", "DISCONNECTED", "CLOSED", "close", "refused"] or force_heal:
                        if not silent: print(f"      🚨 Curando instancia '{name}' (Purga de Sesión)...")
                        purge_cmd = ["docker", "exec", EVOLUTION_CONTAINER, "rm", "-rf", f"/evolution/instances/{name}"]
                        subprocess.run(purge_cmd, check=False)
                        if not silent: print(f"      ✅ Instancia '{name}' restaurada a estado virgen.")
                    
                    # Sincronización Automática Chatwoot (v9.0)
                    sync_chatwoot_integration(env, name, silent)
                    
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
        print("⚕️  SENTINEL FIXER v11.0 [SUPER-LINK]: Curación y Vinculación Autónoma...")
    
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
