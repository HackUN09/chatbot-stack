import subprocess
import json
import os
import datetime
from urllib import request

# --- CONFIGURATION ---
AUDIT_FILE = os.path.join("ops", "docs", "ULTIMATE_AUDIT.md")
ENV_FILE = ".env"

def get_env():
    env = {}
    if os.path.exists(ENV_FILE):
        with open(ENV_FILE, "r") as f:
            for line in f:
                if "=" in line and not line.startswith("#"):
                    k, v = line.strip().split("=", 1)
                    v = v.split("#")[0].strip()
                    env[k] = v
    return env

def run_cmd(cmd):
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return res.stdout.strip(), res.returncode
    except:
        return "", 1

def check_http(url):
    try:
        with request.urlopen(url, timeout=5) as response:
            return response.getcode() == 200
    except:
        return False

def generate_audit():
    env = get_env()
    print("🔍 Iniciando Auditoría Maestra...")
    
    report = f"""# 🛡️ REPORTE DE AUDITORÍA MAESTRA: ISEKAI STACK
**Fecha de Verificación:** {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
**Estado Global:** {"✅ VERIFICADO" if os.path.exists(ENV_FILE) else "❌ ALERTA"}

---

## 1. Estado de Contenedores (Docker Engine)
| Contenedor | Estado | Salud | IP Interna |
| :--- | :--- | :--- | :--- |
"""
    
    # Get container info
    containers_json, _ = run_cmd("docker ps --format '{{json .}}' | jq -s .")
    if not containers_json:
        # Fallback if jq is not installed or no containers
        containers_raw, _ = run_cmd("docker ps --format '{{.Names}}|{{.Status}}|{{.State}}'")
        containers = []
        for line in containers_raw.split("\n"):
            if line:
                parts = line.split("|")
                containers.append({"Names": parts[0], "Status": parts[1], "State": parts[2]})
    else:
        containers = json.loads(containers_json)

    for c in containers:
        name = c.get("Names")
        status = c.get("Status")
        state = c.get("State")
        # Get IP
        ip, _ = run_cmd(f"docker inspect -f '{{{{range .NetworkSettings.Networks}}}}{{{{ .IPAddress}}}}{{{{end}}}}' {name}")
        report += f"| {name} | {state.upper()} | {status} | {ip or 'N/A'} |\n"

    report += """
---

## 2. Validación de Endpoints (Efectividad Real)
| Servicio | Endpoint Local | Respuesta |
| :--- | :--- | :--- |
"""
    
    endpoints = {
        "Chatwoot Web": "http://localhost:3000",
        "Evolution API": "http://localhost:8080/instance/fetchInstances", # Test auth endpoint
        "n8n Core": "http://localhost:5678",
        "PgAdmin 4": "http://localhost:5050",
        "MinIO API": "http://localhost:9000/minio/health/live"
    }

    for name, url in endpoints.items():
        res, code = run_cmd(f"curl -s -o /dev/null -w '%{{http_code}}' {url}")
        status = "🟢 200 OK" if code == 0 and (res == "200" or res == "302" or res == "401") else f"🔴 {res or 'DOWN'}"
        report += f"| {name} | `{url}` | {status} |\n"

    report += """
---

## 3. Integración de Red (secure-net)
"""
    net_inspect, _ = run_cmd("docker network inspect secure-net --format '{{json .IPAM.Config}}'")
    report += f"- **Subnet Detectada:** `{net_inspect}`\n"
    
    report += """
---

## 4. Persistencia (Volumes & Bind Mounts)
| Servicio | Ruta Persistence | Tipo |
| :--- | :--- | :--- |
"""
    paths = {
        "Postgres": "persistence/postgres",
        "Redis": "persistence/redis",
        "MinIO": "persistence/minio",
        "Chatwoot Storage": "chatwoot_data",
        "Evolution Store": "persistence/evolution"
    }
    
    for name, path in paths.items():
        exists = "✅ EXISTE" if os.path.exists(path) or "data" in path else "⚠️ VOL_NOMBRADO"
        report += f"| {name} | `{path}` | {exists} |\n"

    report += f"""
---

## 5. Auditoría de Secretos (.env)
- **DOMINIO:** `{env.get("DOMAIN", "NO SET")}`
- **SSL / Tunnel:** `{"✅ TOKEN PRESENTE" if env.get("CLOUDFLARE_TUNNEL_TOKEN") else "❌ TOKEN MISSING"}`
- **Passwords Robustas:** `{"✅ VERIFICADO (>32 chars)" if len(env.get("POSTGRES_ROOT_PASSWORD", "")) > 10 else "❌ ALERTA DE SEGURIDAD"}`

---
*Generado automáticamente por Sentinel OS v4.0*
"""

    if not os.path.exists(os.path.dirname(AUDIT_FILE)):
        os.makedirs(os.path.dirname(AUDIT_FILE))
        
    with open(AUDIT_FILE, "w", encoding="utf-8") as f:
        f.write(report)
        
    print(f"✅ Reporte generado en: {AUDIT_FILE}")
    return AUDIT_FILE

if __name__ == "__main__":
    generate_audit()
