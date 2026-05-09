# 🌌 SENTINEL OS v11.1 — Manual de Instalación Completo

<div align="center">

**Guía definitiva: del `git clone` al sistema funcionando en producción**

*Versión v11.1 — Multi-Instance Engine | SSRF Fix | Webhook Internal Routing*

</div>

---

## 📋 Prerrequisitos del Sistema

| Requisito | Mínimo | Verificar |
|:----------|:-------|:----------|
| Docker Engine | 24.0+ | `docker --version` |
| Docker Compose | v2.20+ | `docker compose version` |
| RAM | 12 GB libres | `free -h` |
| CPU | 4 cores | `nproc` |
| Disco | 20 GB libres | `df -h` |
| SO | Linux/WSL2/macOS | — |
| Dominio | Con Cloudflare DNS | — |

> [!IMPORTANT]
> En **Windows**, es obligatorio usar **WSL2** o un entorno Linux. Los scripts Bash no son compatibles con PowerShell directamente.

---

## ⚡ Despliegue Rápido (3 comandos)

```bash
# 1. Clonar
git clone https://github.com/HackUN09/chatbot-stack.git && cd chatbot-stack

# 2. Configurar (edita las 6 variables mínimas marcadas con ★)
cp .env.example .env && nano .env

# 3. Desplegar
chmod +x sistema_maestro.sh && ./sistema_maestro.sh
# → Selecciona Opción 1: GENESIS
```

---

## 🔧 Configuración Detallada del `.env`

### Variables Obligatorias (★ = DEBES cambiar)

```bash
# ★ Tu dominio raíz (sin https://)
DOMAIN=tuempresa.com

# ★ Token del Tunnel de Cloudflare Zero Trust
CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoiMD...

# ★ Email del administrador de Chatwoot
CHATWOOT_ADMIN_EMAIL=admin@tuempresa.com

# ★ Password del administrador (min 8 chars)
CHATWOOT_ADMIN_PASSWORD=TuPasswordSegura123!

# ★ Password de PostgreSQL (usa openssl rand -base64 32)
POSTGRES_ROOT_PASSWORD=TuPasswordDB!

# ★ Clave criptográfica de Rails (usa openssl rand -hex 64)
SECRET_KEY_BASE=generado_con_openssl_rand_hex_64
```

### Variables de Seguridad Adicionales

```bash
# Passwords individuales por base de datos (no compartir con root)
CHATWOOT_DB_PASSWORD=pwChatwoot!
EVOLUTION_DB_PASSWORD=pwEvolution!
N8N_DB_PASSWORD=pwN8n!

# MinIO S3
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=pwMinio!

# Redis
REDIS_PASSWORD=pwRedis!

# API Keys
EVOLUTION_API_KEY=tuApiKeyEvolution!
N8N_ENCRYPTION_KEY=tuClaveN8n32chars!
N8N_USER_MANAGEMENT_JWT_SECRET=tuSecretoJWT!
```

### Variables de S3 (CRÍTICAS — No cambiar nombres de servicio)

```bash
# CRÍTICO: El nombre DEBE ser 'core_minio' (nombre exacto del container Docker)
S3_ENDPOINT=core_minio
S3_PORT=9000
S3_USE_SSL=false
S3_FORCE_PATH_STYLE=true

# Buckets (se crean automáticamente)
EVOLUTION_BUCKET=evolution-media
CHATWOOT_BUCKET=chatwoot-storage

# CDN público (lo que ven los usuarios en el browser)
STORAGE_CDN_HOST=https://s3.tudominio.com
```

> [!WARNING]
> Si cambias `S3_ENDPOINT` a cualquier otro valor (ej: `minio-core`, `localhost`), Evolution API no podrá conectar con MinIO y obtendrás errores `ECONNREFUSED`.

---

## 🏗️ Estructura de Redes Docker

```
┌─────────────────────────────────────────────────────────────┐
│                    RED: secure-net                           │
│                                                             │
│  chatwoot-web:3000  ←→  app_evolution:8080                  │
│         ↑                      ↑                            │
│  chatwoot-worker              core_minio:9000                │
│         ↑                      ↑                            │
│      db_core:5432         cache_core:6379                   │
│                                                             │
│  evolution_audio_converter:4040                             │
│  cloudflared_tunnel (sin puerto interno)                    │
└─────────────────────────────────────────────────────────────┘
         ↕ Solo Cloudflare Tunnel expone al internet
┌─────────────────────────────────────────────────────────────┐
│                    INTERNET PÚBLICO                         │
│  chat.dominio.com → chatwoot-web:3000                       │
│  api.dominio.com  → app_evolution:8080                      │
│  n8n.dominio.com  → app_n8n_editor:5678                     │
│  s3.dominio.com   → core_minio:9000                         │
└─────────────────────────────────────────────────────────────┘
```

### Regla de Oro de Networking

| Escenario | URL a usar |
|:----------|:-----------|
| Servicio → Servicio (interno) | `http://nombre_container:puerto` |
| Browser del agente | `https://subdominio.tudominio.com` |
| Webhook Evolution → Chatwoot | `http://chatwoot-web:3000` |
| Upload Chatwoot → MinIO | `http://core_minio:9000` |
| CDN archivos multimedia | `https://s3.tudominio.com` |

---

## 🚀 Secuencia de GENESIS (Opción 1) — Detallada

```
Paso 0  → docker network create secure-net
           Red privada compartida. Idempotente.

Paso 1  → docker compose -p 01-infra up -d
           • PostgreSQL 16.6: crea 3 DBs + 3 usuarios
           • Redis 7.4: password + DB indexes 1 (Chatwoot) y 2 (Evolution)
           • MinIO: crea buckets evolution-media y chatwoot-storage con política download
           • PgAdmin: localhost:5050
           • Redis Insight: localhost:5540

Paso 2  → sentinel_engine.py --fix-db
           ALTER ROLE para los 3 usuarios DB (idempotente).

Paso 3  → docker compose -p 02-apps up -d
           • Chatwoot: ejecuta rails db:prepare (2-3 min primer arranque)
           • Evolution API v2.3.7
           • Audio Converter (Opus→OGG)
           • n8n v1.76.1

Paso 4  → docker compose -p 03-tunnel up -d
           Cloudflare Tunnel activa los 4 subdominios públicos.

Paso 5  → sentinel_engine.py --wait
           Healthcheck activo. Espera hasta 120s que todos respondan.

Paso 6  → sentinel_engine.py --setup-s3
           • Configura CORS en MinIO
           • Ejecuta heal_media() para corregir MIME types

Paso 7  → sentinel_engine.py --setup-cw
           • Crea usuario admin en Chatwoot
           • Extrae access_token y lo inyecta en .env

Paso 8  → sentinel_engine.py --fix-evo
           • Detecta TODAS las instancias de Evolution API
           • Sincroniza cada una con su propio Inbox en Chatwoot
           • Parchea el webhook URL a la URL interna Docker
             (http://app_evolution:8080 en lugar de https://api.dominio.com)
           • Elimina el timeout de Cloudflare hairpinning

RESULTADO → Dashboard con credenciales de acceso
```

---

## 🩺 Troubleshooting — Problemas Conocidos y Soluciones

### Error #1: `ECONNREFUSED` al subir archivos a MinIO

**Síntoma:** Evolution o Chatwoot no pueden subir multimedia.

**Diagnóstico:**
```bash
docker logs app_evolution | Select-String "ECONNREFUSED"
```

**Causa:** `S3_ENDPOINT` apunta a un nombre incorrecto.

**Solución:**
```bash
# Verifica que el container se llame core_minio
docker ps | Select-String "minio"

# En .env:
S3_ENDPOINT=core_minio   # CORRECTO
# S3_ENDPOINT=minio-core  # INCORRECTO
```

---

### Error #2: `422 Invalid Request (invalid hostname)`

**Síntoma:** Evolution API recibe 422 de Chatwoot al enviar media.

**Diagnóstico:**
```bash
docker logs app_evolution 2>&1 | Select-String "422"
```

**Causa:** Chatwoot bloquea URLs con hostnames internos de Docker (protección SSRF).

**Solución aplicada en v11.1:**
- `ALLOWED_HOSTS: "*"` en Chatwoot
- `SSRF_SAFE_LIST: "core_minio,chatwoot-web,evolution_audio_converter,app_evolution"`
- `S3_PUBLIC_URL: https://s3.tudominio.com` en Evolution (usa CDN público para referencias)

**Si persiste:**
```bash
# Reiniciar Chatwoot con la nueva config
docker compose -f modules/02-apps/docker-compose.yml --env-file .env up -d chatwoot-web chatwoot-worker
# Luego re-sincronizar
python ops/scripts/sentinel_engine.py --fix-evo
```

---

### Error #3: Webhook timeout en Chatwoot Worker

**Síntoma:** En `docker logs chatwoot-worker`:
```
Exception: Invalid webhook URL https://api.tudominio.com/chatwoot/webhook/instancia : Timed out
```

**Causa:** Hairpinning — Chatwoot intenta llegar a Evolution por el dominio público (pasando por Cloudflare), lo que causa timeouts o loops.

**Solución aplicada en v11.1:** `sentinel_engine.py --fix-evo` ahora parchea automáticamente el webhook URL en cada Inbox a `http://app_evolution:8080/chatwoot/webhook/{instancia}` (comunicación directa por red interna Docker).

---

### Error #4: Audio Converter `(unhealthy)` en docker ps

**Síntoma:** `evolution_audio_converter` aparece como `(unhealthy)`.

**Causa:** El healthcheck probaba `GET /` que devuelve 404. El servicio funciona correctamente.

**Solución aplicada en v11.1:** Healthcheck cambiado a `nc -z localhost 4040` (verifica que el puerto TCP está escuchando).

---

### Error #5: QR code no aparece en Evolution API

**Síntoma:** `/instance/connect` devuelve timeout o QR no visible.

**Causa:** Baileys usa una versión de WhatsApp Web obsoleta.

**Solución:**
```bash
# En .env:
CONFIG_SESSION_PHONE_VERSION=2.3000.1033351060
```

---

### Error #6: Chatwoot 502 Bad Gateway los primeros minutos

**Síntoma:** Cloudflare muestra 502 al abrir `chat.tudominio.com`.

**Causa:** Chatwoot ejecuta `rails db:prepare` (~200 migraciones) en el primer arranque. Tarda 2-3 minutos.

**Solución:** Esperar. `sentinel_engine.py --wait` espera activamente hasta que Chatwoot responda.

---

### Error #7: `UnicodeEncodeError` en Windows

**Síntoma:** `sentinel_engine.py` falla con `'charmap' codec can't encode character`.

**Causa:** Windows usa cp1252 por defecto; el script tiene emojis UTF-8.

**Solución:** El script v11.1 ya tiene `encoding='utf-8'` en todos los `open()` y se eliminaron emojis de los `print()`.

---

## 🔄 Operaciones de Mantenimiento

```bash
# Sincronizar todas las instancias Evolution con Chatwoot
python ops/scripts/sentinel_engine.py --fix-evo

# Reparar base de datos (usuarios y permisos)
python ops/scripts/sentinel_engine.py --fix-db

# Corregir MIME types de audios en MinIO
python ops/scripts/sentinel_engine.py --heal-media

# Ver estado de todos los containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Ver logs de un servicio en vivo
docker logs -f app_evolution
docker logs -f chatwoot-web
docker logs -f chatwoot-worker

# Backup completo de persistencia
tar -czf backup-$(date +%Y%m%d).tar.gz persistence/

# Limpieza Docker (nuclear)
./ops/scripts/clean-docker.sh
```

---

## 📊 Acceso a Servicios

| Servicio | URL | Credenciales |
|:---------|:----|:-------------|
| Chatwoot CRM | `https://chat.tudominio.com` | `CHATWOOT_ADMIN_EMAIL` / `CHATWOOT_ADMIN_PASSWORD` |
| Evolution API | `https://api.tudominio.com` | Header: `apikey: EVOLUTION_API_KEY` |
| n8n Automation | `https://n8n.tudominio.com` | Se crea en el primer acceso |
| MinIO Console | `http://localhost:9001` | `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` |
| PgAdmin | `http://localhost:5050` | `PGADMIN_DEFAULT_EMAIL` / `PASSWORD` |
| Redis Insight | `http://localhost:5540` | Sin password |

---

## 🔒 Modelo de Seguridad

- **0 puertos expuestos** al internet — todo vía Cloudflare Tunnel (TLS E2E)
- **Red Docker aislada** (`secure-net`) — servicios solo se ven entre sí
- **Credenciales segregadas** — cada servicio tiene su propio usuario DB
- **`.gitignore` blindado** — `.env`, `.env.bank`, `persistence/` nunca van a Git
- **Binding local** — MinIO, PgAdmin, Redis Insight solo en `127.0.0.1`

---

*Sentinel OS v11.1 — HackUN09 & Antigravity AI*
