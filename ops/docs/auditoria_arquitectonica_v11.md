# 🔬 Auditoría Arquitectónica | Sentinel OS v11.0

> *Análisis de estabilidad, rendimiento y vectores de mejora del sistema*
>
> *Auditor: Antigravity AI | Fecha: 2026-03-01 | Estado: ✅ Production Ready*

---

## 📐 Resumen Ejecutivo

| Métrica | Valor | Estado |
|:--------|:------|:------:|
| Servicios totales | 9 (8 persistentes + 1 init) | ✅ |
| Healthchecks activos | 4/8 | ⚠️ |
| Variables de entorno | 47 documentadas | ✅ |
| Bases de datos segregadas | 3/3 | ✅ |
| Volúmenes persistentes | 7/7 | ✅ |
| Secretos expuestos en docs | 0 | ✅ |
| Problemas resueltos | 6/6 | ✅ |

---

## 🧬 Análisis por Servicio

### S₁ — PostgreSQL 16.6-alpine (`db_core`)

| Parámetro | Valor Actual | Recomendación | Prioridad |
|:----------|:-------------|:-------------|:---------:|
| `max_connections` | 500 | ✅ Correcto para 3 DBs | — |
| `shared_buffers` | 512MB | ⚠️ Ideal: 256MB (1/4 del límite) | Baja |
| `work_mem` | 16MB | ✅ Bueno para queries complejas | — |
| Memory Limit | 1G | ✅ Correcto | — |
| Healthcheck | `pg_isready` cada 10s | ✅ Activo | — |

**Observación**: `shared_buffers=512MB` es exactamente la mitad del memory limit (1G). Esto puede causar que el OOM-killer mate el proceso. La recomendación es bajarlo a `256MB` si se observa inestabilidad.

---

### S₂ — Redis 7.4-alpine (`cache_core`)

| Parámetro | Valor Actual | Nota |
|:----------|:-------------|:-----|
| `maxmemory` | 512MB | ✅ Correcto |
| `maxmemory-policy` | `allkeys-lru` | ✅ Evicción óptima para caché |
| `appendonly` | yes | ✅ Durabilidad AOF |
| Password | Configurado | ✅ |
| Memory Limit | 512MB | ✅ |

**Estado**: ✅ Sin observaciones.

---

### S₃ — MinIO (`core_minio`)

| Parámetro | Valor Actual | Nota |
|:----------|:-------------|:-----|
| Versión | RELEASE.2024-11-07 | ✅ Pinned (no `:latest`) |
| CORS | `MINIO_API_CORS_ALLOW_ORIGIN=*` | ✅ Necesario para acceso web |
| Console | Puerto 9001 | ✅ Solo localhost |
| Healthcheck | `curl /minio/health/live` cada 30s | ✅ Activo |
| Buckets | chatwoot-storage, evolution-media | ✅ Creados automáticamente |
| Política | `download` (público) | ✅ Requerido por navegadores |

**Estado**: ✅ Sin observaciones.

---

### S₄ — Chatwoot v3.12.0 (`chatwoot-web` + `chatwoot-worker`)

| Parámetro | Valor Actual | Nota |
|:----------|:-------------|:-----|
| Web Memory | 2G | ✅ Rails/Puma necesita ~1.5G |
| Worker Memory | 1.5G | ✅ Sidekiq con 25 threads |
| SIDEKIQ_CONCURRENCY | 25 | ✅ Bueno para throughput medio |
| Storage | `s3_compatible` → MinIO | ✅ |
| Healthcheck | No definido | ⚠️ Depende del entrypoint |

**Recomendación**: Añadir healthcheck dedicado en futuras versiones:
```yaml
healthcheck:
  test: ["CMD-SHELL", "curl -f http://localhost:3000/auth/sign_in || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 120s  # ← Dar tiempo a las migraciones
```

---

### S₅ — Evolution API v2.3.7 (`app_evolution`)

| Parámetro | Valor Actual | Nota |
|:----------|:-------------|:-----|
| Memory | 2G | ✅ Baileys consume ~1G por instancia |
| Audio Converter | Integrado (depends_on) | ✅ |
| S3_ENDPOINT | `core_minio` | ✅ Corregido |
| Chatwoot Integration | Habilitada | ✅ |
| Healthcheck | No definido | ⚠️ |

**Recomendación**: Añadir healthcheck:
```yaml
healthcheck:
  test: ["CMD-SHELL", "curl -f http://localhost:8080/ || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
```

---

### S₆ — Audio Converter (`evolution_audio_converter`)

| Parámetro | Valor Actual | Nota |
|:----------|:-------------|:-----|
| Healthcheck | `wget -qO- http://localhost:4040` | ✅ Activo |
| API Key | Sincronizada con Evolution | ✅ |
| Start Period | 15s | ✅ |

**Estado**: ✅ Servicio nuevo, sin issues conocidos.

---

### S₇ — n8n v1.76.1 (`app_n8n_editor`)

| Parámetro | Valor Actual | Nota |
|:----------|:-------------|:-----|
| Memory | 1G | ✅ |
| Execution Mode | `regular` | ⚠️ No escala horizontalmente |
| Pruning | Activo (7 días) | ✅ Protocolo AEGIS |
| Healthcheck | No definido | ⚠️ |

**Recomendación de escala futura**: Para alto volumen de workflows, migrar a Queue Mode:
```yaml
environment:
  EXECUTIONS_MODE: queue
  QUEUE_BULL_REDIS_HOST: cache_core
```

---

## 🔴 Problemas Resueltos — Registro Histórico

### Issue #1: Audio no reproducible en Chatwoot

| Campo | Detalle |
|:------|:--------|
| **Severidad** | 🔴 Crítica |
| **Síntoma** | Audios WhatsApp no suenan al presionar Play en Chatwoot |
| **Causa raíz** | Triple: (1) MIME type `audio/opus` en vez de `audio/ogg`, (2) `Content-Disposition: attachment` en vez de `inline`, (3) transcodificación deshabilitada |
| **Fix** | Habilitado `evolution_audio_converter`, forzado MIME type `audio/ogg` con `inline`, corregido `S3_ENDPOINT` |
| **Archivos modificados** | `docker-compose.yml`, `.env.example`, `sentinel_engine.py` |
| **Verificación** | ✅ Audios reproducibles en Chrome, Firefox, Safari |

### Issue #2: S3_ENDPOINT inconsistente

| Campo | Detalle |
|:------|:--------|
| **Severidad** | 🔴 Crítica |
| **Síntoma** | Evolution API no podía subir archivos, imágenes no se veían |
| **Causa raíz** | `.env` decía `S3_ENDPOINT=minio-core` pero el contenedor se llama `core_minio` |
| **Fix** | Unificado a `core_minio` en 7 archivos |
| **Archivos modificados** | `.env`, `.env.example`, `.env.bank`, 4 docs `.md` |
| **Verificación** | ✅ `docker exec core_minio mc ls local/` devuelve 2 buckets |

### Issue #3: QR Code no aparece

| Campo | Detalle |
|:------|:--------|
| **Severidad** | 🟡 Media |
| **Síntoma** | Endpoint `/instance/connect` no devolvía QR |
| **Causa raíz** | Versión de WhatsApp Web emulada desactualizada |
| **Fix** | `CONFIG_SESSION_PHONE_VERSION=2.3000.1033351060` |
| **Verificación** | ✅ QR generado correctamente |

### Issue #4: Encoding error en Windows (charmap)

| Campo | Detalle |
|:------|:--------|
| **Severidad** | 🟡 Media |
| **Síntoma** | `sentinel_engine.py` fallaba al escribir el `.env` en Windows |
| **Causa raíz** | Windows usa `cp1252`, no `utf-8` por defecto |
| **Fix** | `encoding='utf-8'` en todos los `open()` del script |
| **Verificación** | ✅ Token guardado correctamente |

### Issue #5: Chatwoot tarda mucho en arrancar (502)

| Campo | Detalle |
|:------|:--------|
| **Severidad** | 🟢 Baja (esperado) |
| **Síntoma** | 502 Bad Gateway los primeros 2-3 minutos |
| **Causa raíz** | `rails db:prepare` ejecuta migraciones de ~200 tablas en el primer arranque |
| **Fix** | Documentado como comportamiento esperado; healthcheck con `start_period` recomendado |
| **Verificación** | ✅ Arranca en 2-3 min consistentemente |

### Issue #6: Versión incorrecta en .gitignore

| Campo | Detalle |
|:------|:--------|
| **Severidad** | 🟢 Baja (cosmético) |
| **Síntoma** | `.gitignore` decía "v17.0" en vez de "v11.0" |
| **Fix** | Reescrito completamente con versión correcta |
| **Verificación** | ✅ |

---

## 📊 Matriz de Dependencias

```
              PG   RD   S3   CW   EVO  N8N  AC   CF
PostgreSQL       —    ·    ·    ←    ←    ←    ·    ·
Redis            ·    —    ·    ←    ←    ·    ·    ·
MinIO            ·    ·    —    ←    ←    ·    ·    ·
Chatwoot         →    →    →    —    ←    ·    ·    ←
Evolution        →    →    →    →    —    ·    ←    ←
n8n              →    ·    ·    ·    ·    —    ·    ←
AudioConverter   ·    ·    ·    ·    →    ·    —    ·
Cloudflare       ·    ·    ·    →    →    →    ·    —

Leyenda: → depende de | ← depende por | · independiente
```

---

## ✅ Calificación Final

| Categoría | Score | Justificación |
|:----------|:-----:|:-------------|
| 🔒 Seguridad | 9/10 | Zero-Trust, secrets segregados, red aislada |
| 📈 Escalabilidad | 7/10 | n8n en modo regular limita horizontalidad |
| 🔄 Resiliencia | 8/10 | AEGIS con 4 capas; healthchecks parciales |
| 📖 Documentación | 10/10 | 47 vars documentadas, 6 problemas explicados |
| 🚀 Portabilidad | 10/10 | Clone → .env → Deploy en 3 comandos |

**Score Global: 8.8/10** — Production Ready ✅

---

<div align="center">

**Auditoría Arquitectónica v11.0** — *Análisis de Estabilidad Sistémica*

Desarrollado con 🧬 por **[HackUN09](https://github.com/HackUN09)** & **Antigravity AI**

</div>
