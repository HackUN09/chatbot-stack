# 🧬 GUÍA DE RÉPLICA | Sentinel OS v11.0

> **Si estás leyendo esto, acabas de clonar el repositorio.**
> Esta guía te lleva del `git clone` al sistema 100% funcional.
> No se omite nada. No se asume nada.

---

## 📋 Checklist Rápido (resumen de toda la guía)

```
□ 1. Instalar Docker + Docker Compose
□ 2. Tener un dominio propio
□ 3. Crear un Cloudflare Tunnel con 4 subdominios
□ 4. Clonar este repo
□ 5. cp .env.example .env
□ 6. Editar .env (mínimo 6 variables)
□ 7. chmod +x sistema_maestro.sh && ./sistema_maestro.sh → Opción 1
□ 8. Esperar 3-5 minutos
□ 9. Acceder a https://chat.tudominio.com
□ 10. Conectar WhatsApp escaneando QR en Evolution API
```

**Tiempo total estimado**: 15-30 minutos (la mayoría es configurar Cloudflare).

---

## 🔴 PASO 1 — Instalar Docker

### En Ubuntu/Debian (servidor Linux):
```bash
# Instalar Docker Engine
curl -fsSL https://get.docker.com | sh

# Dar permisos al usuario actual
sudo usermod -aG docker $USER

# ⚠️ IMPORTANTE: Cerrar sesión y volver a entrar
exit
# Reconectar SSH o terminal...

# Verificar
docker --version          # → Docker version 24.x o superior
docker compose version    # → Docker Compose version v2.20+
docker run hello-world    # → Si ves "Hello from Docker!" funciona
```

### En Windows (con Docker Desktop):
1. Descarga [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Instala y reinicia el PC
3. Abre Docker Desktop y verifica que diga "Docker Desktop is running"
4. Abre **Git Bash** (no PowerShell, no CMD)
5. Ejecuta `docker --version` para verificar

### En macOS:
1. Descarga [Docker Desktop para Mac](https://www.docker.com/products/docker-desktop/)
2. Instala y abre Docker Desktop
3. Abre Terminal y ejecuta `docker --version`

---

## 🔴 PASO 2 — Tener un Dominio

Necesitas un **dominio propio** (ej: `miempresa.com`). Puedes comprar uno en:
- [Namecheap](https://www.namecheap.com/) (~$10/año)
- [Google Domains](https://domains.google/) (~$12/año)
- [GoDaddy](https://www.godaddy.com/)

### Configurar DNS en Cloudflare:
1. Crea cuenta en [Cloudflare](https://dash.cloudflare.com/)
2. Añade tu dominio a Cloudflare
3. Cambia los nameservers de tu registrador a los que da Cloudflare
4. Espera propagación DNS (5-30 minutos)

---

## 🔴 PASO 3 — Crear el Túnel de Cloudflare

El túnel es lo que permite que tu servidor (sin IP pública, detrás de un router) sea accesible desde internet de forma segura.

### 3.1 Crear el Túnel:
1. Accede a [Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. Ve a **Networks → Tunnels**
3. Click en **Create a Tunnel**
4. Tipo: **Cloudflared**
5. Nombre: `sentinel-os` (o el que quieras)
6. **Copia el TOKEN** que aparece (empieza con `eyJ...`) — lo usarás en el Paso 6

### 3.2 Configurar los 4 Subdominios:

En la pestaña **Public Hostname**, añade estos 4 hostnames:

| Subdominio | Tipo | URL del servicio |
|:-----------|:----:|:----------------|
| `chat.tudominio.com` | HTTP | `chatwoot-web:3000` |
| `api.tudominio.com` | HTTP | `app_evolution:8080` |
| `n8n.tudominio.com` | HTTP | `app_n8n_editor:5678` |
| `s3.tudominio.com` | HTTP | `core_minio:9000` |

> [!CAUTION]
> **El tipo SIEMPRE es HTTP** (no HTTPS). Cloudflare maneja el SSL automáticamente.
> **La URL no lleva `http://`** — solo `nombre-contenedor:puerto`.

### Resultado visual en Cloudflare:

```
┌─────────────────────────────────────────────────────────┐
│  Tunnel: sentinel-os                                    │
│  Status: 🟢 HEALTHY                                     │
│                                                         │
│  Public Hostnames:                                      │
│  ┌──────────────────────┬──────┬──────────────────────┐ │
│  │ Hostname             │ Type │ Service              │ │
│  ├──────────────────────┼──────┼──────────────────────┤ │
│  │ chat.miempresa.com   │ HTTP │ chatwoot-web:3000    │ │
│  │ api.miempresa.com    │ HTTP │ app_evolution:8080   │ │
│  │ n8n.miempresa.com    │ HTTP │ app_n8n_editor:5678  │ │
│  │ s3.miempresa.com     │ HTTP │ core_minio:9000      │ │
│  └──────────────────────┴──────┴──────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## 🟢 PASO 4 — Clonar el Repositorio

```bash
git clone https://github.com/HackUN09/chatbot-stack.git
cd chatbot-stack
```

---

## 🟢 PASO 5 — Crear tu archivo `.env`

```bash
cp .env.example .env
```

Esto copia la plantilla con 47 variables documentadas. Ahora debes editarla.

---

## 🟡 PASO 6 — Editar el `.env` (LA PARTE MÁS IMPORTANTE)

```bash
nano .env   # o usa: code .env, vim .env, o cualquier editor
```

### 🔴 Variables OBLIGATORIAS (6 — sin estas NO funciona)

| # | Variable | Qué poner | Ejemplo |
|:-:|:---------|:----------|:--------|
| 1 | `DOMAIN` | Tu dominio sin www ni https | `miempresa.com` |
| 2 | `CLOUDFLARE_TUNNEL_TOKEN` | El token del Paso 3 | `eyJhIjoiMD...` (cadena larga) |
| 3 | `CHATWOOT_ADMIN_EMAIL` | Tu email real | `admin@miempresa.com` |
| 4 | `CHATWOOT_ADMIN_PASSWORD` | Password seguro | `MiP@ssw0rd2024!` |
| 5 | `POSTGRES_ROOT_PASSWORD` | Password de la base de datos | `DbS3cur3P@ss!` |
| 6 | `SECRET_KEY_BASE` | Clave criptográfica de 64 bytes | *(ver abajo cómo generar)* |

**Generar SECRET_KEY_BASE:**
```bash
# En Linux/Mac:
openssl rand -hex 64

# En Windows (Git Bash):
openssl rand -hex 64

# Resultado ejemplo (usarlo tal cual, SIN comillas):
# 1d949ab8579a59a307a4ff63b103b3c78c94871b9df7fa7bc1c76a496b357c48...
```

### 🟡 Variables RECOMENDADAS (cambiar para producción real)

| Variable | Por qué cambiarla | Valor predeterminado |
|:---------|:-------------------|:--------------------|
| `REDIS_PASSWORD` | Seguridad de la caché | `CambiaEstaPasswordRedis!` |
| `MINIO_ROOT_PASSWORD` | Acceso al almacenamiento S3 | `CambiaEstaPasswordMinio!` |
| `EVOLUTION_API_KEY` | Proteger la API de WhatsApp | `CambiaEstaApiKeyEvolution!` |
| `N8N_ENCRYPTION_KEY` | Cifrado de credenciales en workflows | `CambiaClaveCifradoN8n32chars!` |
| `CHATWOOT_DB_PASSWORD` | Password de la DB de Chatwoot | `CambiaPasswordChatwootDB!` |
| `EVOLUTION_DB_PASSWORD` | Password de la DB de Evolution | `CambiaPasswordEvolutionDB!` |
| `N8N_DB_PASSWORD` | Password de la DB de n8n | `CambiaPasswordN8nDB!` |

> [!WARNING]
> Si cambias `EVOLUTION_DB_PASSWORD`, **TAMBIÉN** debes cambiar la misma contraseña dentro de `DATABASE_CONNECTION_URI`. Lo mismo aplica para `REDIS_PASSWORD` dentro de `CACHE_REDIS_URI`.
> El `.env.example` tiene comentarios `⚠️` indicando estas dependencias.

### 🟢 Variables que NO necesitas tocar (ya están configuradas)

| Variable | Valor | Por qué no tocarla |
|:---------|:------|:-------------------|
| `CHATWOOT_URL` | `http://chatwoot-web:3000` | DNS interno de Docker, es fijo |
| `CHATWOOT_ACCOUNT_ID` | `1` | Siempre es 1 para instalación nueva |
| `CHATWOOT_GLOBAL_TOKEN` | `SE_AUTOGENERA_AL_DESPLEGAR` | Lo inyecta el script automáticamente |
| `S3_ENDPOINT` | `core_minio` | Hostname Docker de MinIO, es fijo |
| `S3_PORT` | `9000` | Puerto interno de MinIO, es fijo |
| `S3_REGION` | `us-east-1` | MinIO lo ignora pero el SDK lo requiere |
| `API_AUDIO_CONVERTER` | `http://evolution_audio_converter:4040/process-audio` | DNS interno, fijo |
| `MINIO_ROOT_USER` | `minioadmin` | Username por defecto de MinIO |
| `EVOLUTION_BUCKET` | `evolution-media` | Nombre del bucket, se crea automáticamente |
| `CHATWOOT_BUCKET` | `chatwoot-storage` | Nombre del bucket, se crea automáticamente |
| Todas las de `[07]` Audio | Valores correctos | Ya están configuradas para transcoding |
| Todas las de `[11]` AEGIS | Valores correctos | Auto-poda activada a 7 días |

### 📝 Ejemplo COMPLETO de un `.env` funcional (mínimo):

```bash
# Solo las 6 obligatorias cambiadas, todo lo demás con defaults:

DOMAIN=miempresa.com
CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoiMDg2NDMwMjQ4Y2RhNWYwYmE5ZWVjMjRmZTc4YjBhMTAi...
CHATWOOT_ADMIN_EMAIL=juan@miempresa.com
CHATWOOT_ADMIN_PASSWORD=JuanAdmin2024!
POSTGRES_ROOT_PASSWORD=PostgresSeguro2024!
SECRET_KEY_BASE=1d949ab8579a59a307a4ff63b103b3c78c94871b9df7fa7bc1c76a496b357c48...

# Todo lo demás se queda como está en el .env.example
```

---

## 🟢 PASO 7 — Desplegar

```bash
# Dar permisos de ejecución al orquestador
chmod +x sistema_maestro.sh

# Ejecutar
./sistema_maestro.sh
```

Aparecerá un menú con ASCII art. Selecciona **Opción 1: GENESIS**.

### ¿Qué pasa internamente? (en orden):

```
Paso 0 (t=0s)    → Crea red Docker privada "secure-net"
Paso 1 (t=5s)    → Levanta PostgreSQL, Redis, MinIO
                    PostgreSQL crea 3 bases de datos automáticamente
                    MinIO crea 2 buckets con política pública
Paso 2 (t=30s)   → Verifica usuarios de base de datos
Paso 3 (t=45s)   → Levanta Chatwoot, Evolution, Audio Converter, n8n
                    Chatwoot migra ~200 tablas (toma 2-3 min)
Paso 4 (t=60s)   → Levanta Cloudflare Tunnel
Paso 5 (t=90s)   → Espera que TODOS respondan HTTP 200
Paso 6 (t=120s)  → Configura CORS de MinIO + fix MIME types
Paso 7 (t=150s)  → Crea admin de Chatwoot + inyecta token en .env
Paso 8 (t=180s)  → Sincroniza Evolution ↔ Chatwoot
```

**⏱️ Tiempo total**: 3-5 minutos.

Al final verás un **dashboard de credenciales**:

```
 ┌──────────────────────────────────────────────────────────────┐
 │  🛡️  OMEGA VAULT - DEPLOYMENT COMPLETE                       │
 └──────────────────────────────────────────────────────────────┘
   ➤ FRONTEND ACCESS CENTERS:
    • Chatwoot CRM:    https://chat.miempresa.com
    • Evolution API:   https://api.miempresa.com
    • n8n Workflows:   https://n8n.miempresa.com
    • MinIO Storage:   http://localhost:9001
    • pgAdmin Panel:   http://localhost:5050
    • Redis Insight:   http://localhost:5540

   ➤ CREDENCIALES POR SERVICIO:
    ━━━ CHATWOOT CRM ━━━
    • Usuario:      juan@miempresa.com
    • Contraseña:   JuanAdmin2024!
    • Token API:    [auto-generado]

    ━━━ EVOLUTION API ━━━
    • API Key:      [tu EVOLUTION_API_KEY]

    ━━━ MINIO S3 ━━━
    • Usuario:      minioadmin
    • Contraseña:   [tu MINIO_ROOT_PASSWORD]
```

---

## 🟢 PASO 8 — Verificar que Todo Funciona

```bash
# Ver estado de todos los contenedores
docker ps --format "table {{.Names}}\t{{.Status}}"

# Resultado esperado (todos deben decir "Up"):
# NAMES                         STATUS
# app_evolution                 Up 5 minutes
# app_n8n_editor                Up 5 minutes
# cache_core                    Up 5 minutes (healthy)
# chatwoot-web                  Up 5 minutes
# chatwoot-worker               Up 5 minutes
# cloudflared_tunnel            Up 5 minutes
# core_minio                    Up 5 minutes (healthy)
# db_core                       Up 5 minutes (healthy)
# evolution_audio_converter     Up 5 minutes (healthy)
```

---

## 🟢 PASO 9 — Acceder a Chatwoot

1. Abre `https://chat.tudominio.com` en tu navegador
2. Inicia sesión con el email y password del `.env`
3. Ya estás en el CRM — verás el dashboard vacío

---

## 🟢 PASO 10 — Conectar WhatsApp

1. Abre `https://api.tudominio.com` en tu navegador
2. En el header `apikey` usa tu `EVOLUTION_API_KEY`
3. Crea una instancia:
   ```
   POST https://api.tudominio.com/instance/create
   Header: apikey: tu_api_key
   Body: { "instanceName": "mi-whatsapp", "integration": "WHATSAPP-BAILEYS" }
   ```
4. Conecta la instancia:
   ```
   GET https://api.tudominio.com/instance/connect/mi-whatsapp
   Header: apikey: tu_api_key
   ```
5. **Escanea el QR code** con tu WhatsApp (Settings → Linked Devices → Link a Device)
6. ¡Listo! Los mensajes de WhatsApp aparecerán en Chatwoot automáticamente

---

## ❓ Preguntas Frecuentes

### "¿Puedo usar esto sin dominio propio?"
No. Cloudflare Tunnel requiere un dominio. Es la forma segura de exponer los servicios sin abrir puertos.

### "¿Puedo usarlo en una Raspberry Pi?"
Técnicamente sí, pero necesitas mínimo 4GB RAM (idealmente 8GB). La Pi 4 con 8GB funciona.

### "¿Qué pasa si mi servidor se reinicia?"
Todos los servicios tienen `restart: always`. Se levantan automáticamente. Los datos están en `persistence/` y no se pierden.

### "¿Puedo cambiar las contraseñas después del primer despliegue?"
Sí, pero debes:
1. Editar el `.env`
2. Ejecutar `./sistema_maestro.sh → Opción 4 (REPAIR)`
3. Para contraseñas de PostgreSQL, debes cambiarlas también manualmente con SQL

### "¿Cuántas líneas de WhatsApp puedo conectar?"
No hay límite técnico. Cada línea consume ~200MB de RAM adicional en Evolution API. Con 8GB RAM total puedes manejar 3-5 líneas simultáneas.

### "¿Necesito saber programar?"
No. Solo necesitas saber usar la terminal para ejecutar comandos y un editor de texto para el `.env`.

### "¿Los audios funcionan?"
Sí. El sistema incluye un servicio de **Audio Converter** que transcodifica automáticamente los audios de WhatsApp (formato Opus) a OGG, que es compatible con todos los navegadores.

### "¿Qué pasa si necesito restaurar el sistema?"
```bash
# Si tienes backup:
tar -xzf backup-YYYYMMDD.tar.gz    # Restaurar datos
./sistema_maestro.sh → Opción 1    # Re-desplegar

# Si tienes .env.bank (backup de credenciales):
cp .env.bank .env
./sistema_maestro.sh → Opción 1
```

---

## 📊 Resumen de Configuración

```
╔═══════════════════════════════════════════════════════════╗
║  CONFIGURACIÓN MÍNIMA (para que funcione):              ║
║  • 6 variables en .env                                   ║
║  • 1 túnel en Cloudflare con 4 subdominios              ║
║  • Docker instalado                                      ║
║                                                          ║
║  CONFIGURACIÓN COMPLETA (para producción):              ║
║  • 13 variables en .env (6 obligatorias + 7 passwords)  ║
║  • 1 túnel en Cloudflare con 4 subdominios              ║
║  • Docker instalado                                      ║
║  • SMTP configurado en Chatwoot (opcional)               ║
║                                                          ║
║  LO QUE ES AUTOMÁTICO (no tocar):                       ║
║  • 34 variables restantes                                ║
║  • Creación de bases de datos y usuarios                 ║
║  • Creación de buckets S3                                ║
║  • Migraciones de Chatwoot                               ║
║  • Token API de Chatwoot                                 ║
║  • Audio transcoding                                     ║
║  • CORS de MinIO                                         ║
║  • Sincronización Evolution ↔ Chatwoot                   ║
╚═══════════════════════════════════════════════════════════╝
```

---

<div align="center">

**Sentinel OS v11.0** — *Guía de Réplica para Nuevos Usuarios*

Desarrollado con 🧬 por **[HackUN09](https://github.com/HackUN09)** & **Antigravity AI**

</div>
