# 🛡️ Sentinel OS — Security Architecture & SSRF Hardening

## Overview
Sentinel OS v11.1 implements a multi-layered security strategy to protect the conversation pipeline while maintaining high performance. This document details the specific protections against SSRF (Server-Side Request Forgery) and the Zero-Trust network model.

---

## 1. Zero-Trust Networking (Cloudflare Tunnel)
The entire stack operates without exposing any public ports on the host machine. 
- **Mechanism**: A `cloudflared` container establishes an outbound connection to Cloudflare's edge.
- **Traffic**: All incoming requests (api.dominio.com, chat.dominio.com, etc.) are routed through the tunnel directly to the internal Docker network.
- **Benefit**: No open ports (80, 443, 8080) means no direct surface for port scanning or brute-force attacks on the host.

## 2. SSRF Hardening (The "422 Fix")
Chatwoot, being a Rails application, has strict protections against fetching resources from local or internal IPs to prevent SSRF attacks. In a Docker environment, this often results in `422 Unprocessable Content` errors when Evolution API sends internal media URLs.

### Our Solution:
1. **SSRF Safe List**: We explicitly whitelist internal service identifiers in Chatwoot's environment.
   ```yaml
   SSRF_SAFE_LIST: "core_minio,chatwoot-web,evolution_audio_converter,app_evolution"
   ```
2. **Public CDN Reference**: Evolution API is configured with `S3_PUBLIC_URL`. When it sends an attachment to Chatwoot, it provides the public CDN link (via Cloudflare) instead of the internal `core_minio` link. This ensures Chatwoot can safely "see" the file from a trusted public source.

## 3. Internal Webhook Patching
To avoid "Hairpinning" (where a container calls its own public domain and goes through the internet and back), Sentinel OS implements dynamic patching.
- **Problem**: Default webhooks often point to `https://api.dominio.com`, causing 30s timeouts in Cloudflare.
- **Fix**: The `sentinel_engine.py` script automatically modifies the webhook URL in Chatwoot to point to `http://app_evolution:8080`.
- **Security**: Since this happens entirely within the `secure-net` Docker network, the traffic never leaves the machine, reducing latency and exposure.

## 4. Database Segregation
We follow the principle of least privilege for data access.
- **Schema Separation**: Evolution, Chatwoot, and n8n each have their own dedicated database and user.
- **Restricted Access**: The `evolution_user` cannot access the `chatwoot` database, and vice versa.
- **Automation**: The `01-segregation.sh` script handles this during the first boot.

## 5. Media Persistence Security
- **MinIO Policies**: Buckets are created with `download` policy for public access via CDN, but `upload/delete` operations are restricted to authenticated internal services.
- **Deduplication**: Files are stored with content-based hashes to prevent unauthorized file enumeration.

---

*Sentinel OS v11.1 — HackUN09 & Antigravity AI*
