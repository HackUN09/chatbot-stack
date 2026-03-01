# 📘 Manual de Instalación | Sentinel OS v11.0

> *Guía determinista de despliegue: del `git clone` al sistema operativo en 3 comandos*

---

## 📐 Modelo de Despliegue

El despliegue sigue un **orden topológico estricto** basado en dependencias:

```
Fase 1 (t=0)     → Red Docker (secure-net)
Fase 2 (t=30s)   → PostgreSQL + Redis + MinIO       [Capa de Persistencia]
Fase 3 (t=60s)   → Chatwoot + Evolution + n8n + Audio [Capa de Aplicación]
Fase 4 (t=90s)   → Cloudflare Tunnel                  [Capa de Acceso]
Fase 5 (t=120s)  → Healthchecks + Admin Setup          [Verificación]
```

Cada capa espera a que la anterior tenga `health: healthy` antes de iniciar. Esto garantiza que **nunca hay race conditions** entre servicios.

---

## ⚙️ Prerrequisitos

### 🖥️ Hardware Mínimo

| Componente | Mínimo | Recomendado | Justificación |
|:-----------|:------:|:-----------:|:--------------|
| **CPU** | 2 cores | 4 cores | Chatwoot + Sidekiq consumen ~1.5 CPU |
| **RAM** | 4 GB | 8 GB | PostgreSQL (1G) + Chatwoot (2G) + Evolution (2G) |
| **Disco** | 50 GB SSD | 100 GB SSD | MinIO almacena multimedia; crece con uso |
| **Red** | 10 Mbps | 50 Mbps | WhatsApp descarga archivos multimedia |

### 🔧 Software Necesario

| Software | Versión Mínima | Verificar con | Instalación |
|:---------|:--------------:|:-------------|:------------|
| Docker Engine | 24.0+ | `docker --version` | `curl -fsSL https://get.docker.com \| sh` |
| Docker Compose | v2.20+ | `docker compose version` | Incluido en Docker Engine |
| Git | 2.0+ | `git --version` | `sudo apt install git` |
| Dominio propio | — | DNS apuntando a Cloudflare | Comprar en Namecheap/GoDaddy |
| Cloudflare Account | — | [one.dash.cloudflare.com](https://one.dash.cloudflare.com/) | Cuenta gratuita |

---

## 🚀 Instalación Paso a Paso

### Paso 1 — Preparar el Servidor

```bash
# Actualizar el sistema operativo
sudo apt update && sudo apt upgrade -y

# Instalar Docker (Ubuntu/Debian/WSL)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# ⚠️ Cerrar sesión y volver a entrar para que el grupo docker tome efecto
exit
# Reconectar...

# Verificar que Docker funciona sin sudo
docker run hello-world
docker compose version
```

### Paso 2 — Clonar el Repositorio

```bash
git clone https://github.com/HackUN09/chatbot-stack.git
cd chatbot-stack
```

### Paso 3 — Configurar Variables de Entorno

```bash
# Copiar la plantilla documentada
cp .env.example .env

# Editar con tu editor favorito
nano .env
```

#### 🎯 Variables que DEBES cambiar (mínimo 6):

| Variable | Qué poner | Ejemplo |
|:---------|:----------|:--------|
| `DOMAIN` | Tu dominio sin www | `miempresa.com` |
| `CLOUDFLARE_TUNNEL_TOKEN` | Token de tu tunnel | `eyJhIjoiMD...` |
| `CHATWOOT_ADMIN_EMAIL` | Email del admin | `admin@miempresa.com` |
| `CHATWOOT_ADMIN_PASSWORD` | Password seguro | `MiP@ssw0rd2024!` |
| `POSTGRES_ROOT_PASSWORD` | Password de DB | `DbS3cur3P@ss!` |
| `SECRET_KEY_BASE` | Generar con comando abajo | (64 bytes hex) |

```bash
# Generar SECRET_KEY_BASE automáticamente:
openssl rand -hex 64
```

> [!TIP]
> Las demás variables (`REDIS_PASSWORD`, `MINIO_ROOT_PASSWORD`, `*_DB_PASSWORD`, `EVOLUTION_API_KEY`) puedes dejarlas con el valor por defecto del template para un despliegue rápido. **Cámbialas para producción real.**

### Paso 4 — Configurar Cloudflare Tunnel

1. Accede a [**Cloudflare Zero Trust**](https://one.dash.cloudflare.com/)
2. Navega a **Networks → Tunnels → Create a Tunnel**
3. Nombre del túnel: `sentinel-os` (o el que prefieras)
4. Copia el **token** generado → pégalo en `CLOUDFLARE_TUNNEL_TOKEN`
5. Configura los **4 Public Hostnames**:

| Subdominio | Tipo | Servicio Docker | Puerto |
|:-----------|:----:|:----------------|:------:|
| `chat.tudominio.com` | HTTP | `chatwoot-web` | `3000` |
| `api.tudominio.com` | HTTP | `app_evolution` | `8080` |
| `n8n.tudominio.com` | HTTP | `app_n8n_editor` | `5678` |
| `s3.tudominio.com` | HTTP | `core_minio` | `9000` |

> [!IMPORTANT]
> En Cloudflare, el **tipo** de servicio debe ser `HTTP` (no HTTPS). Cloudflare maneja el SSL automáticamente.

### Paso 5 — Desplegar el Sistema

```bash
# Dar permisos de ejecución
chmod +x sistema_maestro.sh

# Ejecutar el orquestador maestro
./sistema_maestro.sh
```

Selecciona **Opción 1: GENESIS** desde el menú interactivo.

**⏱️ Tiempo estimado**: 3-5 minutos (depende de tu conexión a internet para descargar las imágenes Docker).

#### ✅ Lo que se crea automáticamente:

| Acción | Servicio responsable |
|:-------|:--------------------|
| Red Docker `secure-net` | `docker network create` |
| 3 Bases de datos segregadas (chatwoot, evolution, n8n) | `01-segregation.sh` |
| Extensiones PostgreSQL (pgcrypto, uuid-ossp) | `01-segregation.sh` |
| 2 Buckets S3 con política pública | `create-buckets` (MinIO MC) |
| Usuario Admin de Chatwoot | `chatwoot-web` entrypoint |
| Audio Transcoding habilitado | `evolution_audio_converter` |
| MIME types corregidos en MinIO | `sentinel_engine.py --heal-media` |

### Paso 6 — Verificación Post-Instalación

```bash
# Ver estado de TODOS los contenedores
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Resultado esperado (todos deben decir "Up" y "healthy"):
# db_core                Up (healthy)
# cache_core             Up (healthy)
# core_minio             Up (healthy)
# chatwoot-web           Up (healthy)     127.0.0.1:3000->3000
# chatwoot-worker        Up
# app_evolution          Up               127.0.0.1:8080->8080
# evolution_audio_converter  Up (healthy)
# app_n8n_editor         Up               127.0.0.1:5678->5678
# cloudflared_tunnel     Up
```

---

## 🎯 Acceso a los Servicios

| Servicio | URL | Credenciales |
|:---------|:----|:-------------|
| 💬 **Chatwoot CRM** | `https://chat.tudominio.com` | Email/Password configurados en `.env` |
| 🔵 **Evolution API** | `https://api.tudominio.com` | API Key: `EVOLUTION_API_KEY` del `.env` |
| 🟣 **n8n Automation** | `https://n8n.tudominio.com` | Se crea en el primer acceso web |
| 🪣 **MinIO Console** | `https://s3.tudominio.com` | `minioadmin` / `MINIO_ROOT_PASSWORD` |
| 🐘 **PgAdmin** | `http://localhost:5050` | `PGADMIN_DEFAULT_EMAIL/PASSWORD` |
| ♦️ **Redis Insight** | `http://localhost:5540` | Sin password (solo acceso local) |

---

## 🩺 Troubleshooting Detallado

Cada problema está documentado con: **Síntoma → Causa Raíz → Diagnóstico → Solución Exacta**

---

### 🔴 Problema 1: Chatwoot no carga o tarda mucho

**Síntoma**: Al acceder a `https://chat.tudominio.com` aparece error 502 o la página tarda más de 3 minutos.

**Causa Raíz**: Chatwoot ejecuta `rails db:prepare` en su primer arranque, lo que incluye migraciones de ~200 tablas. Esto puede tomar 2-5 minutos dependiendo del hardware. El healthcheck de Cloudflare Tunnel devuelve 502 mientras Chatwoot aún no está escuchando.

**Diagnóstico**:
```bash
docker logs chatwoot-web --tail 50
# Buscar: "Listening on http://0.0.0.0:3000" = listo
# Si ves: "ActiveRecord::Migration" = aún migrando, espera
```

**Solución**: Esperar. Si después de 5 minutos no arranca:
```bash
# Reiniciar solo Chatwoot
docker restart chatwoot-web
docker logs chatwoot-web -f  # Ver en tiempo real
```

---

### 🔴 Problema 2: Audios de WhatsApp no se reproducen en Chatwoot

**Síntoma**: Los mensajes de audio de WhatsApp aparecen en Chatwoot pero al dar Play no suenan. Los videos se reproducen pero sin audio.

**Causa Raíz** (triple):
1. **Formato incompatible**: WhatsApp envía audio en formato `.opus` con codec Opus. Los navegadores esperan `audio/ogg` con disposición `inline`, pero MinIO servía `audio/opus` con `attachment` → el navegador descargaba en vez de reproducir.
2. **Endpoint S3 incorrecto**: El `.env` tenía `S3_ENDPOINT=minio-core` pero el contenedor se llama `core_minio` → Evolution no podía subir archivos correctamente.
3. **Transcoding desactivado**: El servicio `evolution_audio_converter` no estaba habilitado, por lo que los archivos se almacenaban en formato raw Opus sin transcodificar.

**Solución Aplicada** (automática en v11.0):
```
① evolution_audio_converter intercepta el audio ANTES de almacenarlo
② Transcodifica Opus → OGG (compatible con todos los navegadores)
③ sentinel_engine.py --heal-media corrige MIME types existentes en MinIO:
   Content-Type: audio/opus  → audio/ogg
   Content-Disposition: attachment → inline
④ S3_ENDPOINT corregido a core_minio en todos los archivos
```

**Verificar que funciona**:
```bash
# Audio converter online?
docker ps | grep audio  # → Up (healthy)

# Fix metadatos de archivos existentes:
python ops/scripts/fix_media_metadata.py
```

---

### 🔴 Problema 3: Evolution API no genera código QR

**Síntoma**: Al crear una instancia en Evolution API, el endpoint `/instance/connect` no devuelve el QR code.

**Causa Raíz**: La versión de WhatsApp Web emulada por Baileys estaba desactualizada. WhatsApp bloquea versiones antiguas y no permite generar el QR de autenticación.

**Solución**: Se configuró `CONFIG_SESSION_PHONE_VERSION=2.3000.1033351060` en el `.env`. Esta es la versión de WhatsApp Web verificada como funcional. Si WhatsApp actualiza su versión mínima en el futuro, este valor debe actualizarse.

---

### 🔴 Problema 4: Imágenes y archivos no se ven en Chatwoot

**Síntoma**: Los agentes ven un ícono roto en vez de la imagen/archivo multimedia.

**Causa Raíz** (doble):
1. **Buckets sin política pública**: MinIO crea los buckets como privados por defecto. Chatwoot necesita que `chatwoot-storage` y `evolution-media` tengan política `download` para que el navegador del agente pueda acceder directamente.
2. **Endpoint CDN mal configurado**: Chatwoot construye las URLs de multimedia usando `STORAGE_CDN_HOST`. Si este valor no coincide con el subdominio configurado en Cloudflare Tunnel, el navegador no puede acceder.

**Solución Aplicada** (automática en v11.0):
```bash
# El servicio create-buckets en docker-compose ejecuta:
mc mb --ignore-existing minio/chatwoot-storage
mc mb --ignore-existing minio/evolution-media
mc anonymous set download minio/evolution-media
mc anonymous set download minio/chatwoot-storage

# Y en .env:
STORAGE_CDN_HOST=https://s3.tudominio.com
# ↑ Debe coincidir con el subdominio en Cloudflare Tunnel
```

---

### 🔴 Problema 5: Error de encoding al guardar token en `.env`

**Síntoma**: El script `sentinel_engine.py` fallaba con `UnicodeEncodeError: charmap codec` al guardar el token de Chatwoot.

**Causa Raíz**: Windows usa codificación `cp1252` por defecto. El script intentaba escribir caracteres UTF-8 (emojis en comentarios del `.env`) con la codificación del sistema.

**Solución**: Se forzó `encoding='utf-8'` en todas las operaciones de lectura/escritura de archivos en `sentinel_engine.py`.

---

### 🔴 Problema 6: Docker Compose no encontraba servicios dependientes

**Síntoma**: Error `no such service: minio-core` al levantar los contenedores de aplicaciones.

**Causa Raíz**: El servicio de MinIO se definió como `core_minio` en el `docker-compose.yml` de infraestructura, pero las referencias en `.env` y documentación apuntaban a `minio-core` (guión vs guión bajo).

**Solución**: Se unificó **todo** el proyecto a `core_minio`:
- `.env`, `.env.example`, `.env.bank`
- `CONFIGURACION_MANUAL.md`, `MANUAL_INSTALACION.md`
- `README.md`, `sentinel_engine.py`
- Archivos de referencia internos (`ops/config/envs/`)

---

## 🔄 Mantenimiento

| Operación | Comando | Frecuencia |
|:----------|:--------|:-----------|
| 🔄 Actualizar stack | `git pull && ./sistema_maestro.sh → Opción 4` | Semanal |
| 💾 Backup de datos | `tar -czf backup-$(date +%Y%m%d).tar.gz persistence/` | Diario |
| 📊 Ver logs en vivo | `docker compose -f modules/02-apps/docker-compose.yml logs -f` | Ad-hoc |
| 🧹 Limpieza Docker | `./ops/scripts/clean-docker.sh` | Mensual |
| 🎤 Fix audio metadata | `python ops/scripts/fix_media_metadata.py` | Si hay audios erróneos |
| 🔬 Health global | `docker ps --format "table {{.Names}}\t{{.Status}}"` | Ad-hoc |

---

<div align="center">

**Sentinel OS v11.0** — *Guía de Instalación Determinista*

Desarrollado con 🧬 por **[HackUN09](https://github.com/HackUN09)** & **Antigravity AI**

</div>
