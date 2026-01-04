import subprocess
import os
import sys
import shutil

# --- CONFIGURATION ---
ENV_FILE = ".env"
CONTAINER_NAME = "db_core"
ROOT_USER = "root_admin"
CHATWOOT_DATA_VOLUME = "chatwoot_data"

def sanitize_env():
    print("\n🧹 [1/4] Sanitizando Archivo .env...")
    if not os.path.exists(ENV_FILE):
        print(f"❌ Error: {ENV_FILE} not found.")
        return

    # Backup only if not recently backed up (or simple overwrite)
    shutil.copy(ENV_FILE, f"{ENV_FILE}.bak")
    
    new_lines = []
    changes_made = False
    
    with open(ENV_FILE, "r", encoding="utf-8") as f:
        for line in f:
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                new_lines.append(line)
                continue
            
            if "=" in line:
                key, val = line.split("=", 1)
                if "#" in val:
                    clean_val = val.split("#")[0].strip()
                    if clean_val != val.strip():
                        changes_made = True
                        val = clean_val
                new_lines.append(f"{key}={val}\n")
            else:
                new_lines.append(line)
    
    if changes_made:
        with open(ENV_FILE, "w", encoding="utf-8") as f:
            f.writelines(new_lines)
        print("   ✅ .env limpiado de comentarios inline.")
    else:
        print("   ✅ .env ya estaba limpio.")

def clean_stale_pids():
    print("\n💀 [2/4] Buscando PIDs Zombis (Chatwoot)...")
    # Using busybox to attach to volume and clean
    cmd = [
        "docker", "run", "--rm", 
        "-v", f"{CHATWOOT_DATA_VOLUME}:/app/storage", 
        "busybox", "rm", "-f", 
        "/app/storage/pids/server.pid", 
        "/app/tmp/pids/server.pid"
    ]
    try:
        subprocess.run(cmd, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print("   ✅ Limpieza de PIDs completada.")
    except Exception as e:
        print(f"   ⚠️ No se pudo limpiar PIDs (¿Docker corriendo?): {e}")

def load_env():
    env_vars = {}
    if not os.path.exists(ENV_FILE):
        return {}
    with open(ENV_FILE, 'r') as f:
        for line in f:
            if '=' in line and not line.startswith('#'):
                parts = line.strip().split('=', 1)
                if len(parts) == 2:
                    env_vars[parts[0]] = parts[1]
    return env_vars

def run_sql(db, sql, password):
    cmd = [
        "docker", "exec", "-e", f"PGPASSWORD={password}", 
        CONTAINER_NAME, "psql", "-U", ROOT_USER, "-d", db, 
        "-c", sql
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        # Don't spam if container is down, just warn
        pass 
    return result

def fix_db_permissions(env):
    print("\n🔐 [3/4] Reparando Permisos y Extensiones DB...")
    root_pass = env.get("POSTGRES_ROOT_PASSWORD")
    if not root_pass:
        print("   ⚠️ No se encontró password root en .env, saltando DB fix.")
        return

    # 1. Extensions
    extensions = ["pg_trgm", "pgcrypto", "pg_stat_statements", "btree_gin"]
    for ext in extensions:
        run_sql("chatwoot", f"CREATE EXTENSION IF NOT EXISTS {ext};", root_pass)
    
    # 2. Schema Permissions
    apps = {
        "chatwoot": "chatwoot_user",
        "evolution": "evolution_user",
        "n8n": "n8n_user"
    }
    for db, user in apps.items():
        run_sql(db, f"GRANT ALL ON SCHEMA public TO {user};", root_pass)
    
    # 3. Sync Passwords
    passwords = {
        "chatwoot_user": env.get("CHATWOOT_DB_PASSWORD"),
        "evolution_user": env.get("EVOLUTION_DB_PASSWORD"),
        "n8n_user": env.get("N8N_DB_PASSWORD")
    }
    for user, pwd in passwords.items():
        if pwd:
            run_sql("postgres", f"ALTER USER {user} WITH PASSWORD '{pwd}';", root_pass)
    
    print("   ✅ Mantenimiento DB finalizado.")

def main():
    print("⚕️  SENTINEL FIXER v2.0: Auto-Reparación Iniciada...")
    
    # 1. Filesystem & Env Fixes (Can run anytime)
    sanitize_env()
    clean_stale_pids()
    
    # 2. Load Env for DB Ops
    env = load_env()
    
    # 3. DB Fixes (Needs DB container up)
    # Check if DB is up to avoid errors
    db_check = subprocess.run(["docker", "ps", "-q", "-f", f"name={CONTAINER_NAME}"], capture_output=True, text=True)
    if db_check.stdout.strip():
        fix_db_permissions(env)
    else:
        print("\n⏳ [3/4] Base de datos apagada. Omitiendo arreglos SQL.")
        
    print("\n✨ SISTEMA OPTIMIZADO Y LISTO.")

if __name__ == "__main__":
    main()
