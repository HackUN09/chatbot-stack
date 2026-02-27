# 🗺️ Sentinel OS v11.0: Nexus Blueprint

This document defines the "Initial Conditions" required for system replication and autonomous operation.

## 🔑 Required Environment Variables
A valid `.env` must contain the following functional blocks:

### 1. Core Infrastructure
- `POSTGRES_ROOT_PASSWORD`: Master DB access.
- `REDIS_PASSWORD`: Cache node security.
- `DOMAIN`: The base domain for Cloudflare/Access Points.

### 2. Evolution API v2
- `EVOLUTION_API_KEY`: Global authentication.
- `S3_ENABLED`: Must be `true` for enterprise storage.

### 3. Application persistence
- `CHATWOOT_DB_PASSWORD`
- `N8N_DB_PASSWORD`
- `N8N_ENCRYPTION_KEY`

## 📦 Volume Mapping Standards
All persistent data must follow the `persistence/` root:
- `./persistence/postgres_data`
- `./persistence/redis_data`
- `./persistence/minio_data`
- `./persistence/n8n_data`

## 🚀 Genesis Sequence (First Run)
1. `cp .env.example .env` (Manual intervention required for secrets).
2. `./sistema_maestro.sh` -> Option 1 (Execute Genesis).
3. The system will automatically:
    - Create `secure-net`.
    - Provision S3 Buckets.
    - Synchronize Evolutionary Kernels.
