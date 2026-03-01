# 🏛️ Flujo Arquitectónico | Sentinel OS v11.0

> *Topología de datos, caminos de información y puntos de sincronización*
>
> *"La arquitectura de un sistema define los límites de su inteligencia."*

---

## 📐 Modelo Formal de la Arquitectura

El flujo de información en Sentinel OS se modela como un **grafo dirigido acíclico** (DAG) con 3 capas funcionales:

```
L₃ = Capa de Acceso     = {Cloudflare Tunnel}
L₂ = Capa de Aplicación = {Evolution, Chatwoot, n8n, AudioConverter}
L₁ = Capa de Datos      = {PostgreSQL, Redis, MinIO}
```

**Regla de flujo**: La información siempre fluye `L₃ → L₂ → L₁` (entrada) y `L₁ → L₂ → L₃` (salida). Nunca hay comunicación directa entre capas no adyacentes.

---

## 🔄 Flujo Completo de un Mensaje WhatsApp

```mermaid
sequenceDiagram
    participant U as 👤 Usuario WhatsApp
    participant CF as ☁️ Cloudflare
    participant EVO as 🔵 Evolution API
    participant AC as 🎤 Audio Converter
    participant S3 as 🪣 MinIO S3
    participant CW as 🟢 Chatwoot
    participant CW_W as ⚙️ Sidekiq Worker
    participant N8N as 🟣 n8n
    participant PG as 🐘 PostgreSQL
    participant RD as ♦️ Redis

    Note over U,RD: ① RECEPCIÓN DE MENSAJE

    U->>CF: Mensaje WhatsApp (texto/audio/imagen)
    CF->>EVO: Route api.domain → port 8080

    alt 📝 Mensaje de Texto
        EVO->>PG: Guardar mensaje (tabla: messages)
        EVO->>RD: Cache sesión (index 2)
        EVO->>CW: POST /chatwoot/receive (Super-Link)
    else 🎵 Mensaje de Audio (.opus)
        EVO->>AC: POST /process-audio (Opus → OGG)
        AC-->>EVO: audio.ogg (transcoded)
        EVO->>S3: PUT evolution-media/audio.ogg
        S3-->>EVO: URL pública del archivo
        EVO->>CW: POST /chatwoot/receive + media_url
    else 🖼️ Imagen o Video
        EVO->>S3: PUT evolution-media/file
        S3-->>EVO: URL pública del archivo
        EVO->>CW: POST /chatwoot/receive + media_url
    end

    Note over U,RD: ② PROCESAMIENTO EN CHATWOOT

    CW->>PG: Guardar conversación (tabla: conversations)
    CW->>RD: Publicar en ActionCable (index 1)
    CW->>CW_W: Encolar job Sidekiq
    CW_W->>PG: Actualizar métricas y contadores

    Note over U,RD: ③ AUTOMATIZACIÓN (OPCIONAL)

    EVO->>N8N: Webhook POST /webhook/whatsapp
    N8N->>N8N: Ejecutar workflow (IA, clasificación, etc.)
    N8N->>EVO: Respuesta automática vía API
    EVO->>U: Mensaje de respuesta → WhatsApp

    Note over U,RD: ④ VISUALIZACIÓN POR AGENTE HUMANO

    CW-->>CF: Dashboard en tiempo real
    CF-->>U: 👩‍💼 Agente ve conversación en chat.domain
```

---

## 🧬 Puntos de Integración

### Super-Link: Evolution ↔ Chatwoot

El **Super-Link** es la conexión bidireccional entre Evolution API y Chatwoot CRM:

```
Evolution → Chatwoot (incoming):
  CHATWOOT_URL=http://chatwoot-web:3000   (DNS interno Docker)
  CHATWOOT_TOKEN=${CHATWOOT_GLOBAL_TOKEN}  (Bearer auth)
  CHATWOOT_ACCOUNT_ID=1

Chatwoot → Evolution (outgoing):
  Configurado en Chatwoot → Settings → Integrations → Channel: API
  El agente responde en Chatwoot → Chatwoot llama a Evolution → WhatsApp
```

**Variables críticas**:
- `CHATWOOT_URL` → URL **interna** (nunca la pública)
- `CHATWOOT_GLOBAL_TOKEN` → Se autogenera con `sistema_maestro.sh`
- Si alguna de estas falla, los mensajes llegan a Evolution pero NO aparecen en Chatwoot

### Webhooks: Evolution → n8n

```
Evolution envía webhooks a n8n cuando:
├── Nuevo mensaje recibido → messages.upsert
├── Mensaje actualizado → messages.update
├── QR code generado → qrcode.updated
├── Conexión establecida → connection.update
└── Presencia actualizada → presence.update

Configurar en Evolution API:
POST /webhook/set/{instance}
{
  "url": "https://n8n.tudominio.com/webhook/whatsapp",
  "webhook_by_events": true,
  "events": ["MESSAGES_UPSERT"]
}
```

---

## 💾 Mapa de Almacenamiento

```
┌─────────────────────────────────────────────────────┐
│                    MinIO S3                          │
│  ┌───────────────────┐  ┌───────────────────────┐   │
│  │ evolution-media    │  │ chatwoot-storage      │   │
│  │ (multimedia WA)    │  │ (adjuntos CRM)        │   │
│  │                    │  │                       │   │
│  │ • Imágenes         │  │ • Logos de inbox      │   │
│  │ • Videos           │  │ • Avatares de agentes │   │
│  │ • Audios (.ogg)    │  │ • Archivos adjuntos   │   │
│  │ • Documentos       │  │ • Capturas de QR      │   │
│  │ • Stickers         │  │                       │   │
│  └───────────────────┘  └───────────────────────┘   │
│  Política: download (público) — Acceso vía CDN      │
│  CDN URL: https://s3.tudominio.com                  │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                  PostgreSQL 16                       │
│  ┌──────────┐  ┌───────────┐  ┌──────────────────┐  │
│  │ chatwoot  │  │ evolution │  │       n8n        │  │
│  │           │  │           │  │                  │  │
│  │ ~200 tabs │  │ ~50 tabs  │  │ ~30 tabs         │  │
│  │ Users     │  │ Sessions  │  │ Workflows        │  │
│  │ Convos    │  │ Messages  │  │ Executions       │  │
│  │ Messages  │  │ Contacts  │  │ Credentials      │  │
│  │ Contacts  │  │ Webhooks  │  │ Webhooks         │  │
│  └──────────┘  └───────────┘  └──────────────────┘  │
│  Extensiones: pgcrypto, uuid-ossp en cada DB        │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                   Redis 7.4                          │
│  ┌──────────────────────────────────────────────┐   │
│  │ Index 1: Chatwoot                            │   │
│  │   • Sidekiq jobs (cola de background)        │   │
│  │   • ActionCable (WebSockets en tiempo real)  │   │
│  │   • Cache de vistas y fragmentos             │   │
│  ├──────────────────────────────────────────────┤   │
│  │ Index 2: Evolution                           │   │
│  │   • Cache de sesiones WhatsApp activas       │   │
│  │   • Estado de conexiones Baileys             │   │
│  │   • TTL: 604800s (7 días)                    │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

---

## 🔒 Flujo de Seguridad

```
Internet → Cloudflare → [TLS Terminación] → Tunnel Cifrado → Docker Network → Servicio

Propiedades:
• Ningún puerto expuesto al internet desde el servidor
• TLS cifrado end-to-end por Cloudflare
• Red Docker aislada (secure-net): solo servicios se ven entre sí
• PostgreSQL: no tiene port binding, solo accesible internamente
• Redis: protegido con password + solo red interna
• MinIO: ports en 127.0.0.1 (solo localhost, no accesible desde afuera)
```

---

<div align="center">

**Flujo Arquitectónico v11.0** — *Topología de Datos y Sincronización*

Desarrollado con 🧬 por **[HackUN09](https://github.com/HackUN09)** & **Antigravity AI**

</div>
