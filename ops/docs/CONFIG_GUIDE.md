# 📖 GUÍA MAESTRA DE CONFIGURACIÓN Y OPERACIÓN (v9.0 Sentinel OS)

Este manual detalla cómo configurar, operar y dominar el **Sentinel OS Genesis v9.0**.

---

## 1. ⚙️ Variables de Entorno (.env)
El corazón de la configuración. Sentinel OS v9.0 introduce el bloque de **Super-Link**.

### A. Configuración de Red y Gateway
- `DOMAIN`: Tu dominio (ej: `isekaichat.com`).
- `CLOUDFLARE_TUNNEL_TOKEN`: Conecta tu servidor local con el Gateway de Cloudflare.

### B. Bloque Super-Link (v9.0)
- `CHATWOOT_GLOBAL_TOKEN`: Tu token de acceso de Chatwoot (Perfil -> Token de acceso).
- `CHATWOOT_GLOBAL_ACCOUNT_ID`: El ID de tu cuenta de Chatwoot (usualmente `1` o `2`).
- *Sentinel Fixer usará estos valores para vincular Evolution automáticamente.*

### C. Secretos de Infraestructura (Capa 01)
- `POSTGRES_ROOT_PASSWORD`: Contraseña del superusuario.
- `REDIS_PASSWORD`: Seguridad para la caché central.
- `MINIO_ROOT_PASSWORD`: Acceso administrativo al almacenamiento S3 local.

---

## 2. 🏛️ Arquitectura Modular
Sentinel OS utiliza una **Estructura Modular Segregada** bajo la red `secure-net`.

- **Módulo 01 (Infra)**: PostgreSQL 15, Redis 7, MinIO.
- **Módulo 02 (Apps)**: Chatwoot v3.12, Evolution API v2.3.7, n8n Core.
- **Módulo 03 (Tunnel)**: Cloudflared (Acceso Zero-Trust).

---

## 3. 🧩 Operación de Sentinel Fixer v6.0 (El Sanador)
El `sentinel_fixer.py` es el motor de integridad. Sus funciones en v6.0 son:

1.  **Sanitización Blindada**: Limpia el `.env` de espacios extra o bytes nulos al inicio del arranque.
2.  **Vinculación Automática (Auto-Link)**:
    -   Consulta la API de Evolution buscando todas las instancias.
    -   Por cada instancia encontrada, aplica la configuración de Chatwoot definida en el `.env`.
    -   Activa los webhooks de sincronización de contactos y mensajes automáticamente.
3.  **Auto-Heal Purge**: Si una instancia de WhatsApp está en estado `ERROR` o `DISCONNECTED`, purga la sesión físicamente para que puedas escanear el QR desde cero sin conflictos.

---

## 🎮 Operación en Consola (Sistema Maestro)

1.  **Génesis Start (1)**: Lanza todo el stack. Ejecuta el checklist de salud v9.0.
2.  **Sentinel Hyper-Integrity (5)**: 
    -   **Opción Normal**: Verifica conectividad y permisos.
    -   **Opción 'F' (Forzar)**: Realiza una curación profunda, purga sesiones de Evolution y fuerza la re-vinculación de Chatwoot.
3.  **Bóveda de Secretos (7)**: Muestra todas las URLs y contraseñas reales generadas en tu `.env`.
4.  **Auditoría Inteligente (8)**: Ejecuta `system_audit.py` y genera un reporte detallado en `ops/docs/ULTIMATE_AUDIT.md`.

---

## 🔄 Cómo Replicar o Migrar
1.  Clona el repositorio.
2.  Prepara tu `.env` con los dominios y tokens.
3.  Ejecuta `./sistema_maestro.sh`.
4.  Selecciona la **Opción 1**. El sistema se auto-construirá y auto-vinculará.

---
*Robustez. Integridad. Dominación. v9.0 - HackUN09.*
