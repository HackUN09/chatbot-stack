# Auditoría Arquitectónica: Sentinel OS v11.0 vs. Cánones Técnicos

Este documento presenta una crítica constructiva y científica del estado actual de **Sentinel OS**, comparando la implementación local con las mejores prácticas extraídas de los manuales técnicos oficiales (NotebookLM).

## 1. Capa de Datos (PostgreSQL 16.6)
### 🔍 Hallazgo: Sobre-asignación de Buffers
*   **Estado Actual:** `shared_buffers=512MB` con un límite de contenedor de `memory: 1G`.
*   **Crítica:** La documentación oficial de PostgreSQL (v15) recomienda un valor inicial del **25%** de la memoria del sistema (aprox. 256MB en este caso). Asignar el 50% (`512MB`) puede ahogar la memoria de trabajo (**work_mem**) y el caché del sistema operativo, aumentando el riesgo de OOM (Out Of Memory) en ráfagas de alta concurrencia.
*   **Mejora Propuesta:** Ajustar `shared_buffers` a `256MB` y aumentar `max_wal_size` para manejar picos de escritura sin checkpoints frecuentes.

## 2. Capa de Caché (Redis 7)
### 🔍 Hallazgo: Riesgo de OOM por Overhead
*   **Estado Actual:** `maxmemory 512mb` con un límite de contenedor de `memory: 512M`.
*   **Crítica:** Redis tiene un consumo interno de memoria por metadatos y buffers de replicación/clientes. Si `maxmemory` es igual al límite del contenedor, el kernel matará el proceso (OOM Kill) antes de que Redis pueda ejecutar su política de desalojo (`allkeys-lru`).
*   **Mejora Propuesta:** Reducir `maxmemory` a `400MB` (~80% del límite del contenedor) para dar margen operativo al proceso.

## 3. Capa de Automatización (n8n)
### 🔍 Hallazgo: Modo Monolítico vs. Escalamiento
*   **Estado Actual:** Modo ejecución simple (Editor).
*   **Crítica:** Para un stack que pretende ser empresarial y escalable (**total_environment**), la guía oficial recomienda **Queue Mode** (Redis + Workers). El modo actual bloquea ejecuciones pesadas y puede saturar el editor en ráfagas de mensajes.
*   **Mejora Propuesta:** Transicionar a `Queue Mode` segregando el contenedor del Editor de los Workers para procesar mensajes de Evolution API en paralelo sin afectar la UI.

## 4. Orquestación (Docker & Seguridad)
### 🔍 Hallazgo: Inconsistencia en Salud (Healthchecks)
*   **Estado Actual:** n8n y MinIO carecen de `healthcheck` definido en el `compose`.
*   **Crítica:** Sin healthchecks, el orquestador no puede reiniciar automáticamente servicios zombis.
*   **Mejora Propuesta:** Implementar healthchecks basados en las APIs internas de cada servicio para asegurar la auto-recuperación (**self-healing**).

## 5. Gestión de Entorno (.env)
### 🔍 Hallazgo: Dispersión de Secretos
*   **Estado Actual:** Variables duplicadas entre `.env` y el bloque `environment` de los archivos YAML.
*   **Crítica:** Dificulta la replicación ("Sentinel Nexus").
*   **Mejora Propuesta:** Consolidar el uso de `env_file` y usar variables de sustitución solo para parámetros dinámicos, manteniendo el `.env` como única fuente de verdad (SSoT).

---
*Este análisis ha sido generado comparando los 9 cuadernos científicos de Sentinel con la implementación física en disco.*
