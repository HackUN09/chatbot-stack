# 🛡️ Isekai Hardened Stack v5.0 (Sentinel OS)

> **The Ultimate Self-Healing Enterprise Infrastructure.** 
> Una arquitectura blindada, autorreparable y lista para dominar.

---

## 🌟 Visión General
Isekai Stack es una suite completa de herramientas para la automatización de comunicaciones, marketing y flujos de trabajo, diseñada con un enfoque en **seguridad extrema**, **segregación de datos** y **orquestación simplificada**.

### 🛠️ Componentes Core
- **💬 Chatwoot**: Plataforma de atención omnicanal.
- **🧬 Evolution API**: Motor de integración para WhatsApp y APIs de mensajería.
- **⚡ n8n**: Automatización de flujos de trabajo basados en nodos.
- **🐘 PostgreSQL 15**: Base de datos centralizada con usuarios segregados.
- **🧠 Redis 7**: Capa de caché de alto rendimiento.
- **📦 MinIO**: Almacenamiento de objetos compatible con S3.
- **🌉 Cloudflare Tunnel**: Acceso global seguro sin abrir puertos (Zero Trust).

---

## ⚔️ Características "Sentinel OS v5.0"
Este repositorio incluye el **Sistema Maestro (Sentinel OS)**, una consola de mando que ofrece:
- **🎨 Interfaz Cyberpunk**: Experiencia visual premium en terminal.
- **⚕️ Auto-Healing Activo**: El sistema limpia configuraciones (`.env`) y repara estados corruptos (PIDs) en cada inicio.
- **🧹 Sentinel Fixer v2**: Un cerebro de reparación unificado que sincroniza contraseñas, purga basura y garantiza el arranque.
- **📘 Manual Integrado**: Instrucciones completas in-app (Opción `?`).
- **📸 Génesis Snapshot**: Backups instantáneos de todo.
- **🔐 Vault**: Gestión visual de secretos.

---

## 🚀 Instalación Rápida

### 1. Requisitos Previos
- Docker & Docker Compose
- Python 3.9+
- Una cuenta en Cloudflare (para el túnel)

### 2. Configuración
```bash
git clone https://github.com/tu-usuario/chatbot-stack.git
cd chatbot-stack
cp .env.example .env
# Edita el archivo .env con tus credenciales
```

### 3. Lanzamiento
Simplificamos todo a un solo comando:
```bash
chmod +x sistema_maestro.sh
./sistema_maestro.sh
```
*Selecciona la **Opción 1** para iniciar el despliegue secuencial.*

---

## 🏗️ Arquitectura de Directorios (Clean Architecture)
```text
├── modules/           # Capas de Orquestación (Infra, Apps, Tunnel)
├── persistence/       # Datos persistentes (Excluido de Git)
├── ops/               # Operaciones (Scripts, Backups, Documentación)
├── sistema_maestro.sh # El cerebro del stack
└── .env               # Secretos (Excluido de Git)
```

---

## 🛡️ Seguridad
- **Zero Trust**: Acceso externo protegido por Cloudflare.
- **DB Segregation**: Cada aplicación tiene su propio usuario con permisos mínimos.
- **Secrets Management**: Generación de claves criptográficamente seguras.

---

## 📜 Documentación Detallada
Para una inmersión profunda en la configuración, replicación y arquitectura, consulta:
- [📖 Guía Maestra de Configuración y Operación](ops/docs/CONFIG_GUIDE.md)
- [📑 Reporte de Auditoría Real (Autogenerado)](ops/docs/ULTIMATE_AUDIT.md)

---
*Desarrollado con ❤️ por **Antigravity - Sentinel OS**.*
