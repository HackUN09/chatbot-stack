# 🤖 Isekai Chatbot Stack (Sentinel OS v11.0 Gold Master)

![Sentinel OS Banner](https://img.shields.io/badge/Sentinel_OS-v11.0_Gold_Master-46m?style=for-the-badge&logo=matrix&color=00FF41)
![Status](https://img.shields.io/badge/Status-Fully_Operational-brightgreen?style=for-the-badge)

**Sentinel OS** es un ecosistema omnicanal de nivel empresarial diseñado para la dominación total de las comunicaciones mediante IA. Unifica WhatsApp (via Evolution API), Chatwoot y n8n bajo una orquestación centralizada y segura.

---

## 🌟 Características Principales
*   **Gestión Omnicanal**: Controla WhatsApp, Instagram, Messenger y más desde un solo panel (Chatwoot).
*   **Turbo Sync (v11.0)**: Sincronización inyectada directamente en base de datos para máxima velocidad.
*   **Multimedia Perfecta**: Alineación Nativa con S3 (MinIO) para previsualización instantánea de medios.
*   **Escalabilidad Enterprise**: Optimizado con Sidekiq Concurrency para ráfagas masivas de mensajes.
*   **Zero-Touch Deployment**: Orquestador encriptado con capacidades de auto-curación.

---

## 🚀 Guía Rápida de Inicio
El sistema está diseñado para ser desplegado en minutos si tienes los requisitos listos.

### Pasos para el primer despliegue:
1.  **Clonar y Preparar**:
    ```bash
    cp .env.example .env
    ```
2.  **Configurar**: Edita el `.env` con tu dominio y Tunnel Token de Cloudflare.
3.  **Lanzar**:
    ```bash
    ./sistema_maestro.sh
    ```
    Selecciona la **Opción 1** y deja que Sentinel OS haga el resto.

> [!IMPORTANT]
> Lee el [Manual de Configuración](file:///c:/Users/wamr1/Documents/Salvar/Projects/chatbot-stack/ops/docs/CONFIG_GUIDE.md) para completar la vinculación del **Super-Link**.

---

## 🏛️ Arquitectura del Sistema
El stack se divide en tres capas fundamentales protegidas por la red `secure-net`:
1.  **Capa 01 (Infraestrucura)**: Postgres 15, Redis 7, MinIO S3.
2.  **Capa 02 (Aplicaciones)**: Chatwoot Web/Worker, Evolution API, n8n.
3.  **Capa 03 (Seguridad)**: Cloudflare Tunnel (Acceso Global HTTPS).

---

## 🩺 Mantenimiento e Integridad
Sentinel OS no solo corre, se cuida solo:
-   **Sentinel Fixer**: Repara permisos, limpia PIDs corruptos y sincroniza llaves API.
-   **Génesis Snapshot**: Sistema de respaldos en tiempo real para configuraciones y bases de datos.

---
*Diseñado para la eficiencia. Construido para la integridad. v11.0 Gold Master.*
