# 📖 GUÍA MAESTRA DE CONFIGURACIÓN Y OPERACIÓN (v11.0 Sentinel OS)

Este manual es la autoridad definitiva para desplegar el **Sentinel OS Genesis v11.0 Gold Master**. Sigue estos pasos para un sistema perfecto.

---

## 🛠️ Requisitos Previos (Antes de empezar)
Para que el sistema funcione, **DEBES** tener listos los siguientes datos externos:
1.  **Dominio Propio**: Un dominio apuntando a tu servidor (ej: `isekaichat.com`).
2.  **Cloudflare Tunnel**: Crea un túnel en Cloudflare Zero Trust y obtén el **Tunnel Token**.
3.  **Docker & Docker Compose**: Instalados y operativos en tu servidor Linux.

---

## 🚀 Guía de Arranque (Paso a Paso)

### 1. Preparación del Entorno
Copia la plantilla de secretos y configúrala:
```bash
cp .env.example .env
```
Edita el `.env` y rellena los campos críticos:
- `DOMAIN`: Tu dominio real.
- `CLOUDFLARE_TUNNEL_TOKEN`: Tu token de Cloudflare.
- **Passwords**: Puedes generarlas manualmente o usar el script `python ops/scripts/generate_secrets.py` para llenar los campos `generate_...`.

### 2. El Primer Lanzamiento
Ejecuta el orquestador principal:
```bash
./sistema_maestro.sh
```
Selecciona la **Opción 1: Lanzar Sistema Completo**.
> [!NOTE] 
> En este primer arranque, Chatwoot se instalará pero aún no tendrás el Token de API para el Super-Link. Es normal que veas una advertencia de vinculación al final.

### 3. Configuración del Super-Link (Sincronización Total)
Para que Evolution API y Chatwoot hablen perfectamente:
1. Entra a `https://chat.tu-dominio.com`.
2. Crea tu cuenta de Administrador.
3. Ve a **Ajustes de Perfil** (abajo a la izquierda) y copia el **Token de Acceso**.
4. Edita tu `.env` y pega el token en `CHATWOOT_GLOBAL_TOKEN`.
5. Asegúrate de que `CHATWOOT_GLOBAL_ACCOUNT_ID` coincida con tu ID de cuenta (por defecto es `1`).
6. Reinicia el sistema desde el menú (Opción 2 y luego Opción 1) o simplemente ejecuta la **Opción 5 (Sentinel Hyper-Integrity)**.

---

## 📂 Glosario de Variables Críticas

| Variable | Descripción | Importancia |
| :--- | :--- | :--- |
| `S3_ENDPOINT` | Dominio público de tu S3 (MinIO). | **Crítica** para ver fotos/audios. |
| `SIDEKIQ_CONCURRENCY` | Hilos de procesamiento de mensajes. | **Alta** para ráfagas de usuarios. |
| `TURBO_SYNC_URI` | Enlace directo a la DB de Chatwoot. | **Alta** para no perder historial. |

---

## 🩺 Resolución de Problemas (Troubleshooting)

- **¿No se ven las imágenes?**: Asegúrate de que `S3_ENDPOINT` sea `s3.tu-dominio.com` y no una IP interna.
- **¿Error 401 en Evolution?**: Usa la **Opción 5** en el menú principal para re-sincronizar llaves.
- **¿Sistema lento?**: Verifica los logs con la **Opción 4** para identificar cuellos de botella en la base de datos.

---
*Robustez. Integridad. Dominación. v11.0 - Protocolo Sentinel.*
