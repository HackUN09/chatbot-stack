# 🛡️ Sentinel OS: Isekai Hardened Stack v8.0

> **Genesis Edition // The Ultimate Autonomous Infrastructure.** 
> Una arquitectura blindada, autorreparable y diseñada para la dominación digital.

[![Project Status: Operational](https://img.shields.io/badge/Status-Operational-brightgreen.svg)]()
[![Version: 8.0](https://img.shields.io/badge/Version-8.0-blue.svg)]()

---

## 🌟 Visión General
Sentinel OS no es solo un conjunto de contenedores; es un ecosistema autogestionado para el despliegue de Chatbots, automatización masiva y atención omnicanal. Diseñado bajo los principios de **Hyper-Intergrity**, asegura que tu infraestructura esté siempre en línea, reparándose a sí misma ante fallos de sincronización o corrupción de datos.

### 🛠️ Ecosistema Core
- **💬 Chatwoot**: Atención al cliente omnicanal de nivel empresarial.
- **🧬 Evolution API v2**: Pasarela multicanal avanzada (WhatsApp, etc.).
- **⚡ n8n**: Orquestador de flujos de trabajo inteligentes.
- **🐘 PostgreSQL 15**: Motor de datos blindado con segregación de usuarios.
- **🧠 Redis 7**: Capa de caché ultrarrápida con seguridad activa.
- **📦 MinIO**: Almacenamiento de objetos compatible con S3 para multimedia.
- **🌉 Cloudflare Tunnel**: Acceso global Zero-Trust sin exposición de puertos.

---

## 🦾 Características "Genesis Edition v8.0"
- **🎨 UI Cyberpunk/Matrix**: Una consola de mando gamificada para la gestión total.
- **🩺 Protocolo Génesis**: Checklist visual en tiempo real que verifica e higieniza el sistema en cada arranque.
- **⚕️ God Mode (Auto-Healing)**: 
    - Reparación automática de errores 401 (Unauthorized).
    - Sanitización agresiva de `.env` (Zero characters invisibles).
    - Purga inteligente de sesiones corruptas.
- **📸 Génesis Snapshot**: Sistema de respaldos instantáneos de todo el stack.
- **🔐 Vault & Audit**: Registro en tiempo real de secretos y salud del sistema.

---

## 🚀 Despliegue Rápido (Zero-Touch)

### 1. Requisitos
- Docker & Docker Compose.
- Git & Python 3.9+.

### 2. Instalación
```bash
git clone https://github.com/HackUN09/chatbot-stack.git
cd chatbot-stack
cp .env.example .env
# Configura tus dominios y llaves en el .env
```

### 3. Lanzamiento Maestro
```bash
chmod +x sistema_maestro.sh
./sistema_maestro.sh
```
*Selecciona la **Opción 1** para activar el Protocolo Génesis.*

---

## 🏗️ Estructura del Proyecto (Genesis Architecture)
```text
├── modules/           # Capas de Orquestación (01-Infra, 02-Apps, 03-Tunnel)
├── persistence/       # Datos persistentes de todos los servicios
├── ops/               # Operaciones
│   ├── scripts/       # El cerebro de reparación (Sentinel Fixer, Audit)
│   ├── backups/       # Snapshots y volcados SQL
│   └── docs/          # Documentación técnica profunda
└── sistema_maestro.sh # El orquestador interactivo
```

---

## 📜 Documentación Detallada
Para comprender el corazón de la bestia, consulta nuestra documentación extendida:
- [📖 Guía del Sistema Sentinel OS](ops/docs/SYSTEM_GUIDE.md) - Cómo funciona todo por dentro.
- [📑 Reporte de Auditoría](ops/docs/ULTIMATE_AUDIT.md) - Estado de salud en tiempo real.
- [🛡️ Guía de Configuración Blindada](ops/docs/CONFIG_GUIDE.md) - Mejores prácticas de seguridad.

---
*Desarrollado con ❤️ por **HackUN09 & Antigravity**.*
