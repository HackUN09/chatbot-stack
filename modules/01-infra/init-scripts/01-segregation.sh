#!/bin/sh
set -e

echo "--- INIT: Creating Segregated Users & Databases ---"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Chatwoot
    CREATE USER chatwoot_user WITH PASSWORD '$CHATWOOT_DB_PASSWORD';
    CREATE DATABASE chatwoot OWNER chatwoot_user;
    GRANT ALL PRIVILEGES ON DATABASE chatwoot TO chatwoot_user;

    -- Evolution API
    CREATE USER evolution_user WITH PASSWORD '$EVOLUTION_DB_PASSWORD';
    CREATE DATABASE evolution OWNER evolution_user;
    GRANT ALL PRIVILEGES ON DATABASE evolution TO evolution_user;

    -- n8n
    CREATE USER n8n_user WITH PASSWORD '$N8N_DB_PASSWORD';
    CREATE DATABASE n8n OWNER n8n_user;
    GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n_user;
EOSQL

echo "--- INIT: Users Verified ---"
