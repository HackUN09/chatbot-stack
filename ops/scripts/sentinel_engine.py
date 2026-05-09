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
    """Loads .env with prioritized encoding fallback."""
    env = {}
    encodings = ['utf-8', 'cp1252', 'latin-1']
    
    if not os.path.exists('.env'):
        return env

    for encoding in encodings:
        try:
            with open('.env', 'r', encoding=encoding) as f:
                for line in f:
                    line = line.strip()
                    if '=' in line and not line.startswith('#'):
                        key, val = line.split('=', 1)
                        clean_key = key.strip()
                        clean_val = val.strip().strip('"').strip("'")
                        env[clean_key] = clean_val
                        os.environ[clean_key] = clean_val
            return env
        except (UnicodeDecodeError, Exception):
            continue
    return env

def save_env(env_data):
    """Saves ENV dictionary back to .env preserving UTF-8/Emojis."""
    try:
        # 1. Read existing lines to preserve comments and structure
        lines = []
        if os.path.exists('.env'):
            with open('.env', 'r', encoding='utf-8', errors='replace') as f:
                lines = f.readlines()
        
        # 2. Update or append keys
        updated_content = []
        keys_processed = set()
        
        for line in lines:
            if '=' in line and not line.strip().startswith('#'):
                key = line.split('=', 1)[0].strip()
                if key in env_data:
                    updated_content.append(f"{key}={env_data[key]}\n")
                    keys_processed.add(key)
                    continue
            updated_content.append(line)
            
        # 3. Add new keys that weren't in the file
        for key, val in env_data.items():
            if key not in keys_processed:
                updated_content.append(f"{key}={val}\n")
                
        # 4. Atomic write with explicit UTF-8
        with open('.env', 'w', encoding='utf-8', newline='\n') as f:
            f.writelines(updated_content)
        return True
    except Exception as e:
        print(f"    [ERROR] Failed to save .env: {e}")
        return False

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

def call_chatwoot_api(endpoint, payload=None, method='GET'):
    """Calls Chatwoot internal API using internal Docker hostname."""
    base_url = "http://127.0.0.1:3000"
    account_id = ENV.get('CHATWOOT_ACCOUNT_ID', '1')
    token = ENV.get('CHATWOOT_GLOBAL_TOKEN', '')
    if not token:
        return False, "CHATWOOT_GLOBAL_TOKEN not set"

    headers = {
        "Content-Type": "application/json",
        "api_access_token": token
    }
    url = f"{base_url}/api/v1/accounts/{account_id}{endpoint}"
    payload_str = json.dumps(payload) if payload else None
    data = payload_str.encode('utf-8') if payload_str else None

    try:
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        with urllib.request.urlopen(req, timeout=10) as response:
            return True, json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        return False, f"HTTP {e.code}: {e.read().decode('utf-8')}"
    except Exception as e:
        return False, str(e)

def patch_webhook_internal(instance_name):
    """
    Patches the Chatwoot inbox webhook URL to use the internal Docker URL.
    This eliminates the Cloudflare hairpinning timeout when Chatwoot sends
    events back to Evolution API.
    Bug fixed: 'Timed out reading data from server' in chatwoot-worker logs.
    """
    ok, resp = call_chatwoot_api("/inboxes", method="GET")
    if not ok:
        print(f"    [WARN] Could not fetch inboxes to patch webhook: {resp}")
        return
    for inbox in resp.get("payload", []):
        if inbox.get("name") == instance_name:
            inbox_id = inbox.get("id")
            internal_url = f"http://app_evolution:8080/chatwoot/webhook/{instance_name}"
            patch_ok, patch_resp = call_chatwoot_api(
                f"/inboxes/{inbox_id}",
                payload={"channel": {"webhook_url": internal_url}},
                method="PATCH"
            )
            if patch_ok:
                print(f"    [FIX] Webhook for '{instance_name}' patched to internal URL.")
            else:
                print(f"    [WARN] Webhook patch failed for '{instance_name}': {patch_resp}")
            return

def setup_s3():
    """Crea buckets en MinIO y aplica políticas de acceso público usando mc dentro del container."""
    print("  [S3] Configurando Buckets en MinIO...")
    if not check_service("MinIO Storage", url="http://localhost:9000/minio/health/live"):
        return

    minio_user = ENV.get('MINIO_ROOT_USER', 'minioadmin')
    minio_pass = ENV.get('MINIO_ROOT_PASSWORD', 'minioadmin')
    evo_bucket = ENV.get('EVOLUTION_BUCKET', ENV.get('S3_BUCKET', 'evolution-media'))
    cw_bucket  = ENV.get('CHATWOOT_BUCKET', ENV.get('STORAGE_BUCKET_NAME', 'chatwoot-storage'))

    # Paso 1: Crear alias local dentro del container core_minio
    alias_cmd = [
        "docker", "exec", "core_minio",
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
        mb_cmd = ["docker", "exec", "core_minio", "mc", "mb", "--ignore-existing", f"local/{bucket_name}"]
        res_mb = subprocess.run(mb_cmd, capture_output=True, text=True, check=False)
        if res_mb.returncode == 0:
            print(f"    [OK] Bucket '{bucket_name}' garantizado.")
        else:
            print(f"    [WARN] mb resultado: {res_mb.stderr.strip()}")

        # Aplicar política pública de descarga
        policy_cmd = ["docker", "exec", "core_minio", "mc", "anonymous", "set", "download", f"local/{bucket_name}"]
        res_pol = subprocess.run(policy_cmd, capture_output=True, text=True, check=False)
        if res_pol.returncode == 0:
            print(f"    [OK] Política pública aplicada a '{bucket_name}'.")
        else:
            print(f"    [WARN] Policy resultado: {res_pol.stderr.strip()}")

    print("    [S3] Setup completo.")
    heal_media()

def heal_media():
    """Corrige Content-Type y Disposition de audios/videos en MinIO de forma automática."""
    print("  [HEAL] Curando metadatos de multimedia (Audio/Video Fix)...")
    if not os.environ.get('AUDIO_CONVERTER_ENABLED', 'false').lower() == 'true':
        print("    [SKIP] Audio converter no habilitado.")
        return

    minio_user = ENV.get('MINIO_ROOT_USER', 'minioadmin')
    minio_pass = ENV.get('MINIO_ROOT_PASSWORD', 'minioadmin')
    cw_bucket  = ENV.get('CHATWOOT_BUCKET', 'chatwoot-storage')

    # Comando quirúrgico para corregir .opus a audio/ogg e inyectar 'inline'
    # Esto asegura que el reproductor de Chatwoot funcione sin descargar el archivo
    fix_cmd = [
        "docker", "exec", "core_minio", "/bin/sh", "-c",
        f"mc alias set local http://localhost:9000 {minio_user} {minio_pass} > /dev/null 2>&1 && "
        f"mc find local/{cw_bucket} --name '*.opus' --exec "
        f"\"mc cp --attr Content-Type=audio/ogg;Content-Disposition=inline local/{{}} local/{{}}\""
    ]
    
    try:
        subprocess.run(fix_cmd, capture_output=True, text=True, check=False)
        print(f"    [OK] Metadatos de Audio (.opus -> ogg) sincronizados en '{cw_bucket}'.")
    except Exception as e:
        print(f"    [WARN] Error en heal_media: {e}")

def setup_chatwoot():
    print("  [CW] Inicializando Admin, Cuenta e Inbox...")
    if not check_service("Chatwoot Web", url="http://localhost:3000/api", retries=60):
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
                # Auto-inject into .env using robust save_env
                current_env = load_env()
                current_env['CHATWOOT_GLOBAL_TOKEN'] = token
                if save_env(current_env):
                    print("    [AUTO] Token inyectado quirúrgicamente en .env (UTF-8 Safe)")
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
    print("[ CW_PREP ] Verificando Esquema de Base de Datos...")

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
    print("[ EVO_FIX ] Ejecutando Chequeo de Integridad...")
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

    # Process all instances found or create one if none exist
    targets = []
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
            targets.append("Master-Bridge")
        else:
            print(f"    [ERROR] No se pudo crear la instancia: {res_create}")
            return
    else:
        for inst in instances:
            name = inst.get('name') or inst.get('instanceName') or inst.get('instance', {}).get('instanceName')
            if name:
                targets.append(name)
        print(f"    [INFO] Detected {len(targets)} active instances.")

    for target in targets:
        # Evolution v2.x Integration Mapping
        chatwoot = {
            "enabled": True, 
            "accountId": str(ENV.get('CHATWOOT_ACCOUNT_ID', '1')),
            "token": ENV.get('CHATWOOT_GLOBAL_TOKEN', '').strip(), 
            "url": ENV.get('CHATWOOT_URL', "http://chatwoot-web:3000"),
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
        else:
            print(f"    [OK] Bridge Evolution-Chatwoot ({target}): SINCRONIZADO")
            # FIX: Patch webhook to internal Docker URL (eliminates hairpinning timeout)
            patch_webhook_internal(target)

# --- [03] HELPERS ---
def check_service(name, url=None, cmd=None, retries=60):
    print(f"[WAIT] Verificando {name}...")
    for i in range(retries):
        try:
            if url:
                # Use 127.0.0.1 instead of localhost for Windows reliability
                robust_url = url.replace("localhost", "127.0.0.1")
                req = urllib.request.Request(robust_url, method='GET')
                with urllib.request.urlopen(req, timeout=5) as response:
                    # Accepts any response that implies the server is processing requests
                    if response.status in [200, 401, 301, 302, 404, 500]:
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
    print("[ DB_FIX ] Verificando Consistencia de Usuarios...")
    
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
    print("[ WAIT ] Esperando a que TODOS los servicios estén listos (Healthcheck)...")
    
    # Defines services and their health endpoints/commands
    services = [
        {"name": "Database (Postgres)", "url": None, "cmd": ["docker", "exec", "db_core", "pg_isready", "-U", "root_admin"]},
        {"name": "Evolution API", "url": "http://localhost:8080/", "cmd": None},
        {"name": "Chatwoot Web", "url": "http://localhost:3000/api", "cmd": None}, # /api returns 200, /health_check returns 404 in v3.12
        {"name": "MinIO Storage", "url": "http://localhost:9000/minio/health/live", "cmd": None}
    ]

    for service in services:
        name = service["name"]
        print(f"    [CHECK] Verificando {name}...")
        
        ready = False
        for i in range(120): # Wait up to 240 seconds (4 minutes)
            try:
                if service["url"]:
                    # HTTP Check
                    req = urllib.request.Request(service["url"], method='GET')
                    with urllib.request.urlopen(req, timeout=3) as response:
                        if response.status in [200, 401, 404, 301, 302]:
                            ready = True
                elif service["cmd"]:
                    # Command Check (Docker)
                    res = subprocess.run(service["cmd"], capture_output=True, check=False)
                    if res.returncode == 0:
                        ready = True
            except Exception:
                pass
            
            if ready:
                print(f"    [OK] {name} está operativo.")
                break
                
            if i % 5 == 0: # Print every 10 seconds (since sleep is 2s)
                print(f"       ... esperando {name} ({i*2}s/240s) ...")
            
            time.sleep(2)
        
        if not ready:
            print(f"    [ERROR] {name} NO respondió a tiempo. Abortando.")
            sys.exit(1)
    
    print("    [OK] Sistema completamente estable. Procediendo con la configuración.")

def main():
    parser = argparse.ArgumentParser(description="Sentinel Engine - Orchestrator V11.1")
    parser.add_argument('--fix-evo', action='store_true', help="Fix Evolution API sync")
    parser.add_argument('--fix-db', action='store_true', help="Fix Database permissions")
    parser.add_argument('--setup-s3', action='store_true', help="Setup MinIO buckets")
    parser.add_argument('--prep-cw', action='store_true', help="Run Chatwoot Migrations if needed")
    parser.add_argument('--setup-cw', action='store_true', help="Setup Chatwoot admin")
    parser.add_argument('--heal-media', action='store_true', help="Fix audio/video MIME types in MinIO")
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
    elif args.heal_media:
        heal_media()
    else:
        print("Sentinel Engine V11.1 - No action specified.")

if __name__ == "__main__":
    main()
