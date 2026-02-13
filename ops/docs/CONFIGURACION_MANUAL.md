# 🔧 Guía de Configuración Manual | Sentinel OS v11.0

**Configuración detallada y quirúrgica de cada componente del ecosistema**

---

## 📑 Tabla de Contenidos

1. [Variables de Entorno Explicadas](#variables-de-entorno-explicadas)
2. [Configuración Manual de Chatwoot](#configuración-manual-de-chatwoot)
3. [Integración Chatwoot ↔ Evolution API](#integración-chatwoot--evolution-api)
4. [Configuración de n8n](#configuración-de-n8n)
5. [MinIO S3 Storage](#minio-s3-storage)
6. [Optimización de PostgreSQL](#optimización-de-postgresql)
7. [Troubleshooting Avanzado](#troubleshooting-avanzado)

---

## 🔐 Variables de Entorno Explicadas

### Capa 01: Gateway & Dominio

```bash
DOMAIN=isekaichat.com
# Tu dominio principal sin www

CLOUDFLARE_TUNNEL_TOKEN=eyJ...
# Token de Cloudflare Zero Trust Tunnel
```

### Capa 02: Chatwoot Core

```bash
CHATWOOT_GLOBAL_TOKEN=wDxv4X3jez9q9jhiCJBDtReG
# API Token obtenido desde Configuración de Perfil en Chatwoot
# CRÍTICO: Necesario para la integración con Evolution API

CHATWOOT_ACCOUNT_ID=1
# ID de cuenta en Chatwoot (usualmente 1 para la primera cuenta)

CHATWOOT_URL=http://chatwoot-web:3000
# URL interna del contenedor Chatwoot (NO uses la URL pública aquí)

FRONTEND_URL=https://chat.isekaichat.com
# URL pública del frontend de Chatwoot
```

### Capa 03: Infraestructura

```bash
POSTGRES_ROOT_PASSWORD=HackUN1991.1
# Password del superusuario postgres

REDIS_PASSWORD=HackUN1991.1  
# Password de Redis (usada por Chatwoot y Evolution)

MINIO_ROOT_PASSWORD=HackUN1991.1
# Password de MinIO S3 Storage
```

### Capa 04: Evolution API

```bash
SERVER_URL=https://api.isekaichat.com
# URL pública de Evolution API

EVOLUTION_API_KEY=HackUN1991.1
# API Key para autenticación en Evolution

DATABASE_CONNECTION_URI=postgresql://evolution_user:password@db_core:5432/evolution?schema=public
# URI completa de conexión a PostgreSQL

CONFIG_SESSION_PHONE_VERSION=2.3000.1033351060
# Versión de WhatsApp Web a emular (actualizado Feb 2026)
```

---

## 📱 Configuración Manual de Chatwoot

### Crear Primera Cuenta

1. Accede a `https://chat.tudominio.com`
2. Completa el formulario inicial:
   - **Nombre Completo**: Tu nombre
   - **Email**: Email del administrador
   - **Password**: Contraseña segura (mín. 8 caracteres)

### Configurar Inbox de WhatsApp

> [!IMPORTANT]
> **NO** crees inboxes manualmente. Evolution API los creará automáticamente cuando configures la integración.

### Obtener API Token

1. Click en tu avatar (esquina inferior izquierda)
2. **Configuración de Perfil**
3. Sección **Access Token**
4. Click en **Copy**
5. Actualiza tu `.env`:
```bash
CHATWOOT_GLOBAL_TOKEN=tu_token_copiado_aqui
```

---

## 🔗 Integración Chatwoot ↔ Evolution API

### Opción A: Configuración Automática (Recomendado)

```bash
./sistema_maestro.sh
# Selecciona Opción 4: REPAIR & SYNC
```

El sistema detectará automáticamente tu token de Chatwoot y configurará todas las instancias de Evolution.

### Opción B: Configuración Manual

1. Accede a Evolution API Manager: `https://api.tudominio.com/manager`
2. Crea una nueva instancia o selecciona una existente
3. Ve a **Settings → Chatwoot**
4. Rellena el formulario:

```yaml
Chatwoot Enabled: ON
Chatwoot URL: http://chatwoot-web:3000
Account ID: 1
Token: wDxv4X3jez9q9jhiCJBDtReG  # Tu token real
Sign Messages: ON
Sign Delimiter: \n
Name Inbox: WhatsApp
Organization: Tu Empresa
Conversation Pending: OFF
Reopen Conversation: ON
Import Contacts: ON
Import Messages: ON
Days Limit: 60
Auto Create: ON
```

5. Click en **Save**

### Verificación de Integración

Verifica que la integración funciona correctamente:

```bash
# Ver logs de Evolution API
docker logs app_evolution --tail 100 | grep -i "chatwoot"

# Deberías ver líneas como:
# "Init message chatwoot bot contact"
# "Chatwoot sync completed"
```

---

## ⚡ Configuración de n8n

### Primer Acceso

1. Accede a `https://n8n.tudominio.com`
2. Crea tu cuenta de administrador
3. Email: El configurado en `.env` (`CHATWOOT_ADMIN_EMAIL`)
4. Password: El configurado en `.env` (`CHATWOOT_ADMIN_PASSWORD`)

### Conectar n8n con Evolution API

1. En n8n, crea un nuevo workflow
2. Agrega un nodo **Webhook**
3. Configura la URL: `https://n8n.tudominio.com/webhook/whatsapp`
4. En Evolution API, ve a **Settings → Webhooks**
5. Agrega la URL del webhook de n8n

### Conectar n8n con Chatwoot

1. En n8n, agrega un nodo **HTTP Request**
2. Configura:
   - **Method**: POST
   - **URL**: `http://chatwoot:3000/api/v1/accounts/1/conversations`
   - **Headers**:
     ```
     api_access_token: tu_chatwoot_token
     Content-Type: application/json
     ```

---

## 🪣 MinIO S3 Storage

### Acceso a la Consola

- **URL**: `https://s3.tudominio.com`
- **Usuario**: `minioadmin`
- **Password**: El de tu `.env` (`MINIO_ROOT_PASSWORD`)

### Buckets S3 (Creación Automática)

✅ **Los buckets se crean AUTOMÁTICAMENTE** al iniciar el stack por primera vez.

El servicio `create-buckets` (basado en `minio/mc`) se ejecuta una sola vez y:
1. Espera a que MinIO esté saludable
2. Crea `chatwoot-storage` (privado)
3. Crea `evolution-media` (público para descarga)
4. Aplica las políticas de acceso correctas

Para verificar que funcionó:
```bash
docker logs 01-infra-create-buckets-1
# Debe terminar con: "✅ Buckets created successfully!"
```

> [!NOTE]
> Si necesitas recrear los buckets, simplemente reinicia el servicio:
> ```bash
> docker restart 01-infra-create-buckets-1
> ```

---

## 🐘 Optimización de PostgreSQL

### Ajustes Recomendados para 4GB RAM

Edita `modules/01-infra/docker-compose.yml`:

```yaml
db_core:
  command: >
    postgres
    -c shared_buffers=256MB
    -c effective_cache_size=1GB
    -c work_mem=16MB
    -c maintenance_work_mem=128MB
    -c max_connections=100
```

### Backup Manual de Base de Datos

```bash
# Backup de todas las bases
docker exec db_core pg_dumpall -U postgres > backup_$(date +%Y%m%d).sql

# Restaurar desde backup
cat backup_20260212.sql | docker exec -i db_core psql -U postgres
```

---

## 🩺 Troubleshooting Avanzado

### Problema: Evolution API no conecta a Chatwoot

**Síntomas**: Los mensajes de WhatsApp no aparecen en Chatwoot

**Diagnóstico**:
```bash
# Verificar conectividad interna
docker exec app_evolution curl -I http://chatwoot:3000

# Verificar token
docker exec app_evolution printenv | grep CHATWOOT
```

**Solución**: Asegúrate de que `CHATWOOT_URL` en `.env` sea `http://chatwoot-web:3000` (no HTTPS).

### Problema: Imágenes no cargan en Chatwoot

**Síntomas**: Los mensajes con imágenes muestran un ícono roto

**Diagnóstico**:
```bash
# Verificar MinIO
docker logs minio-core --tail 50

# Verificar S3_ENDPOINT
cat .env | grep S3_ENDPOINT
```

**Solución**: `S3_ENDPOINT` debe ser el dominio público: `s3.tudominio.com` (no una IP interna).

### Problema: QR Code no aparece

**Síntomas**: Pantalla en blanco al intentar conectar WhatsApp

**Diagnóstico**:
```bash
docker logs app_evolution --tail 200 | grep -i "qr\|baileys"
```

**Solución**: Ya está configurado con `CONFIG_SESSION_PHONE_VERSION` actualizado. Si persiste, espera 2-3 minutos o reinicia el contenedor:
```bash
docker restart app_evolution
```

---

**Documentación v11.0** | Desarrollado por **HackUN09** & **Antigravity AI**
