import secrets
import os

token = "eyJhIjoiMDg2NDMwMjQ4Y2RhNWYwYmE5ZWVjMjRmZTc4YjBhMTAiLCJ0IjoiZDFiY2U5ODktNzRhNi00MzhlLWIzNTItZTM3MTk1ZDI2YjYyIiwicyI6Ik5qUmtaRE5tT1dVdE5XTTNZUzAwWkdWbExXRXdOemt0TTJaa1lqaG1NelEwTnpsaSJ9"

env_content = f"""# ==========================================
# MASTER SECRETS VAULT (ISEKAI STACK)
# Generated at: 2026-01-02
# ==========================================

# --- DOMAIN CONFIG ---
DOMAIN=isekaichat.com

# --- CLOUDFLARE ---
CLOUDFLARE_TUNNEL_TOKEN={token}

# --- INFRASTRUCTURE SECRETS ---
POSTGRES_ROOT_PASSWORD={secrets.token_hex(32)}
REDIS_PASSWORD={secrets.token_hex(32)}
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD={secrets.token_hex(32)}

# --- APP DB PASSWORDS ---
CHATWOOT_DB_PASSWORD={secrets.token_hex(24)}
EVOLUTION_DB_PASSWORD={secrets.token_hex(24)}
N8N_DB_PASSWORD={secrets.token_hex(24)}

# --- APP SECURITY KEYS ---
# Chatwoot
SECRET_KEY_BASE={secrets.token_hex(64)}
# Evolution API
EVOLUTION_API_KEY={secrets.token_hex(32)}
# n8n
N8N_ENCRYPTION_KEY={secrets.token_hex(24)}

# --- MANAGEMENT TOOLS ---
PGADMIN_DEFAULT_EMAIL=admin@isekaichat.com
PGADMIN_DEFAULT_PASSWORD={secrets.token_hex(16)}
"""

with open('.env', 'w') as f:
    f.write(env_content)

print(".env file generated successfully")
