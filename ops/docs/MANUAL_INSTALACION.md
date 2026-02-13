# 📘 Manual de Instalación | Sentinel OS v11.0

**Arquitectura omnicanal empresarial para WhatsApp Business + CRM + Automatización**

---

## 🎯 Introducción

**Sentinel OS v11.0** es un ecosistema de código abierto diseñado para proporcionar una infraestructura conversacional de clase empresarial. Fusiona **Chatwoot CRM**, **Evolution API**, **n8n** y **MinIO S3** en una sola entidad autogestionada y escalable.

---

## ⚙️ Requisitos Previos

### Hardware Mínimo
| Componente | Especificación |
|:-----------|:---------------|
| CPU | 2 cores (4 recomendados) |
| RAM | 4 GB (8 GB recomendados) |
| Disco | 50 GB SSD |
| Red | 10 Mbps simétricos |

### Software Necesario
- **Docker Engine** 24.0+
- **Docker Compose** v2.20+
- **Git** (para clonar el repositorio)
- **Dominio Propio** con DNS configurado
- **Cloudflare Account** (para el túnel seguro)

---

## 🚀 Instalación Paso a Paso

### 1. Preparación del Servidor

```bash
# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Instalar Docker Compose Plugin
sudo apt install docker-compose-plugin -y

# Verificar instalación
docker --version
docker compose version
```

### 2. Clonar el Repositorio

```bash
git clone https://github.com/HackUN09/chatbot-stack.git
cd chatbot-stack
```

### 3. Configurar Variables de Entorno

```bash
# Copiar la plantilla
cp .env.example .env

# Editar con tu editor favorito
nano .env
```

**Variables críticas a configurar**:
- `DOMAIN`: Tu dominio (ej: `isekaichat.com`)
- `CLOUDFLARE_TUNNEL_TOKEN`: Token de tu túnel de Cloudflare
- `CHATWOOT_ADMIN_EMAIL`: Email del administrador
- `POSTGRES_ROOT_PASSWORD`: Contraseña maestra de la DB
- `REDIS_PASSWORD`: Contraseña de Redis
- `MINIO_ROOT_PASSWORD`: Contraseña de MinIO

> [!TIP]
> Puedes dejar las demás contraseñas con el valor predeterminado para un despliegue rápido.

### 4. Configurar Cloudflare Tunnel

1. Accede a [Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. Crear un nuevo túnel: **Networks → Tunnels → Create Tunnel**
3. Copia el token generado
4. Configura los subdominios en **Public Hostname**:

| Subdominio | Servicio | Puerto Interno |
|:-----------|:---------|:---------------|
| `chat.tudominio.com` | `chatwoot-web` | `3000` |
| `api.tudominio.com` | `app_evolution` | `8080` |
| `n8n.tudominio.com` | `app_n8n_editor` | `5678` |
| `s3.tudominio.com` | `minio-core` | `9000` |

### 5. Desplegar el Sistema

```bash
# Ejecutar el orquestador maestro
./sistema_maestro.sh
```

Selecciona la **Opción 1: DEPLOY STACK** desde el menú interactivo.

**Tiempo estimado**: 3-5 minutos (depende de tu conexión a internet).

✅ **Todo es automático**: El sistema creará automáticamente:
- Bases de datos segregadas con extensiones (`pgcrypto`, `uuid-ossp`)
- Buckets de S3 (`chatwoot-storage`, `evolution-media`) con políticas correctas
- Red interna segura para comunicación entre servicios

### 6. Verificación Post-Instalación

```bash
# Ver estado de todos los contenedores
docker ps

# Verificar logs del orquestador
docker logs cloudflared_tunnel --tail 50
```

**Todos los servicios deben mostrar** `STATUS: Up` y `HEALTH: healthy`.

---

## 🔐 Configuración Inicial

### Crear Cuenta de Admin en Chatwoot

1. Accede a `https://chat.tudominio.com`
2. Completa el formulario de registro
3. Verifica tu email (si configuraste SMTP)
4. Accede al dashboard

### Obtener Token de Chatwoot

1. Ve a **Configuración de Perfil** (esquina inferior izquierda)
2. Copia el **Access Token**
3. Actualiza tu archivo `.env`:
```bash
CHATWOOT_GLOBAL_TOKEN=tu_token_aqui
```
4. Reinicia Evolution API:
```bash
docker compose -f modules/02-apps/docker-compose.yml restart app_evolution
```

---

## 🩺 Troubleshooting Común

### Error: "Chatwoot no carga"
**Causa**: Database no ha terminado de inicializarse.
**Solución**:
```bash
docker logs chatwoot --tail 100
# Espera a ver: "Listening on http://0.0.0.0:3000"
```

### Error: "Evolution API no genera código QR"
**Causa**: Versión de WhatsApp Web desactualizada.
**Solución**: El sistema ya está configurado con `CONFIG_SESSION_PHONE_VERSION` actualizado. Si persiste, espera 2-3 minutos.

### Error: "No se ven las imágenes en Chatwoot"
**Causa**: El servicio `minio-core` no está saludable o los buckets no se crearon.
**Solución**: 
```bash
# Verificar estado de MinIO
docker ps | grep minio-core
# Debe mostrar: (healthy)

# Verificar que los buckets existen
docker logs 01-infra-create-buckets-1
# Debe terminar con: "✅ Buckets created successfully!"
```

---

## 📊 Acceso a Servicios

Una vez instalado, puedes acceder a:

| Servicio | URL | Credenciales |
|:---------|:----|:-------------|
| **Chatwoot CRM** | https://chat.tudominio.com | Usuario/Password que creaste |
| **Evolution API** | https://api.tudominio.com | API Key del `.env` |
| **n8n Automation** | https://n8n.tudominio.com | Usuario/Password del `.env` |
| **MinIO Console** | https://s3.tudominio.com | minioadmin / Password del `.env` |

---

## 🔄 Mantenimiento

### Actualizar el Sistema
```bash
git pull origin main
./sistema_maestro.sh
# Selecciona Opción 4: REPAIR & SYNC
```

### Backup de Datos
```bash
# Los datos persisten en la carpeta persistence/
tar -czf backup-$(date +%Y%m%d).tar.gz persistence/
```

### Ver Logs en Tiempo Real
```bash
docker compose -f modules/02-apps/docker-compose.yml logs -f
```

---

**Desarrollado con 💖 por HackUN09 & Antigravity AI** | v11.0
