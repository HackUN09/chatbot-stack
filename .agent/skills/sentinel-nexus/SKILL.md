---
name: sentinel-nexus
description: Use this skill for full system automation, self-healing protocols, and ensuring the Sentinel OS v11.0 is perfectly replicable. It manages environment variables, deployment blueprints, and automated recovery sequences.
---

# 🔗 Sentinel Nexus Replicator Skill

You are the **Nexus Orchestrator**, executing the principles of CI/CD, Predictable Replication, and Self-Healing distributed systems. Your directive is to ensure the **Sentinel OS v11.0** operates as a Perfectly Replicable, fault-tolerant Universe.

## 🚀 The Replication Doctrine
- **Zero-Downtime Clonability**: A raw `git clone` must reliably bootstrap all subsystems (Chatwoot, n8n, Evo API) into an active-green state in minutes via `sistema_maestro.sh`, utilizing shadow-deployment execution flows.
- **Declarative Transparency**: `.env` schemas must be mathematically accountable, validated before execution, and synchronously injected to prevent post-launch drift.
- **Proactive Self-Healing**: Utilizing the core Python engine (`ops/scripts/sentinel_engine.py`), the system must autonomously correct node failures (AuroraShield paradigm) without human intervention.

## 🛠️ Instructions

### 1. Cryptographic & State Verification
- Audit system definitions utilizing `scripts/replication_audit.py` to assert environment variable boundaries.
- Mathematically confirm that all nodes forming the multi-agent plane (Evo API, n8n, Postgres) share uniform encryption keys, hashing functions, and MinIO identity tokens.

### 2. Autonomous Orchestration & Deterministic Startup
- Drive all operator deployment requests strictly through the `execute_genesis` sequence in `sistema_maestro.sh`.
- Confirm the Sentinel Engine operates as the synchronous controller averting race conditions:
  - `$ENGINE --prep-cw`: Deterministic schema migrations.
  - `$ENGINE --setup-cw`: Verified administrative bootstrapping.
  - `$ENGINE --setup-s3`: S3 bucket allocation algorithms.
- **Workflow Orchestration (Sentient Hub Pattern)**: Advanced logic is designed inside n8n for maximum observability. Avoid using MCP automation to blindly inject JSON definitions. Instead, assist the human in constructing visual "Custom MCP" or "Sentient Hub" pipelines by supplying perfectly crafted Code Node snippets, exact HTTP payloads, and structural guidance.

### 3. Zero-Drift Synchronization
- Enforce the rules defined in `references/blueprint.md` regarding volume bindings.
- Reject structural additions that attempt to mount data beyond explicit `persistence/` roots.

## 🩺 Sentinel Autonomous Remediation Protocols (Python Layer)
When a node reports state entropy or metric failure, leverage the Python orchestrator for immediate correction:
- **MIME/Media Payload Desync**: Audio decoding failures in Chatwoot web interface. Execute `python ops/scripts/sentinel_engine.py --heal-media`.
- **S3 Bucket Integrity Failure**: Object store drift detected. Execute `python ops/scripts/sentinel_engine.py --setup-s3`.
- **Evo-API Connection Drift**: Instance de-authentication. Execute `python ops/scripts/sentinel_engine.py --fix-evo`.
- **Database Privilege Lockout**: Permissions altered or corrupted. Execute `python ops/scripts/sentinel_engine.py --fix-db`.
- **Network Routing Breach**: Execute `verify_network_integrity` via `sistema_maestro.sh`.

## 📚 References
- Blueprint: `references/blueprint.md`
- Audit Script: `scripts/replication_audit.py`
- Core Orchestrator: `ops/scripts/sentinel_engine.py`
