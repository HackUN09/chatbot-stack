#!/bin/bash
set -e

# ===================================================================
# PostgreSQL - Database Segregation & User Provisioning Script
# ===================================================================
# This script creates isolated databases and users for each service
# in the Sentinel OS stack. Executed automatically on first PostgreSQL boot.
# ===================================================================

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- ==============================================
    -- [1] CHATWOOT DATABASE & USER
    -- ==============================================
    CREATE DATABASE chatwoot;
    CREATE USER chatwoot_user WITH ENCRYPTED PASSWORD '${CHATWOOT_DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE chatwoot TO chatwoot_user;
    ALTER USER chatwoot_user WITH SUPERUSER;

    -- Connect to chatwoot DB to enable extensions
    \c chatwoot
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    
    -- ==============================================
    -- [2] EVOLUTION API DATABASE & USER
    -- ==============================================
    CREATE DATABASE evolution;
    CREATE USER evolution_user WITH ENCRYPTED PASSWORD '${EVOLUTION_DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE evolution TO evolution_user;
    ALTER USER evolution_user WITH SUPERUSER;

    -- Connect to evolution DB to enable extensions
    \c evolution
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    
    -- ==============================================
    -- [3] N8N DATABASE & USER
    -- ==============================================
    CREATE DATABASE n8n;
    CREATE USER n8n_user WITH ENCRYPTED PASSWORD '${N8N_DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n_user;
    ALTER USER n8n_user WITH SUPERUSER;

    -- Connect to n8n DB to enable extensions (just in case)
    \c n8n
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
EOSQL

echo "✅ Database segregation completed successfully."
