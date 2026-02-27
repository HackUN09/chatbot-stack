import os
import json
import urllib.request
import urllib.error
import time
import sys
import re
import subprocess
import argparse

# --- [00] CONFIGURATION ---
# Load master .env settings
# Load master .env settings with fallback encoding support
def load_env():
    env = {}
    encodings = ['utf-8', 'cp1252', 'latin-1'] # Priority: UTF-8 -> Windows -> Generic
    
    for encoding in encodings:
        try:
            with open('.env', 'r', encoding=encoding) as f:
                for line in f:
                    if '=' in line and not line.strip().startswith('#'):
                        key, val = line.strip().split('=', 1)
                        env[key] = val
            break # Success, stop trying encodings
        except (UnicodeDecodeError, FileNotFoundError):
            continue
            
    return env

ENV = load_env()

# --- [01] API UTILS ---
def call_api(endpoint, payload=None, method='POST', max_retries=3):
    base_url = "http://localhost:8080"
    api_key = ENV.get('EVOLUTION_API_KEY')
    if not api_key:
        return False, "EVOLUTION_API_KEY not set in environment"

    headers = {"Content-Type": "application/json", "apikey": api_key}
    url = f"{base_url}{endpoint}"
    payload_str = json.dumps(payload) if payload else None
    data = payload_str.encode('utf-8') if payload_str else None

    for attempt in range(max_retries):
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req) as response:
                return True, json.loads(response.read().decode('utf-8'))
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8')
            if e.code == 401:
                return False, f"401 Unauthorized: {error_body}"
            return False, f"HTTP Error {e.code}: {error_body}"
        except Exception as e:
            if attempt == max_retries - 1:
                return False, str(e)
            time.sleep(2 ** attempt)

def setup_s3():
    """Crea buckets en MinIO y aplica políticas de acceso público usando mc dentro del container."""
    print("  [S3] Configurando Buckets en MinIO...")
    if not check_service("MinIO Storage", url="http://localhost:9000/minio/health/live"):
        return

    minio_user = ENV.get('MINIO_ROOT_USER', 'minioadmin')
    minio_pass = ENV.get('MINIO_ROOT_PASSWORD', 'minioadmin')
    evo_bucket = ENV.get('EVOLUTION_BUCKET', ENV.get('S3_BUCKET', 'evolution-media'))
    cw_bucket  = ENV.get('CHATWOOT_BUCKET', ENV.get('STORAGE_BUCKET_NAME', 'chatwoot-storage'))

    # Paso 1: Crear alias local dentro del container minio-core
    alias_cmd = [
        "docker", "exec", "minio-core",
        "mc", "alias", "set", "local",
        "http://localhost:9000", minio_user, minio_pass
    ]
    res_alias = subprocess.run(alias_cmd, capture_output=True, text=True, check=False)
    if res_alias.returncode != 0:
        print(f"    [ERROR] No se pudo crear alias mc: {res_alias.stderr.strip()}")
        return

    # Paso 2: Crear y configurar cada bucket
    for bucket_name in [evo_bucket, cw_bucket]:
        # Crear bucket (idempotente)
        mb_cmd = ["docker", "exec", "minio-core", "mc", "mb", "--ignore-existing", f"local/{bucket_name}"]
        res_mb = subprocess.run(mb_cmd, capture_output=True, text=True, check=False)
        if res_mb.returncode == 0:
            print(f"    [OK] Bucket '{bucket_name}' garantizado.")
        else:
            print(f"    [WARN] mb resultado: {res_mb.stderr.strip()}")

        # Aplicar política pública de descarga
        policy_cmd = ["docker", "exec", "minio-core", "mc", "anonymous", "set", "download", f"local/{bucket_name}"]
        res_pol = subprocess.run(policy_cmd, capture_output=True, text=True, check=False)
        if res_pol.returncode == 0:
            print(f"    [OK] Política pública aplicada a '{bucket_name}'.")
        else:
            print(f"    [WARN] Policy resultado: {res_pol.stderr.strip()}")

    print("    [S3] Setup completo.")

def setup_chatwoot():
    print("  [CW] Inicializando Admin, Cuenta e Inbox...")
    if not check_service("Chatwoot Web", url="http://localhost:3000/auth/sign_in", retries=60):
        print("    [WARN] Chatwoot no está listo, pero intentaremos la configuración vía Rails runner...")
    admin_email = ENV.get('CHATWOOT_ADMIN_EMAIL', 'capsule.cor.arauca@gmail.com')
    admin_pass = ENV.get('CHATWOOT_ADMIN_PASSWORD', 'HackUN1991.1')
    
    # Surgical Ruby script for Chatwoot onboarding
    # Fixes the 'User/AccountUser must exist' by following precise order
    ruby_script = f"begin; " \
                  f"u = User.find_by(email: '{admin_email}') || User.new(email: '{admin_email}'); " \
                  f"u.name = 'Administrator'; u.password = '{admin_pass}'; u.password_confirmation = '{admin_pass}'; " \
                  f"u.confirmed_at = Time.now; u.save!; " \
                  f"a = Account.first || Account.create!(name: 'Isekai Stack'); " \
                  f"au = AccountUser.find_by(account_id: a.id, user_id: u.id) || AccountUser.create!(account: a, user: u, role: :administrator); " \
                  f"Current.account = a; Current.user = u; " \
                  f"inbox = a.inboxes.find_by(name: 'test'); " \
                  f"if inbox.nil?; " \
                  f"  ch = Channel::Api.create!(account: a); " \
                  f"  inbox = a.inboxes.create!(name: 'test', account: a, channel: ch); " \
                  f"end; " \
                  f"unless inbox.members.include?(u); " \
                  f"  mb = inbox.inbox_members.new(user_id: u.id); " \
                  f"  mb.save!; " \
                  f"end; " \
                  f"puts 'CW_SETUP_OK'; " \
                  f"puts 'TOKEN:' + u.access_token.token if u.access_token; " \
                  f"rescue => e; puts 'ERROR:' + e.message; end"

    cmd = ["docker", "exec", "-e", "RUBYOPT=-W0", "chatwoot-web", "bin/rails", "runner", ruby_script]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        output = result.stdout + result.stderr
        
        # Clarification for the user: 
        # 1. Real errors (ERROR:) are captured and displayed.
        # 2. Technical debris (Warnings) is filtered out.
        if "CW_SETUP_OK" in output:
            token_match = re.search(r'TOKEN:(\S+)', output)
            if token_match:
                token = token_match.group(1)
                print(f"    [OK] Admin configurado. Token: {token[:8]}...")
                # Auto-inject into .env
                if os.path.exists('.env'):
                    with open('.env', 'r') as f:
                        lines = f.readlines()
                    with open('.env', 'w') as f:
                        for line in lines:
                            if line.startswith('CHATWOOT_GLOBAL_TOKEN='):
                                f.write(f'CHATWOOT_GLOBAL_TOKEN={token}\n')
                            else:
                                f.write(line)
                    print("    [AUTO] Token inyectado quirúrgicamente en .env")
            else:
                print("    [OK] Chatwoot Admin Initialized")
        elif "ERROR:" in output:
            error_msg = re.search(r'ERROR:(.*)', output)
            print(f"    [ERROR] Error Real Detectado: {error_msg.group(1) if error_msg else 'Fallo de validación'}")
        elif result.returncode != 0:
            print(f"    [ERROR] Fallo Crítico de Rails (Code {result.returncode})")
            
    except Exception as e:
        print(f"    [ERROR] Fallo de Orquestación: {e}")

# --- [02] ACTIONS ---

def prepare_chatwoot_db():
    print("🛠️ [ CW_PREP ] Verificando Esquema de Base de Datos...")

    check_cmd = ["docker", "exec", "-e", "RUBYOPT=-W0", "chatwoot-web", "bin/rails", "runner",
                 "begin; puts User.count; rescue; puts 'MISSING_TABLES'; end"]

    print("    [CHECK] Conectando con Rails Environment...")
    needs_migration = False

    for i in range(15):
        res = subprocess.run(check_cmd, capture_output=True, text=True, check=False)
        output = res.stdout + res.stderr

        if "MISSING_TABLES" in output or 'Relation "users" does not exist' in output:
            needs_migration = True
            print("    [INFO] Tablas no encontradas. Se requiere migración inicial.")
            break
        elif res.returncode == 0 and re.search(r'^\d+$', output.strip()):
            print(f"    [OK] Esquema detectado ({output.strip()} usuarios).")
            return
        else:
            time.sleep(3)

    if needs_migration:
        print("    [AUTO] Ejecutando Migraciones (Esto puede tardar 1-2 minutos)...")
        migrate_cmd = ["docker", "exec", "-e", "RUBYOPT=-W0", "chatwoot-web",
                       "bundle", "exec", "rails", "db:prepare"]
        proc = subprocess.Popen(migrate_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in proc.stdout:
            if "Invoke" in line or "Execute" in line:
                continue
            print(f"       > {line.strip()}")
        proc.wait()
        if proc.returncode == 0:
            print("    [OK] Base de datos Chatwoot preparada correctamente.")
        else:
            print("    [ERROR] Fallo en migración.")

def fix_evolution():
    print("🧬 [ EVO_FIX ] Ejecutando Chequeo de Integridad...")
    if not check_service("Evolution API", url="http://localhost:8080/"):
        return
    
    # 1. Detect target instance (with retries for startup)
    instances = None
    for i in range(8):
        ok, res = call_api("/instance/fetchInstances", method='GET')
        if ok:
            instances = res
            break
        print(f"    [WAIT] Evolution API no responde ({res}). Reintentando en 8s...")
        time.sleep(8)
        
    if instances is None:
        print("FAILED: Evolution API unavailable after retries.")
        return

    # Auto-provision instance if none exist
    if not instances or len(instances) == 0:
        print("    [AUTO] No hay instancias activas. Creando 'Master-Bridge' automáticamente...")
        payload = {
            "instanceName": "Master-Bridge",
            "token": ENV.get('EVOLUTION_API_KEY'),
            "qrcode": True
        }
        ok_create, res_create = call_api("/instance/create", payload)
        if ok_create:
            print("    [OK] Instancia 'Master-Bridge' creada con éxito.")
            target = "Master-Bridge"
        else:
            print(f"    [ERROR] No se pudo crear la instancia: {res_create}")
            return
    else:
        # In Evolution v2, instanceName might be nested inside an 'instance' object or be just 'name'
        first_instance = instances[0]
        target = first_instance.get('name') or first_instance.get('instanceName') or first_instance.get('instance', {}).get('instanceName')
        print(f"    [INFO] Active instance detected: {target}")

    # Evolution v2.x Integration Mapping
    chatwoot = {
        "enabled": True, 
        "accountId": str(ENV.get('CHATWOOT_ACCOUNT_ID', '1')),
        "token": ENV.get('CHATWOOT_GLOBAL_TOKEN', '').strip(), 
        "url": ENV.get('CHATWOOT_URL', "http://chatwoot:3000"),
        "signMsg": True,
        "reopenConversation": True,
        "conversationPending": False,
        "nameInbox": target,
        "mergeBrazilContacts": True,
        "importContacts": True,
        "importMessages": True,
        "daysLimitImportMessages": 60,
        "signDelimiter": "\n",
        "autoCreate": True,
        "organization": "Sentinel Bot",
        "logo": ""
    }
    
    # Sync Chatwoot integration
    cw_ok, cw_res = call_api(f"/chatwoot/set/{target}", chatwoot)
    if not cw_ok:
        print(f"    [ERROR] Sync failed for {target}: {cw_res}")
        return
    
    print(f"    [OK] Bridge Evolution-Chatwoot ({target}): SINCRONIZADO")

# --- [03] HELPERS ---
def check_service(name, url=None, cmd=None, retries=60):
    print(f"⏳ [WAIT] Verificando {name}...")
    for i in range(retries):
        try:
            if url:
                req = urllib.request.Request(url, method='GET')
                with urllib.request.urlopen(req, timeout=5) as response:
                    if response.status in [200, 401]:
                        print(f"    [OK] {name} está listo.")
                        return True
            elif cmd:
                res = subprocess.run(cmd, capture_output=True, check=False)
                if res.returncode == 0:
                    print(f"    [OK] {name} está listo.")
                    return True
        except Exception:
            pass
        
        if i % 5 == 0: print(f"       ... esperando {name} ...")
        time.sleep(2)
    print(f"    [ERROR] {name} no respondió a tiempo.")
    return False

def fix_database():
    print("🗄️ [ DB_FIX ] Verificando Consistencia de Usuarios...")
    
    # 1. Confirm DB is listening (Strict Check via Helper)
    if not check_service("Postgres Core", cmd=["docker", "exec", "db_core", "pg_isready", "-U", "root_admin", "-d", "postgres"]):
        return

    users = {
        "chatwoot_user": ENV.get('CHATWOOT_DB_PASSWORD', 'HackUN1991.1'),
        "evolution_user": ENV.get('EVOLUTION_DB_PASSWORD', 'HackUN1991.1'),
        "n8n_user": ENV.get('N8N_DB_PASSWORD', 'HackUN1991.1')
    }
    for user, pwd in users.items():
        print(f"    [FIX] Garantizando permisos para {user}...")
        
        # 2. Proactive Fix: Create user if it doesn't exist (Idempotent)
        sql_create = f"DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '{user}') THEN CREATE ROLE {user} WITH LOGIN SUPERUSER PASSWORD '{pwd}'; ELSE ALTER ROLE {user} WITH PASSWORD '{pwd}'; END IF; END $$;"
        cmd_create = ["docker", "exec", "db_core", "psql", "-U", "root_admin", "-d", "postgres", "-c", sql_create]
        
        # Retry loop for creation (handles "shutting down" or locked DB)
        for k in range(5):
            res_create = subprocess.run(cmd_create, capture_output=True, text=True, check=False)
            if res_create.returncode == 0:
                 break
            elif "shutting down" in res_create.stderr:
                 print(f"       [RETRY] DB reiniciándose... reintentando en 5s...")
                 time.sleep(5)
            else:
                 # If it fails, maybe it already exists or other error, we proceed to ALTER to be sure
                 break

        # 3. Ensure SUPERUSER (Legacy check / Validation)
        cmd_alter = ["docker", "exec", "db_core", "psql", "-U", "root_admin", "-d", "postgres", "-c", f"ALTER USER {user} WITH SUPERUSER;"]
        result = subprocess.run(cmd_alter, capture_output=True, text=True, check=False)

        if result.returncode == 0:
            print(f"    [OK] {user} operativo ({result.stdout.strip() if result.stdout else 'Checked'}).")
        else:
            print(f"    [ERROR] No se pudo configurar {user}: {result.stderr.strip()}")

def wait_for_ready():
    print("⏳ [ WAIT ] Esperando a que TODOS los servicios estén listos (Healthcheck)...")
    
    # Defines services and their health endpoints/commands
    services = [
        {"name": "Database (Postgres)", "url": None, "cmd": ["docker", "exec", "db_core", "pg_isready", "-U", "root_admin"]},
        {"name": "Evolution API", "url": "http://localhost:8080/", "cmd": None},
        {"name": "Chatwoot Web", "url": "http://localhost:3000/health_check", "cmd": None}, # Use proper health endpoint
        {"name": "MinIO Storage", "url": "http://localhost:9000/minio/health/live", "cmd": None}
    ]

    for service in services:
        name = service["name"]
        print(f"    [CHECK] Verificando {name}...")
        
        ready = False
        for i in range(120): # Wait up to 600 seconds (10 minutes) for slow boots
            try:
                if service["url"]:
                    # HTTP Check
                    req = urllib.request.Request(service["url"], method='GET')
                    with urllib.request.urlopen(req, timeout=5) as response:
                        if response.status in [200, 401]: # 401 is fine, means auth layer is up
                            ready = True
                elif service["cmd"]:
                    # Command Check (Docker)
                    res = subprocess.run(service["cmd"], capture_output=True, check=False)
                    if res.returncode == 0:
                        ready = True
                
                if ready:
                    print(f"    [OK] {name} está operativo.")
                    break
            except Exception:
                pass
            
            if i % 2 == 0: print(f"       ... esperando {name} ({i}/30) ...")
            time.sleep(5)
        
        if not ready:
            print(f"    [ERROR] {name} NO respondió después de 150 segundos. Abortando configuración.")
            sys.exit(1) # Stop script to prevent cascading errors
    
    print("    [OK] Sistema completamente estable. Procediendo con la configuración.")

def main():
    parser = argparse.ArgumentParser(description="Sentinel Engine - Orchestrator V11.1")
    parser.add_argument('--fix-evo', action='store_true', help="Fix Evolution API sync")
    parser.add_argument('--fix-db', action='store_true', help="Fix Database permissions")
    parser.add_argument('--setup-s3', action='store_true', help="Setup MinIO buckets")
    parser.add_argument('--prep-cw', action='store_true', help="Run Chatwoot Migrations if needed")
    parser.add_argument('--setup-cw', action='store_true', help="Setup Chatwoot admin")
    parser.add_argument('--wait', action='store_true', help="Wait for services to be ready")
    parser.add_argument('--get', type=str, help="Get ENV variable")
    args = parser.parse_args()

    if args.get:
        print(ENV.get(args.get, ""))
    elif args.prep_cw:
        prepare_chatwoot_db()
    elif args.wait:
        wait_for_ready()
    elif args.fix_evo:
        fix_evolution()
    elif args.fix_db:
        fix_database()
    elif args.setup_s3:
        setup_s3()
    elif args.setup_cw:
        setup_chatwoot()
    else:
        print("Sentinel Engine V11.1 - No action specified.")

if __name__ == "__main__":
    main()
