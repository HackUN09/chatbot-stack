# 🛠️ REPORTE TÉCNICO: SOLUCIÓN MULTIMEDIA Y SINCRONIZACIÓN
**Sentinel OS v11.0 Gold Master**

Este documento detalla los fallos críticos encontrados y las soluciones definitivas aplicadas para garantizar la estabilidad de **isekaichat.com**.

---

## 1. 📂 El Enemigo Invisible: Corrupción Binaria (.env)
### Error:
Los contenedores (especialmente Evolution API) reportaban errores de "invalid hostname" o fallos de autenticación en Redis/S3 a pesar de que las credenciales en el archivo `.env` del host parecían correctas.

### Causa Raíz:
El despliegue desde Windows inyectaba caracteres ocultos de retorno de carro (`\r` o `CR`) en las variables de entorno. Las librerías de Node.js interpretaban estos caracteres como parte del valor (ej. `S3_SECRET_KEY="pass\r"`), rompiendo la autenticación y el parsing de URLs.

### Solución Definitiva:
- Saneamiento a nivel binario de todos los archivos de configuración eliminando `\r`.
- Implementación de un flujo de despliegue con terminaciones de línea Unix (`LF`) estrictas.

---

## 2. 🌐 El Dilema del Almacenamiento S3 (MinIO)
### Error:
Las imágenes y audios se procesaban en el servidor pero no se visualizaban en la interfaz de Chatwoot.

### Causa Raíz:
Se estaban usando hostnames internos de Docker (ej. `http://core_minio:9000`). Cuando el navegador del usuario intentaba cargar la imagen, fallaba porque `core_minio` no es un dominio resoluble en internet.

### Solución Definitiva:
- **Alineación S3 Pública**: Se configuró tanto Evolution API como Chatwoot para usar `https://s3.isekaichat.com`.
- **Active Storage Alignment**: Se configuró Chatwoot con `s3_compatible` y el bloque `STORAGE_*` para forzar la generación de links públicos.

---

## 3. 🚀 Cuellos de Botella y Mensajes Perdidos
### Error:
En ráfagas de mensajes simultáneos, algunos mensajes aparecían en Chatwoot y otros desaparecían.

### Causa Raíz:
- Límites de concurrencia bajos en el worker de Chatwoot (Sidekiq).
- Latencia en el flujo de webhooks estándar.

### Solución Definitiva:
- **Modo Turbo DB**: Se habilitó `CHATWOOT_IMPORT_DATABASE_CONNECTION_URI`. Evolution API ahora escribe directamente en la DB de Chatwoot, eliminando la latencia del webhook.
- **Alta Concurrencia**: Se incrementó `SIDEKIQ_CONCURRENCY` y `RAILS_MAX_THREADS` a 20 hilos.

---

## 🎭 Resumen de Variables Críticas (Bóveda)
| Variable | Valor Recomendado | Motivo |
| :--- | :--- | :--- |
| `S3_ENDPOINT` | `s3.dominio.com` | Debe ser público para previsualización. |
| `S3_USE_SSL` | `true` | Obligatorio para túneles HTTPS. |
| `STORAGE_FORCE_PATH_STYLE` | `true` | Compatibilidad requerida por MinIO. |
| `SIDEKIQ_CONCURRENCY` | `20` | Estabilidad ante ráfagas de usuarios. |

---
*Documento generado por Sentinel OS v11.0 - Protocolo de Integridad Total.*
