# 📖 Guía del Sistema Sentinel OS (Genesis Edition v9.0)

Esta guía explica el funcionamiento técnico de cada componente de tu stack para que tengas el control total.

## 🕹️ Arquitectura de Orquestación (Súper-Link)

El sistema se basa en una jerarquía de capas representadas en la carpeta `modules/`:
1.  **Capa 01 (Infra):** Bases de Datos (Postgres, Redis) y Almacenamiento (MinIO).
2.  **Capa 02 (Apps):** La lógica de negocio (Chatwoot, Evolution, n8n).
3.  **Capa 03 (Tunnel):** La puerta de enlace segura (Cloudflare Tunnel).

---

## 🔬 Componentes Clave

### 1. `sistema_maestro.sh` (El Cerebro v9.0)
Es el orquestador principal. No solo lanza contenedores, sino que ejecuta el **Protocolo Génesis**:
-   Valida la red interna `secure-net`.
-   Ejecuta el `sentinel_fixer.py` antes de cualquier operación.
-   Realiza un checklist visual de salud en tiempo real.
-   **Vinculación Súper-Link:** Automatiza la conexión entre Evolution y Chatwoot.
-   **Auto-Healing:** Si detecta un error 401 durante el arranque, recrea automáticamente la instancia corrupta.

### 2. `ops/scripts/sentinel_fixer.py` (El Sanador / El "Glaseado" Automático)
Este es el componente de auto-curación ("God Mode") y es quien **automatiza el glaseado** del sistema:
-   **Sanitización de .env:** Elimina caracteres nulos e invisibles que causan errores de autenticación.
-   **Sincronización:** Asegura que las llaves de API entre el `.env` y el Dashboard sean idénticas.
-   **Independencia de Imagen:** Gracias a este script, el "glaseado" se aplica automáticamente a los contenedores. Esto permite que no importe qué imagen uses, el sistema siempre se configure al estilo "Sentinel".
-   **Limpieza de PIDs:** Elimina bloqueos de Chatwoot que impiden el reinicio.

> [!NOTE]
> El código fuente original de Evolution API ha sido movido a `ops/source/evolution-api/` para mantener el proyecto limpio. Es solo una referencia; el sistema funciona basado en la automatización de los scripts.

### 3. `ops/scripts/system_audit.py` (Monitor de Salud)
Genera el reporte `ULTIMATE_AUDIT.md`. Verifica:
-   Estado HTTP de cada servicio (200 OK).
-   Conectividad de red interna.
-   Integridad de variables de entorno críticas.

---

## 🌐 Red y Seguridad

-   **Red Segura (`secure-net`):** Todos los contenedores se comunican internamente en esta red privada. Ninguna base de datos está abierta al público.
-   **Zero-Trust Tunnel:** Cloudflare actúa como un túnel encriptado. Solo el tráfico legítimo hacia tus subdominios llega al servidor.
-   **Persistencia:** Todos tus datos están en la carpeta `persistence/`, protegida y excluida de Git para tu privacidad.

---

## 🛠️ Procedimientos de Mantenimiento

-   **Reinicio Profundo:** Opción 9. Borra contenedores y refresca configuraciones.
-   **Modo Dios Forzado:** Opción 5 -> Presiona 'F'. Ejecuta una cirugía profunda de todas las instancias de Evolution.
-   **Bóveda de Secretos:** Opción 7. Muestra todas tus llaves y accesos reales.

---
*Documentación generada por Antigravity para HackUN09.*
