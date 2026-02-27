# 🌐 Formal Topology of Sentinel OS v11.0

This document defines the structural constraints of the system. Any deviation from this topology constitutes "Entropy Drift" and must be rectified.

## 🕸️ Network Architecture
- **Primary Grid**: `secure-net` (Docker Bridge)
- **Isolation Rule**: All database, cache, and internal API services must only expose ports to the `secure-net` grid.

## 🏗️ Service Matrix

| 🛠️ Service | 📦 Container | 🔌 Internal Port | 🚀 Gateway Port | 🛡️ Health Indices |
| :--- | :--- | :--- | :--- | :--- |
| **PostgreSQL** | `db_core` | `5432` | N/A | `pg_isready` |
| **Redis** | `cache_core` | `6379` | N/A | `redis-cli ping` |
| **Evolution API** | `app_evolution` | `8080` | `8080` | `/instance/fetchInstances` |
| **Chatwoot** | `chatwoot` | `3000` | `3000` | HTTP 200 |
| **n8n** | `n8n` | `5678` | `5678` | HTTP 200 |
| **MinIO** | `minio_core` | `9000/9001` | `9001` | `/minio/health/live` |

## 📐 Expansion Axioms
1. **Homogeneity**: New services must use the `0X-feature` naming convention in the `modules/` directory.
2. **Persistence**: All stateful data must be mapped to volumes within the `persistence/` directory.
3. **Connectivity**: Inter-service communication must happen via Container Name (e.g., `http://db_core:5432`) to utilize the Docker internal DNS.
