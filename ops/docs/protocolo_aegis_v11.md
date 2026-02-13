# 🩺 Protocolo Aegis: Auto-Curado y Auto-Guardado (Sentinel OS)

Este protocolo define las reglas de equilibrio para que el sistema Sentinel OS sea resiliente y se recupere automáticamente de fallos estructurales o de memoria.

## 1. Estrategia de Auto-Curado (Docker Layer)

Para cada servicio crítico, se aplicarán políticas de reinicio agresivas y validaciones de salud (Healthchecks) quirúgicas:

*   **Restart Policy:** `unless-stopped` o `on-failure:5` para prevenir bucles infinitos en errores fatales.
*   **Healthchecks Activos:**
    *   **Postgres:** `pg_isready -U root_admin` - Reintento cada 10s.
    *   **Redis:** `redis-cli ping` - Verificación de latencia mínima.
    *   **Evolution/n8n:** Wget/Curl interno a los endpoints de status cada 30s.

## 2. Estrategia de Auto-Guardado (Persistence Layer)

El Guardado no es opcional, es sistémico. Se divide en tres fases:

### Fase A: Persistencia en Tiempo Real (S3/MinIO)
*   **Evolution API:** Inyección inmediata de archivos multimedia en el bucket `evolution-media`.
*   **Chatwoot:** Uso de `ActiveStorage` sobre S3 para asegurar que incluso si el contenedor web cae, la data no se pierda.

### Fase B: Poda y Mantenimiento (Pruning)
*   **n8n:** Configuración de `N8N_EXECUTIONS_DATA_PRUNE=true` para limpiar registros mayores a 7 días automáticamente, evitando el agotamiento del disco (causa #1 de muerte del sistema).

### Fase C: Sentinel Vault (Snapshot)
*   Se crea un script `vault_sync.sh` que realiza un dump nocturno de PostgreSQL y un backup de los volúmenes de `persistence/` hacia un almacenamiento externo o bucket de desastre.

## 3. Lógica de Interconexión (Environment Sync)

El archivo `.env` actúa como el **Nexus**. No se permiten variables hardcodeadas en los archivos YAML. Si se cambia la URL de S3 en el Nexus, todos los servicios (n8n, Evolution, Chatwoot) se sincronizan instantáneamente en el próximo despliegue.

---
*Diseñado bajo los principios de Sistemas Dinámicos y Equilibrio de Estado del Sentinel OS.*
