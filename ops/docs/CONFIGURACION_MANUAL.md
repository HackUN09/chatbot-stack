# 🔧 Configuración Manual de Servicios | Sentinel OS v11.0

> *Referencia exhaustiva de las 47 variables de entorno y sus interacciones entre servicios*

---

## 📐 Modelo de Configuración

El sistema utiliza un **modelo de configuración centralizado**: un único archivo `.env` en la raíz que alimenta a todos los servicios vía `env_file` y `${VARIABLE}` en los `docker-compose.yml`.

```
                    ┌─────────────┐
                    │   .env      │ ← Fuente Única de Verdad
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ 01-infra │    │ 02-apps  │    │ 03-tunnel│
    │ compose  │    │ compose  │    │ compose  │
    └──────────┘    └──────────┘    └──────────┘
```

> [!IMPORTANT]
> Nunca edites variables directamente en los `docker-compose.yml`. Siempre edita el `.env` y reinicia el servicio afectado.

---

## 🗺️ Mapa Completo de Variables por Servicio

### [01] 🌐 Dominio y Túnel Cloudflare

| Variable | Valor de Ejemplo | Consumido por |
|:---------|:-----------------|:-------------|
| `DOMAIN` | `miempresa.com` | Chatwoot, Evolution, n8n (construyen sus URLs) |
| `CLOUDFLARE_TUNNEL_TOKEN` | `eyJhIjoiMD...` | cloudflared_tunnel |

**Cómo funciona**: Los `docker-compose.yml` usan `${DOMAIN}` para construir URLs dinámicamente:
```yaml
# En Chatwoot:
FRONTEND_URL: https://chat.${DOMAIN}
# En Evolution:
SERVER_URL: https://api.${DOMAIN}
# En n8n:
WEBHOOK_URL: https://n8n.${DOMAIN}/
```

---

### [02] 💬 Chatwoot CRM

| Variable | Propósito | Valor por defecto |
|:---------|:----------|:-----------------|
| `CHATWOOT_ADMIN_EMAIL` | Email del primer admin | — |
| `CHATWOOT_ADMIN_PASSWORD` | Password del primer admin | — |
| `CHATWOOT_GLOBAL_TOKEN` | Token API para integración con Evolution | Se autogenera |
| `CHATWOOT_ACCOUNT_ID` | ID de la cuenta principal | `1` |
| `CHATWOOT_URL` | URL interna (Docker DNS) | `http://chatwoot-web:3000` |
| `FRONTEND_URL` | URL pública del CRM | `https://chat.${DOMAIN}` |
| `SECRET_KEY_BASE` | Clave criptográfica de Rails (64 bytes hex) | — |

> [!CAUTION]
> `CHATWOOT_URL` **SIEMPRE** debe ser `http://chatwoot-web:3000`. Es la URL INTERNA que Evolution usa para comunicarse con Chatwoot dentro de Docker. Nunca pongas la URL pública aquí.

**Flujo de obtención del CHATWOOT_GLOBAL_TOKEN**:
```
1. sistema_maestro.sh → Opción 1 despliega Chatwoot
2. Chatwoot crea admin automáticamente con CHATWOOT_ADMIN_EMAIL
3. sentinel_engine.py consulta la API y obtiene el access_token
4. Lo inyecta automáticamente en el .env
5. Evolution API lo usa para sincronizar mensajes
```

---

### [03] 🛠️ Infraestructura Core

| Variable | Consumido por | Notas |
|:---------|:-------------|:------|
| `POSTGRES_ROOT_PASSWORD` | db_core (PostgreSQL) | Superusuario `root_admin` |
| `REDIS_PASSWORD` | cache_core (Redis) | Protege el acceso a Redis |

**Bases de datos creadas automáticamente** por `01-segregation.sh`:

| Base de Datos | Usuario | Extensiones | Servicio |
|:-------------|:--------|:-----------|:---------|
| `chatwoot` | `chatwoot_user` | pgcrypto, uuid-ossp | Chatwoot CRM |
| `evolution` | `evolution_user` | pgcrypto, uuid-ossp | Evolution API |
| `n8n` | `n8n_user` | pgcrypto, uuid-ossp | n8n Automation |

**Distribución de Redis Indexes**:

| Index | Servicio | Función |
|:-----:|:---------|:--------|
| 0 | Reservado | — |
| 1 | Chatwoot (Sidekiq + ActionCable) | Cola de jobs y WebSockets |
| 2 | Evolution API | Caché de sesiones WhatsApp |

---

### [04] 🧬 Contraseñas DB por Servicio

| Variable | DB Usuario | URI Resultante |
|:---------|:----------|:---------------|
| `CHATWOOT_DB_PASSWORD` | `chatwoot_user` | `postgresql://chatwoot_user:PASS@db_core:5432/chatwoot` |
| `EVOLUTION_DB_PASSWORD` | `evolution_user` | `postgresql://evolution_user:PASS@db_core:5432/evolution` |
| `N8N_DB_PASSWORD` | `n8n_user` | `postgresql://n8n_user:PASS@db_core:5432/n8n` |

> [!WARNING]
> Las contraseñas de las URIs en `DATABASE_CONNECTION_URI` y `CACHE_REDIS_URI` deben coincidir **exactamente** con las variables individuales. Si cambias una, cambia todas las ocurrencias.

---

### [05] 🔑 API Keys y Cifrado

| Variable | Servicio | Propósito |
|:---------|:---------|:----------|
| `EVOLUTION_API_KEY` | Evolution API | Header `apikey` para autenticar requests |
| `N8N_ENCRYPTION_KEY` | n8n | Cifra credenciales guardadas en workflows |
| `N8N_USER_MANAGEMENT_JWT_SECRET` | n8n | Firma tokens JWT de sesión |

---

### [06] 📱 Evolution API — WhatsApp

| Variable | Propósito |
|:---------|:----------|
| `SERVER_URL` | URL pública de Evolution (`https://api.${DOMAIN}`) |
| `DATABASE_CONNECTION_URI` | Conexión completa a PostgreSQL |
| `CACHE_REDIS_URI` | Conexión a Redis (index 2) |
| `CONFIG_SESSION_PHONE_VERSION` | Versión de WhatsApp Web emulada por Baileys |

---

### [07] 🎤 Audio Transcoding

| Variable | Valor | Propósito |
|:---------|:------|:----------|
| `AUDIO_CONVERTER_ENABLED` | `true` | Activa la transcodificación |
| `WA_BUSINESS_AUDIO_CHANNEL` | `true` | Canal de audio WhatsApp Business |
| `API_AUDIO_CONVERTER` | `http://evolution_audio_converter:4040/process-audio` | URL interna del convertidor |
| `EVOLUTION_AUDIO_CONVERTER_FORCE` | `true` | Forzar incluso si el formato parece correcto |
| `AUDIO_CONVERTER_KEY` | (clave) | Autenticación del servicio |

**Problema resuelto**: WhatsApp envía audio como `.opus` (codec Opus). Los navegadores no reproducen `audio/opus` inline. El Audio Converter transcodifica a OGG/Vorbis que es universalmente compatible.

```
WhatsApp → .opus (audio/opus) → AudioConverter → .ogg (audio/ogg) → MinIO → Browser ✅
```

---

### [08] 🪣 MinIO S3 Storage

| Variable | Valor | Consumidor |
|:---------|:------|:-----------|
| `MINIO_ROOT_USER` | `minioadmin` | MinIO, Evolution, Chatwoot |
| `MINIO_ROOT_PASSWORD` | (password) | MinIO, Evolution, Chatwoot |
| `S3_ENABLED` | `true` | Evolution API |
| `S3_ACCESS_KEY` | = `MINIO_ROOT_USER` | Evolution API |
| `S3_SECRET_KEY` | = `MINIO_ROOT_PASSWORD` | Evolution API |
| `S3_REGION` | `us-east-1` | Requerido por SDK |
| `S3_PORT` | `9000` | Evolution API |
| `S3_ENDPOINT` | `core_minio` | Evolution API |
| `S3_USE_SSL` | `false` | Comunicación interna sin SSL |
| `S3_FORCE_PATH_STYLE` | `true` | MinIO requiere path-style |
| `EVOLUTION_BUCKET` | `evolution-media` | Evolution API |
| `CHATWOOT_BUCKET` | `chatwoot-storage` | Chatwoot |
| `STORAGE_CDN_HOST` | `https://s3.${DOMAIN}` | Chatwoot (URLs públicas) |

> [!CAUTION]
> `S3_ENDPOINT` debe ser **`core_minio`** (nombre del contenedor Docker). NO `minio-core`, NO `localhost`, NO `http://core_minio:9000`. Solo el hostname sin protocolo ni puerto.

**Buckets y sus políticas**:

| Bucket | Política | Función |
|:-------|:---------|:--------|
| `chatwoot-storage` | `download` (público) | Archivos adjuntos del CRM |
| `evolution-media` | `download` (público) | Multimedia de WhatsApp |

---

### [09–12] Variables Complementarias

| Sección | Variables | Propósito |
|:--------|:---------|:----------|
| [09] Admin Panels | `PGADMIN_DEFAULT_EMAIL/PASSWORD` | Acceso a PgAdmin (localhost:5050) |
| [10] n8n | `N8N_HOST`, `WEBHOOK_URL` | Hostname y webhooks públicos |
| [11] AEGIS | `N8N_EXECUTIONS_DATA_*` | Auto-poda de ejecuciones (7 días) |
| [12] Import CW | `CHATWOOT_IMPORT_DATABASE_CONNECTION_URI` | Importar historial Evolution→Chatwoot |

---

## 🔬 Diagnóstico Avanzado

### Verificar que todos los servicios se comunican:

```bash
# 1. PostgreSQL acepta conexiones
docker exec db_core pg_isready -U root_admin

# 2. Redis responde
docker exec cache_core redis-cli -a $(grep REDIS_PASSWORD .env | cut -d= -f2) ping

# 3. MinIO está healthy y tiene buckets
docker exec core_minio mc alias set local http://localhost:9000 minioadmin $(grep MINIO_ROOT_PASSWORD .env | cut -d= -f2)
docker exec core_minio mc ls local/

# 4. Chatwoot responde
curl -s http://localhost:3000/auth/sign_in | head -5

# 5. Evolution API responde
curl -s http://localhost:8080/ | python -m json.tool

# 6. Audio Converter online
docker exec evolution_audio_converter wget -qO- http://localhost:4040 || echo "Esperando..."

# 7. n8n accesible
curl -s http://localhost:5678/healthz
```

---

<div align="center">

**Sentinel OS v11.0** — *Referencia de Configuración*

Desarrollado con 🧬 por **[HackUN09](https://github.com/HackUN09)** & **Antigravity AI**

</div>
