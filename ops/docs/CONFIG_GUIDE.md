# 📖 GUÍA MAESTRA DE CONFIGURACIÓN Y OPERACIÓN (v5.0 Sentinel OS)

Esta documentación es el manual definitivo para replicar, modificar y dominar el **Isekai Hardened Stack**. Aquí se detalla cada engranaje del sistema para que puedas personalizarlo al 100%.

---

## 1. ⚙️ Variables de Entorno (.env)
El corazón de la configuración. Se divide en 5 bloques críticos:

### A. Configuración de Red
- `DOMAIN`: El dominio raíz (ej: `tuempresa.com`). Afecta a todos los subdominios de los servicios.
- `CLOUDFLARE_TUNNEL_TOKEN`: La llave que conecta tu servidor local con el Gateway de Cloudflare.

### B. Secretos de Infraestructura (Nivel 01)
- `POSTGRES_ROOT_PASSWORD`: Contraseña del superusuario `root_admin`.
- `REDIS_PASSWORD`: Contraseña para el acceso a la caché central.
- `MINIO_ROOT_PASSWORD`: Acceso administrativo al almacenamiento S3.

### C. Contraseñas de Base de Datos (Segregadas)
- `CHATWOOT_DB_PASSWORD`: Usada por el rol `chatwoot_user`.
- `EVOLUTION_DB_PASSWORD`: Usada por el rol `evolution_user`.
- `N8N_DB_PASSWORD`: Usada por el rol `n8n_user`.

---

## 2. 🏛️ Arquitectura de Capas
El sistema utiliza una **Estructura Modular Segregada** para garantizar que un fallo en una app no tumbe la base de datos.

- **Módulo 01 (Infra)**: PostgreSQL, Redis, MinIO, PgAdmin, Redis Insight.
- **Módulo 02 (Apps)**: Chatwoot (Web/Worker), Evolution API, n8n.
- **Módulo 03 (Tunnel)**: Cloudflared (El único punto de salida/entrada).

### Red Interna: `secure-net`
- **Subnet**: `172.25.0.0/16`
- **DNS Interno**: Los contenedores se comunican entre sí por su nombre (ej: `db_core`, `cache_core`). **NUNCA** uses `localhost` para comunicación entre contenedores.

---

## 3. 🧩 Ajustes Específicos por Servicio

### Chatwoot (Optimizado para 2GB+ RAM)
- **Imagen**: `chatwoot/chatwoot:v3.12.0` (Elegida por estabilidad en Ruby 3.2).
- **S3 Storage**: Configurado para usar el servicio local `core_minio`.
- **Región**: Se fuerza `AWS_REGION=us-east-1` para compatibilidad con el driver de S3.

### Evolution API (v2.1.1)
- **Database Provider**: Debe ser `postgresql`.
- **URI de Conexión**: `postgresql://user:pass@db_core:5432/evolution?schema=public`. Es vital incluir `?schema=public` en Postgres 15.

### PgAdmin 4
- **Puerto Local**: Cambiado a **5050**. Si necesitas cambiarlo, edita `modules/01-infra/docker-compose.yml`.

---

## 4. 🎮 Operación del Sistema Maestro (v5.0)
El script `./sistema_maestro.sh` es tu orquestador autocurativo. Estas son sus funciones clave:

1.  **Génesis Start (1)**:
    *   **Auto-Heal Check**: Antes de iniciar, ejecuta `sentinel_fixer.py` para limpiar el `.env` y eliminar PIDs zombis.
    *   **Secuencia**: Infra -> Espera a DB -> Apps -> Tunnel.
2.  **Sentinel Doctor (5)**: Verifica salud de DB/Redis.
    *   **Técnica 'F' (Fix)**: Sincroniza contraseñas (DB vs .env) y repara permisos de esquema.
3.  **Nuclear Clean (9)**: Detiene todo, purga volúmenes temporales, limpia imágenes huérfanas y reinicia desde cero.
4.  **Audit (8)**: Genera el `ULTIMATE_AUDIT.md`.
5.  **Manual (Espacio / ?)**: Muestra la ayuda interactiva.

---

## 5. 🔄 Cómo Replicar este Proyecto
Si quieres mover este stack a otro PC:
1.  Instala Docker Desktop y Git.
2.  Clona el repositorio.
3.  Crea tu propio `.env` basándote en `.env.example`.
4.  Ejecuta `./sistema_maestro.sh` y selecciona la opción **1**.
5.  Si el sistema detecta que es la primera vez, el script de "Doctor" te ayudará a inicializar las bases de datos.

---
## 🆘 Resolución de Problemas Comunes
- **"401 Unauthorized" en Evolution**: Asegúrate de que el Manager tenga configurada la `EVOLUTION_API_KEY` global que está en tu `.env`.
- **Chatwoot no arranca**: Revisa que `db_core` y `cache_core` estén en estado `ONLINE`.
- **Logs colapsados**: Usa la **Opción 4** del Maestro para filtrar logs por servicio específico.

*Isekai Stack: Robustez por diseño, simplicidad por elección.*
