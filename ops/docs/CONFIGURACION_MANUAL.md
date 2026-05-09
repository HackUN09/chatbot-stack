# ⚙️ SENTINEL OS v11.1 — Mapa de Variables de Entorno

<div align="center">

*Referencia completa de las 48 variables en 12 secciones*

</div>

---

## Resumen de Variables por Servicio

| Sección | Variables | Servicios |
|:--------|:---------:|:----------|
| `[01]` Dominio & Tunnel | 2 | Todos |
| `[02]` Chatwoot & Integración | 7 | chatwoot-web, chatwoot-worker, app_evolution |
| `[03]` Infra Core | 2 | db_core, cache_core |
| `[04]` DB Passwords | 3 | db_core, app_evolution, chatwoot-web, app_n8n |
| `[05]` API Keys & Cifrado | 3 | app_evolution, app_n8n |
| `[06]` Evolution API Config | 4 | app_evolution |
| `[07]` Audio Transcoding | 5 | app_evolution, evolution_audio_converter |
| `[08]` MinIO S3 | 11 | core_minio, app_evolution, chatwoot-web |
| `[09]` Paneles Admin | 2 | pgadmin |
| `[10]` n8n Engine | 2 | app_n8n_editor |
| `[11]` AEGIS Protocol | 3 | app_n8n_editor |
| `[12]` Import DB URI | 1 | app_evolution (import histórico) |

**Total: 45 variables**

---

## [01] 🌐 Dominio & Tunnel

| Variable | Ejemplo | Descripción | Servicios |
|:---------|:--------|:------------|:----------|
| `DOMAIN` | `miempresa.com` | Dominio raíz. Todos los subdominios se construyen con este valor. | TODOS |
| `CLOUDFLARE_TUNNEL_TOKEN` | `eyJhIjoiMD...` | Token del tunnel Zero Trust de Cloudflare. Expone los 4 subdominios. | cloudflared |

---

## [02] 💬 Chatwoot & Integración

| Variable | Ejemplo | Descripción | Servicios |
|:---------|:--------|:------------|:----------|
| `CHATWOOT_ADMIN_EMAIL` | `admin@empresa.com` | Email del primer administrador (se crea automáticamente). | chatwoot-web |
| `CHATWOOT_ADMIN_PASSWORD` | `P@ssw0rd!` | Password del administrador. | chatwoot-web |
| `CHATWOOT_GLOBAL_TOKEN` | `ZKd2GF6r...` | **Auto-generado** por `--setup-cw`. Token API del admin. NO editar. | app_evolution |
| `CHATWOOT_ACCOUNT_ID` | `1` | ID de cuenta (siempre 1 en primera instalación). | app_evolution |
| `CHATWOOT_URL` | `http://chatwoot-web:3000` | URL **INTERNA** Docker. ⚠️ NO cambiar. | app_evolution |
| `FRONTEND_URL` | `https://chat.dominio.com` | URL pública del CRM (para emails de notificación). | chatwoot-web |
| `SECRET_KEY_BASE` | (64 bytes hex) | Clave criptográfica de Rails. Genera con `openssl rand -hex 64`. ⚠️ Si cambias, pierdes sesiones activas. | chatwoot-web, worker |

---

## [03] 🛠️ Infraestructura Core

| Variable | Ejemplo | Descripción | Servicios |
|:---------|:--------|:------------|:----------|
| `POSTGRES_ROOT_PASSWORD` | `P@ssDB!` | Password del superusuario `root_admin` de PostgreSQL. | db_core |
| `REDIS_PASSWORD` | `P@ssRedis!` | Password de Redis. Compartida entre Chatwoot (idx:1) y Evolution (idx:2). | cache_core, chatwoot-web, app_evolution |

---

## [04] 🧬 Passwords de Bases de Datos

> ⚠️ Cada valor DEBE coincidir con el de la sección [06] y [12] donde se usen en URIs de conexión.

| Variable | DB Creada | Usuario | Descripción |
|:---------|:----------|:--------|:------------|
| `CHATWOOT_DB_PASSWORD` | `chatwoot` | `chatwoot_user` | Password exclusiva de la DB de Chatwoot. |
| `EVOLUTION_DB_PASSWORD` | `evolution` | `evolution_user` | Password exclusiva de la DB de Evolution API. |
| `N8N_DB_PASSWORD` | `n8n` | `n8n_user` | Password exclusiva de la DB de n8n. |

---

## [05] 🔑 API Keys & Cifrado

| Variable | Ejemplo | Descripción | Servicios |
|:---------|:--------|:------------|:----------|
| `EVOLUTION_API_KEY` | `MiApiKey!` | API Key maestra para autenticar en Evolution API. Header: `apikey`. | app_evolution |
| `N8N_ENCRYPTION_KEY` | (32+ chars) | Clave de cifrado de n8n. Protege credenciales en workflows. | app_n8n_editor |
| `N8N_USER_MANAGEMENT_JWT_SECRET` | (24+ chars) | JWT Secret de n8n para autenticación de usuarios. | app_n8n_editor |

---

## [06] 📱 Evolution API Config

| Variable | Ejemplo | Descripción |
|:---------|:--------|:------------|
| `SERVER_URL` | `https://api.dominio.com` | URL pública de Evolution (visible en el admin web). |
| `DATABASE_CONNECTION_URI` | `postgresql://evolution_user:${EVOLUTION_DB_PASSWORD}@db_core:5432/evolution?schema=public` | URI completa de Postgres para Evolution. ⚠️ La password DEBE coincidir con `EVOLUTION_DB_PASSWORD`. |
| `CACHE_REDIS_URI` | `redis://:${REDIS_PASSWORD}@cache_core:6379/2` | Redis para caché de sesiones. Usa DB index 2. ⚠️ Formato: `redis://:password@host` (sin usuario). |
| `CONFIG_SESSION_PHONE_VERSION` | `2.3000.1033351060` | Versión de WhatsApp Web emulada por Baileys. No cambiar sin verificar. |

---

## [07] 🎤 Audio Transcoding

| Variable | Valor | Descripción |
|:---------|:------|:------------|
| `AUDIO_CONVERTER_ENABLED` | `true` | Activa el microservicio de transcodificación. |
| `API_AUDIO_CONVERTER` | `http://evolution_audio_converter:4040/process-audio` | URL interna Docker del convertidor. ⚠️ NO usar URL pública. |
| `WA_BUSINESS_AUDIO_CHANNEL` | `true` | Canal de audio compatible con WhatsApp Business. |
| `EVOLUTION_AUDIO_CONVERTER_FORCE` | `true` | Fuerza transcoding aunque el formato parezca correcto (recomendado). |
| `AUDIO_CONVERTER_KEY` | `MiClaveAudio!` | Clave de autenticación entre Evolution y el convertidor. |

---

## [08] 🪣 MinIO S3 Storage

### Variables de MinIO (servidor)

| Variable | Ejemplo | Descripción |
|:---------|:--------|:------------|
| `MINIO_ROOT_USER` | `minioadmin` | Usuario root de MinIO. |
| `MINIO_ROOT_PASSWORD` | `P@ssMinio!` | Password root de MinIO. |

### Variables de S3 para Evolution API

| Variable | Valor | Descripción |
|:---------|:------|:------------|
| `S3_ENABLED` | `true` | Activa almacenamiento S3 en Evolution. |
| `S3_ACCESS_KEY` | `minioadmin` | Debe coincidir con `MINIO_ROOT_USER`. |
| `S3_SECRET_KEY` | (password) | Debe coincidir con `MINIO_ROOT_PASSWORD`. |
| `S3_ENDPOINT` | `core_minio` | **⚠️ CRÍTICO**: nombre exacto del container Docker. |
| `S3_PORT` | `9000` | Puerto interno de MinIO. No cambiar. |
| `S3_REGION` | `us-east-1` | MinIO ignora la región, pero el SDK la requiere. |
| `S3_USE_SSL` | `false` | Comunicación sin SSL en red interna. |
| `S3_FORCE_PATH_STYLE` | `true` | Requerido por MinIO (no compatible con virtual-hosted). |
| `S3_PUBLIC_URL` | `https://s3.dominio.com` | **v11.1**: URL CDN pública que Evolution usa al enviar referencias de archivos a Chatwoot. Evita el error SSRF 422. |
| `EVOLUTION_BUCKET` | `evolution-media` | Bucket para multimedia de WhatsApp. |
| `CHATWOOT_BUCKET` | `chatwoot-storage` | Bucket para adjuntos del CRM. |

### Variables de S3 para Chatwoot

| Variable | Valor | Descripción |
|:---------|:------|:------------|
| `STORAGE_ENDPOINT` | `http://core_minio:9000` | **Upload**: URL interna para que Chatwoot suba archivos a MinIO. |
| `STORAGE_CDN_HOST` | `https://s3.dominio.com` | **Entrega**: URL pública que Chatwoot inserta en los mensajes. |

---

## [09] 👤 Paneles de Administración

| Variable | Descripción |
|:---------|:------------|
| `PGADMIN_DEFAULT_EMAIL` | Email de acceso a PgAdmin (localhost:5050). |
| `PGADMIN_DEFAULT_PASSWORD` | Password de PgAdmin. |

---

## [10] ⚙️ n8n Engine

| Variable | Ejemplo | Descripción |
|:---------|:--------|:------------|
| `N8N_HOST` | `n8n.dominio.com` | Hostname público de n8n. |
| `WEBHOOK_URL` | `https://n8n.dominio.com/` | URL base para webhooks entrantes. |

---

## [11] 🛡️ AEGIS Protocol — Auto-poda de n8n

| Variable | Valor | Descripción |
|:---------|:------|:------------|
| `N8N_EXECUTIONS_DATA_MAX_AGE` | `168` | Máximo de horas que se guardan ejecuciones (168h = 7 días). |
| `N8N_EXECUTIONS_DATA_PRUNE` | `true` | Activa la poda automática de ejecuciones antiguas. |
| `N8N_EXECUTIONS_DATA_PRUNE_TIMEOUT` | `3600` | Timeout del proceso de poda en segundos. |

---

## [12] 🔗 Import de Historial Chatwoot ↔ Evolution

| Variable | Descripción |
|:---------|:------------|
| `CHATWOOT_IMPORT_DATABASE_CONNECTION_URI` | URI directa a la DB de Chatwoot para importación de mensajes históricos. La password DEBE coincidir con `CHATWOOT_DB_PASSWORD`. |

---

## Distribución de Bases de Datos PostgreSQL

| DB | Usuario | Creada por | Extensiones |
|:---|:--------|:----------|:------------|
| `chatwoot` | `chatwoot_user` | `01-segregation.sh` | pgcrypto, uuid-ossp |
| `evolution` | `evolution_user` | `01-segregation.sh` | pgcrypto, uuid-ossp |
| `n8n` | `n8n_user` | `01-segregation.sh` | pgcrypto, uuid-ossp |

## Distribución de Redis Indexes

| Index | Servicio | Función |
|:-----:|:---------|:--------|
| 0 | Reservado | — |
| 1 | Chatwoot | Cola Sidekiq + ActionCable WebSockets |
| 2 | Evolution API | Caché de sesiones WhatsApp (TTL: 7 días) |

---

*Sentinel OS v11.1 — HackUN09 & Antigravity AI*
