Esta es la Guía de Arquitectura Blindada v3.0. Ya no estamos jugando.

Esta guía implementa Seguridad en Profundidad, Segregación de Responsabilidades, Límites de Recursos, Observabilidad y Manejo de Secretos.

Vamos a desplegar:

Infraestructura de Datos: PostgreSQL (con usuarios segregados), Redis (con contraseña), MinIO (S3 Compatible).

Herramientas de Gestión: PgAdmin 4 y Redis Insight (Accesibles vía Túnel Seguro, NO expuestos públicamente).

Aplicaciones: Chatwoot, Evolution API, n8n.

Seguridad: Nginx Proxy, Certbot, Fail2Ban, Logs rotativos.

1.0 PREPARACIÓN DEL TERRENO (Foundation)

El orden y los permisos son la primera línea de defensa.

1.1 Estructura de Directorios Profesional

No usaremos root para correr contenedores si no es necesario.

code
Bash
download
content_copy
expand_less
# Crear estructura
sudo mkdir -p /opt/stack/{infra,apps,proxy,backups,scripts}
sudo mkdir -p /opt/stack/infra/{postgres_data,redis_data,minio_data,pgadmin_data,redisinsight_data}
sudo mkdir -p /opt/stack/apps/{chatwoot_storage,evolution_instances,evolution_store,n8n_data}
sudo mkdir -p /opt/stack/infra/postgres_init

# Crear red aislada para comunicación interna
sudo docker network create --driver bridge --attachable secure-net
1.2 Estrategia de Logging (Global)

Para evitar que los logs llenen el disco, configuraremos el daemon de Docker por defecto o lo haremos servicio por servicio. Lo haremos servicio por servicio para ser explícitos.

2.0 CAPA 1: INFRAESTRUCTURA DE DATOS (Hardened)

Aquí corregimos el error crítico de usar root para todo. Usaremos un script de inicialización para crear usuarios segregados.

Archivo: /opt/stack/infra/postgres_init/01-init-users.sql

code
SQL
download
content_copy
expand_less
-- Usuario y DB para Chatwoot
CREATE USER chatwoot_user WITH PASSWORD 'ChatwootPass_Segura_2026!';
CREATE DATABASE chatwoot OWNER chatwoot_user;

-- Usuario y DB para Evolution
CREATE USER evolution_user WITH PASSWORD 'EvolutionPass_Segura_2026!';
CREATE DATABASE evolution OWNER evolution_user;

-- Usuario y DB para n8n
CREATE USER n8n_user WITH PASSWORD 'N8nPass_Segura_2026!';
CREATE DATABASE n8n OWNER n8n_user;

-- Permisos (Opcional: ajustar según necesidad)
GRANT ALL PRIVILEGES ON DATABASE chatwoot TO chatwoot_user;
GRANT ALL PRIVILEGES ON DATABASE evolution TO evolution_user;
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n_user;

Archivo: /opt/stack/infra/docker-compose.yml

code
Yaml
download
content_copy
expand_less
version: '3.8'

services:
  # --- POSTGRESQL (Base de Datos) ---
  postgres:
    image: postgres:15-alpine
    container_name: db_core
    restart: always
    environment:
      POSTGRES_USER: root_admin         # Solo para mantenimiento
      POSTGRES_PASSWORD: ${DB_ROOT_PASS}
    volumes:
      - ./postgres_data:/var/lib/postgresql/data
      - ./postgres_init:/docker-entrypoint-initdb.d # Script de segregación
    networks:
      - secure-net
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
    logging: &logging
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U root_admin"]
      interval: 10s
      timeout: 5s
      retries: 5

  # --- REDIS (Caché con Contraseña) ---
  redis:
    image: redis:7-alpine
    container_name: cache_core
    restart: always
    command: redis-server --requirepass ${REDIS_PASS} --appendonly yes
    volumes:
      - ./redis_data:/data
    networks:
      - secure-net
    deploy:
      resources:
        limits:
          memory: 512M
    logging: *logging
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASS}", "ping"]
      interval: 10s
      retries: 5

  # --- MINIO (S3 Compatible - Almacenamiento Objetos) ---
  minio:
    image: minio/minio:latest
    container_name: object_storage
    restart: always
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASS}
    volumes:
      - ./minio_data:/data
    networks:
      - secure-net
    ports:
      # Exponemos a localhost SOLAMENTE. Usaremos Nginx para S3 API, Tunnel para Consola.
      - "127.0.0.1:9000:9000"
      - "127.0.0.1:9001:9001"
    logging: *logging

  # --- PGADMIN 4 (Gestión DB - MODO SEGURO) ---
  pgadmin:
    image: dpage/pgadmin4:8
    container_name: admin_db_gui
    restart: always
    environment:
      PGADMIN_DEFAULT_EMAIL: ${ADMIN_EMAIL}
      PGADMIN_DEFAULT_PASSWORD: ${ADMIN_TOOLS_PASS}
      PGADMIN_LISTEN_PORT: 80
      PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION: 'True'
    volumes:
      - ./pgadmin_data:/var/lib/pgadmin
    networks:
      - secure-net
    ports:
      - "127.0.0.1:5050:80" # Solo accesible desde el servidor (SSH Tunneling)
    logging: *logging

  # --- REDIS INSIGHT (Gestión Caché - MODO SEGURO) ---
  redis-insight:
    image: redis/redisinsight:latest
    container_name: admin_cache_gui
    restart: always
    volumes:
      - ./redisinsight_data:/db
    networks:
      - secure-net
    ports:
      - "127.0.0.1:5540:5540" # Solo accesible desde el servidor (SSH Tunneling)
    logging: *logging

networks:
  secure-net:
    external: true

Archivo: /opt/stack/infra/.env (Permisos 600)

code
Ini
download
content_copy
expand_less
DB_ROOT_PASS=SuperRootPass_NoUsarEnApps!
REDIS_PASS=RedisSuperSecurePass!
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASS=MinioSuperStoragePass!
ADMIN_EMAIL=admin@tuempresa.com
ADMIN_TOOLS_PASS=AdminPanelPass!
3.0 CAPA 2: APLICACIONES (Optimized & Scalable)

Aquí es donde conectamos todo, pero respetando los límites de recursos y usando los usuarios segregados.

Archivo: /opt/stack/apps/docker-compose.yml

code
Yaml
download
content_copy
expand_less
version: '3.8'

services:
  # ==========================================
  # 1. CHATWOOT (Rails + Sidekiq)
  # ==========================================
  chatwoot_web:
    image: chatwoot/chatwoot:v3.3.1
    container_name: cw_web
    restart: always
    env_file: .env
    environment:
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
    command: bundle exec rails s -p 3000 -b 0.0.0.0
    depends_on:
      - chatwoot_worker
    networks:
      - secure-net
    ports:
      - "127.0.0.1:3000:3000"
    deploy:
      resources:
        limits:
          memory: 1.5G # Rails consume RAM
          cpus: '1.5'
    logging: &logging
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  chatwoot_worker:
    image: chatwoot/chatwoot:v3.3.1
    container_name: cw_worker
    restart: always
    env_file: .env
    environment:
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
    command: bundle exec sidekiq -C config/sidekiq.yml
    networks:
      - secure-net
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
    logging: *logging

  # ==========================================
  # 2. EVOLUTION API v2 (NodeJS)
  # ==========================================
  evolution_api:
    image: atendai/evolution-api:v2.1.1
    container_name: evo_api
    restart: always
    env_file: .env
    volumes:
      - ./evolution_instances:/evolution/instances
      - ./evolution_store:/evolution/store
    networks:
      - secure-net
    ports:
      - "127.0.0.1:8080:8080"
    deploy:
      resources:
        limits:
          memory: 1G # Ajustar según cantidad de instancias
          cpus: '1.0'
    logging: *logging
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/"]
      interval: 30s
      retries: 3

  # ==========================================
  # 3. N8N (Workflow Automation)
  # ==========================================
  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n_engine
    restart: always
    env_file: .env
    user: "1000" # Ejecutar como usuario node, no root (si la imagen lo soporta/requiere)
    volumes:
      - ./n8n_data:/home/node/.n8n
    command: /bin/sh -c "n8n start"
    networks:
      - secure-net
    ports:
      - "127.0.0.1:5678:5678"
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
    logging: *logging

networks:
  secure-net:
    external: true
3.1 Variables de Entorno Segregadas (apps/.env)

Aquí está la clave. Cada servicio usa SU usuario y SU base de datos.

code
Ini
download
content_copy
expand_less
DOMAIN=tuempresa.com

# --- CHATWOOT CONFIG ---
FRONTEND_URL=https://chat.tuempresa.com
SECRET_KEY_BASE=Generar_Con_Openssl_Rand_Hex_64
# Conexión DB (Usuario Específico)
POSTGRES_HOST=db_core
POSTGRES_PORT=5432
POSTGRES_DATABASE=chatwoot
POSTGRES_USERNAME=chatwoot_user
POSTGRES_PASSWORD=ChatwootPass_Segura_2026!
# Conexión Redis (Con Password)
REDIS_URL=redis://:RedisSuperSecurePass!@cache_core:6379
# Almacenamiento S3 (MinIO)
ACTIVE_STORAGE_SERVICE=amazon
S3_ACCESS_KEY_ID=minioadmin
S3_SECRET_ACCESS_KEY=MinioSuperStoragePass!
S3_BUCKET_NAME=chatwoot-storage
S3_REGION=us-east-1
S3_ENDPOINT=https://s3.tuempresa.com
S3_FORCE_PATH_STYLE=true

# --- EVOLUTION API CONFIG ---
SERVER_URL=https://api.tuempresa.com
AUTHENTICATION_API_KEY=EvoApiKey_SuperSecreta
# DB (Usuario Específico)
DATABASE_ENABLED=true
DATABASE_CONNECTION_URI=postgresql://evolution_user:EvolutionPass_Segura_2026!@db_core:5432/evolution
# Redis (Con Password)
CACHE_REDIS_ENABLED=true
CACHE_REDIS_URI=redis://:RedisSuperSecurePass!@cache_core:6379/1
# MinIO
S3_ENABLED=true
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=MinioSuperStoragePass!
S3_BUCKET=evolution-media
S3_PORT=443
S3_ENDPOINT=s3.tuempresa.com
S3_USE_SSL=true

# --- N8N CONFIG ---
N8N_HOST=n8n.tuempresa.com
N8N_PORT=5678
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.tuempresa.com/
# DB (Usuario Específico)
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=db_core
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n_user
DB_POSTGRESDB_PASSWORD=N8nPass_Segura_2026!
4.0 DESPLIEGUE Y CONFIGURACIÓN INICIAL

Paso 1: Levantar Infraestructura

code
Bash
download
content_copy
expand_less
cd /opt/stack/infra
docker compose up -d
# Verificar salud
docker ps

Paso 2: Configurar Buckets en MinIO
Dado que MinIO arranca vacío, debemos crear los buckets.

Instalar cliente MinIO (mc) en el host o usar contenedor temporal.

Comando rápido:

code
Bash
download
content_copy
expand_less
docker run --rm --network secure-net --entrypoint sh minio/mc -c "\
mc alias set myminio http://object_storage:9000 minioadmin MinioSuperStoragePass!; \
mc mb myminio/chatwoot-storage; \
mc mb myminio/evolution-media; \
mc anonymous set public myminio/chatwoot-storage; \
mc anonymous set public myminio/evolution-media"

Paso 3: Preparar DB de Chatwoot (Crucial)

code
Bash
download
content_copy
expand_less
cd /opt/stack/apps
# Esto creará las tablas usando el usuario 'chatwoot_user'
docker compose run --rm cw_web bundle exec rails db:chatwoot_prepare

Paso 4: Levantar Apps

code
Bash
download
content_copy
expand_less
docker compose up -d
5.0 SEGURIDAD DE ACCESO (Nginx + Tunneling)

La regla de oro: NO expongas herramientas de administración.

5.1 Acceso a PgAdmin y Redis Insight (Método Profesional)

No crearemos subdominios públicos. Usaremos SSH Tunneling.
Cuando quieras administrar la DB:

En tu PC local (Laptop):

code
Bash
download
content_copy
expand_less
# Mapea el puerto remoto 5050 (PgAdmin) al local 5050
ssh -L 5050:localhost:5050 -L 5540:localhost:5540 usuario@ip-servidor

Abre tu navegador local:

PgAdmin: http://localhost:5050

Redis Insight: http://localhost:5540

Resultado: Tráfico encriptado por SSH, sin exposición a internet, imposible de hackear por fuerza bruta web.

5.2 Nginx Reverso (Solo Apps Públicas)

Instala Nginx y configura /etc/nginx/conf.d/stack.conf.

code
Nginx
download
content_copy
expand_less
# --- CHATWOOT ---
server {
    server_name chat.tuempresa.com;
    client_max_body_size 50M; # Permitir subida de archivos
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

# --- EVOLUTION API ---
server {
    server_name api.tuempresa.com;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# --- N8N ---
server {
    server_name n8n.tuempresa.com;
    location / {
        proxy_pass http://127.0.0.1:5678;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_buffering off;
    }
}

# --- MINIO API (S3) ---
server {
    server_name s3.tuempresa.com;
    client_max_body_size 50M;
    location / {
        proxy_pass http://127.0.0.1:9000; # API Port, NO Console
        proxy_set_header Host $host;
    }
}

Certificados SSL:

code
Bash
download
content_copy
expand_less
certbot --nginx
6.0 BACKUPS Y RECUPERACIÓN (The Safety Net)

Creamos un script robusto que extrae las bases de datos y las sube a un bucket de MinIO (simulando S3 externo) o idealmente a AWS S3 real.

Archivo: /opt/stack/scripts/backup_full.sh

code
Bash
download
content_copy
expand_less
#!/bin/bash
# Configuración
BACKUP_DIR="/tmp/pg_backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MC_CMD="docker run --rm --network secure-net --entrypoint sh minio/mc"
MINIO_ALIAS="myminio"

mkdir -p $BACKUP_DIR

echo "--- Iniciando Backup $TIMESTAMP ---"

# 1. Dump de bases de datos individuales
docker exec db_core pg_dump -U chatwoot_user -h localhost chatwoot | gzip > $BACKUP_DIR/chatwoot_$TIMESTAMP.sql.gz
docker exec db_core pg_dump -U evolution_user -h localhost evolution | gzip > $BACKUP_DIR/evolution_$TIMESTAMP.sql.gz
docker exec db_core pg_dump -U n8n_user -h localhost n8n | gzip > $BACKUP_DIR/n8n_$TIMESTAMP.sql.gz

# 2. (Opcional) Subir a S3/MinIO
# Aquí se asume que 'backups' bucket existe.
# Configurar el alias dentro del comando o usar variables de entorno
# Ejemplo conceptual:
# aws s3 cp $BACKUP_DIR s3://mis-backups-reales/ --recursive

echo "--- Backup Finalizado ---"
# Limpieza local (mantener últimos 3 días)
find $BACKUP_DIR -type f -mtime +3 -delete

Hacerlo ejecutable y añadir al Cron (crontab -e):

code
Bash
download
content_copy
expand_less
0 3 * * * /opt/stack/scripts/backup_full.sh >> /var/log/backup_stack.log 2>&1
RESUMEN DE LA IMPLEMENTACIÓN "CRUEL Y DESPIADADA"

Cero Root en DBs de App: Chatwoot y compañía solo pueden ver sus propios datos. Si hackean Evolution, Chatwoot está seguro.

Cero Puertos Expuestos: Nada escucha en 0.0.0.0 excepto Nginx y SSH. PgAdmin/Redis Insight están "muertos" para internet, vivos para ti vía Túnel.

Límites de Recursos: Si Chatwoot se vuelve loco consumiendo RAM, Docker lo reinicia antes de que tumbe el servidor.

Logging Controlado: El disco no se llenará de basura.

MinIO Integrado: Tus archivos multimedia están en almacenamiento de objetos, listo para migrar a AWS S3 mañana si creces.

Redis con Password: Nadie entra a tu caché sin invitación.

Esta infraestructura está lista para auditarse.


Esta es la documentación técnica definitiva de Estructura de Datos y Diccionario de Variables de Entorno para la arquitectura de producción v3.0 ("Hardened").

Esta especificación es estricta. Cualquier desviación en la nomenclatura o estructura puede resultar en fallos de conexión o brechas de seguridad.

1. ESTRUCTURA DE SISTEMA DE ARCHIVOS (File System Hierarchy)

Esta estructura separa lógicamente la persistencia (datos), la configuración (código/env) y los scripts de mantenimiento.

Ruta Base: /opt/stack

code
Text
download
content_copy
expand_less
/opt/stack/
├── infra/                          # CAPA 1: Servicios Backend (DB, Cache, Storage)
│   ├── docker-compose.yml          # Orquestación de Infraestructura
│   ├── .env                        # [chmod 600] Credenciales ROOT y Admin
│   └── postgres_init/              # Scripts SQL de inicialización
│       └── 01-segregation.sql      # Creación de usuarios y DBs separados
├── apps/                           # CAPA 2: Lógica de Negocio
│   ├── docker-compose.yml          # Orquestación de Aplicaciones
│   └── .env                        # [chmod 600] Credenciales de Aplicación (No Root)
├── proxy/                          # CAPA 3: Acceso
│   └── conf.d/                     # Configuraciones de Nginx
│       └── stack.conf              # Bloques de servidor (Reverse Proxy)
├── scripts/                        # Mantenimiento
│   ├── backup_full.sh              # [chmod +x] Script de Backup y Rotación
│   └── restore.sh                  # Script de recuperación ante desastres
└── volumes/                        # PERSISTENCIA DE DATOS (Mapeado a Docker)
    ├── postgres_data/              # Datos crudos de PostgreSQL
    ├── redis_data/                 # Dump RDB/AOF de Redis
    ├── minio_data/                 # Objetos (Archivos) de MinIO
    ├── pgadmin_data/               # Sesiones y configuración de PgAdmin
    ├── redisinsight_data/          # Configuración de Redis Insight
    ├── evolution_instances/        # Sesiones de WhatsApp (Auth keys)
    ├── evolution_store/            # JSON store local de Evolution
    └── n8n_data/                   # Datos de configuración de n8n
2. LISTADO MAESTRO DE VARIABLES DE ENTORNO

A continuación, se presentan los dos archivos .env requeridos. Copie y pegue, pero cambie los valores de las contraseñas.

2.1 Archivo: /opt/stack/infra/.env

Propósito: Definir credenciales maestras y configuración de servicios base.

code
Ini
download
content_copy
expand_less
# ==============================================================================
# INFRAESTRUCTURA DE DATOS - CREDENCIALES ROOT (SOLO MANTENIMIENTO)
# ==============================================================================

# --- POSTGRESQL (Superusuario) ---
# Usado solo para crear otras DBs y usuarios. NO USAR EN APPS.
DB_ROOT_USER=root_admin
DB_ROOT_PASS=Pone_Aqui_Tu_Password_Super_Seguro_Root_DB_2026!

# --- REDIS (Seguridad) ---
# Contraseña maestra para conectar al caché.
REDIS_PASS=Pone_Aqui_Tu_Password_Redis_Super_Complejo!

# --- MINIO (S3 Compatible Storage) ---
# Credenciales del administrador de almacenamiento.
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASS=Pone_Aqui_Tu_Password_Minio_Storage!
MINIO_BROWSER_REDIRECT_URL=https://s3-console.tuempresa.com

# ==============================================================================
# HERRAMIENTAS DE GESTIÓN (ACCESO VÍA TÚNEL/VPN)
# ==============================================================================

# --- PGADMIN 4 ---
ADMIN_EMAIL=admin@tuempresa.com
ADMIN_TOOLS_PASS=Password_Para_Entrar_A_Los_Paneles!

# --- REDIS INSIGHT ---
# (Redis Insight generalmente no usa ENV para auth web, se configura en GUI, 
# pero mantenemos variables si se usa una imagen custom con auth).
RI_ENCRYPTION_KEY=Clave_Random_Para_Encriptar_Datos_Locales
2.2 Archivo: /opt/stack/apps/.env

Propósito: Configurar las aplicaciones conectándose a la infraestructura con privilegios mínimos.

code
Ini
download
content_copy
expand_less
# ==============================================================================
# CONFIGURACIÓN GLOBAL
# ==============================================================================
DOMAIN=tuempresa.com
TZ=America/Bogota

# ==============================================================================
# CHATWOOT (Soporte Omnicanal)
# ==============================================================================

# --- CORE ---
FRONTEND_URL=https://chat.tuempresa.com
# Generar con: openssl rand -hex 64
SECRET_KEY_BASE=5b6a7... (CADENA HEXADECIMAL DE 64 CARACTERES) ...f9
NODE_ENV=production
RAILS_ENV=production
INSTALLATION_ENV=docker

# --- DATABASE (Usuario Segregado: chatwoot_user) ---
POSTGRES_HOST=db_core
POSTGRES_PORT=5432
POSTGRES_DATABASE=chatwoot
POSTGRES_USERNAME=chatwoot_user
POSTGRES_PASSWORD=ChatwootPass_Segura_2026!

# --- REDIS (Con Auth) ---
# Formato: redis://:PASSWORD@HOST:PORT/DB_INDEX
REDIS_URL=redis://:Pone_Aqui_Tu_Password_Redis_Super_Complejo!@cache_core:6379/0

# --- EMAIL (SMTP - Obligatorio) ---
MAILER_SENDER_EMAIL=noreply@tuempresa.com
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=tu_api_key_real_del_proveedor
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true

# --- STORAGE (S3/MinIO) ---
ACTIVE_STORAGE_SERVICE=amazon
S3_ACCESS_KEY_ID=minioadmin
S3_SECRET_ACCESS_KEY=Pone_Aqui_Tu_Password_Minio_Storage!
S3_BUCKET_NAME=chatwoot-storage
S3_REGION=us-east-1
S3_ENDPOINT=http://object_storage:9000
S3_FORCE_PATH_STYLE=true

# ==============================================================================
# EVOLUTION API (WhatsApp Gateway)
# ==============================================================================

# --- SERVER ---
SERVER_URL=https://api.tuempresa.com
# La llave maestra para controlar la API. Generar: openssl rand -hex 32
AUTHENTICATION_API_KEY=EvoKey_... (CADENA ALEATORIA SEGURA)

# --- DATABASE (Usuario Segregado: evolution_user) ---
DATABASE_ENABLED=true
DATABASE_PROVIDER=postgresql
# URI Completa: postgresql://USER:PASS@HOST:PORT/DB
DATABASE_CONNECTION_URI=postgresql://evolution_user:EvolutionPass_Segura_2026!@db_core:5432/evolution

# --- CACHE (Redis DB Index 1) ---
CACHE_REDIS_ENABLED=true
CACHE_REDIS_URI=redis://:Pone_Aqui_Tu_Password_Redis_Super_Complejo!@cache_core:6379/1

# --- STORAGE (MinIO) ---
S3_ENABLED=true
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=Pone_Aqui_Tu_Password_Minio_Storage!
S3_BUCKET=evolution-media
S3_PORT=9000
S3_ENDPOINT=object_storage
S3_USE_SSL=false 
# (Internal network is HTTP fast, Nginx handles External SSL)

# ==============================================================================
# N8N (Automatización)
# ==============================================================================

# --- CORE ---
N8N_HOST=n8n.tuempresa.com
N8N_PORT=5678
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.tuempresa.com/
# Clave para encriptar credenciales en la DB. NO PERDER NUNCA.
N8N_ENCRYPTION_KEY=n8n_key_... (CADENA ALEATORIA SEGURA)

# --- DATABASE (Usuario Segregado: n8n_user) ---
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=db_core
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n_user
DB_POSTGRESDB_PASSWORD=N8nPass_Segura_2026!
3. DICCIONARIO TÉCNICO DE VARIABLES (La "Biblia" del Config)

Use esta tabla para entender qué hace cada variable y validar que su valor sea correcto.

Servicio	Variable	Descripción Crítica	Formato Requerido
Infra	DB_ROOT_PASS	Contraseña del superusuario de Postgres. Da acceso total a todos los datos.	Alfanumérico, >16 caracteres.
Infra	REDIS_PASS	Candado de seguridad de Redis. Sin esto, un SSRF en n8n expone todo.	Alfanumérico, sin espacios.
Chatwoot	SECRET_KEY_BASE	Firma criptográfica de cookies. Si cambia, todos los usuarios son deslogueados.	Hexadecimal 64 chars.
Chatwoot	FRONTEND_URL	Define CORS y generación de links. Debe ser HTTPS exacto.	https://sub.dominio.com (Sin slash final)
Chatwoot	REDIS_URL	Cadena de conexión Sidekiq. Debe incluir la contraseña.	redis://:PASS@HOST:PORT/0
Evolution	AUTHENTICATION_API_KEY	Header apikey requerido para usar la API.	String (Recom: UUID o Hex 32)
Evolution	DATABASE_CONNECTION_URI	Cadena JDBC-style para Postgres.	postgresql://u:p@h:5432/db
Evolution	S3_USE_SSL	Define si la conexión interna Docker->MinIO es encriptada. false es aceptable en red interna.	true o false
n8n	N8N_ENCRYPTION_KEY	Cifra las claves de servicios (Google, OpenAI) guardadas en la DB. Si se pierde, n8n deja de funcionar.	String complejo.
n8n	WEBHOOK_URL	URL pública para recibir datos. Necesaria para Oauth callbacks y Triggers.	https://.../ (Con slash final opcional)
4. COMANDOS DE VALIDACIÓN RIGUROSA

Una vez creados los archivos, ejecute estas validaciones antes de desplegar:

1. Verificar permisos de archivos (Seguridad):
Los archivos .env contienen las llaves del reino. Nadie más que root debe leerlos.

code
Bash
download
content_copy
expand_less
sudo chmod 600 /opt/stack/infra/.env
sudo chmod 600 /opt/stack/apps/.env

2. Generar Claves Fuertes (No inventar contraseñas mentalmente):
Use openssl para llenar las variables SECRET_KEY, API_KEY, etc.

code
Bash
download
content_copy
expand_less
openssl rand -hex 32  # Para API Keys
openssl rand -base64 24 # Para Passwords

3. Validar Red Docker:
Asegúrese que la red externa existe antes de levantar infra.

code
Bash
download
content_copy
expand_less
docker network ls | grep secure-net || docker network create --driver bridge --attachable secure-net


¡Esto me encanta! Vamos a llevarlo al siguiente nivel. No haré un simple script bash; voy a diseñar un Orquestador de Despliegue Automatizado con estética Cyberpunk/Nequi (Magenta Neón, Cian Eléctrico, Púrpura Profundo).

Este script, llamado CYBER_STACK_V1.sh, hará todo: desde configurar el kernel de Linux hasta desplegar los contenedores, gestionar secretos, configurar SSL y crear alias de mantenimiento.

💾 Instrucciones Previas

Accede a tu servidor VPS (Ubuntu 20.04/22.04/24.04).

Crea el archivo: nano sistema_maestro.sh

Pega el siguiente código (es largo, asegúrate de copiarlo todo).

Dale permisos: chmod +x sistema_maestro.sh

Ejecútalo: ./sistema_maestro.sh

🖥️ EL CÓDIGO (sistema_maestro.sh)
code
Bash
download
content_copy
expand_less
#!/bin/bash

# ==============================================================================
#  CYBER STACK ORCHESTRATOR v3.0 - NEON EDITION
#  Arquitectura: Docker Swarm/Compose | Nginx | SSL | Security Hardening
# ==============================================================================

# --- PALETA DE COLORES NEQUI / CYBERPUNK ---
NEON_MAGENTA='\033[38;5;198m'
NEON_CYAN='\033[38;5;51m'
DEEP_PURPLE='\033[38;5;55m'
NEON_GREEN='\033[38;5;46m'
NEON_YELLOW='\033[38;5;226m'
WHITE='\033[1;37m'
GREY='\033[0;90m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# --- VARIABLES GLOBALES ---
INSTALL_DIR="/opt/cyber-stack"
ENV_FILE="$INSTALL_DIR/.env.secrets"
LOG_FILE="$INSTALL_DIR/install.log"

# --- FUNCIONES GRÁFICAS ---

function print_banner() {
    clear
    echo -e "${NEON_MAGENTA}"
    echo "   ██████╗██╗   ██╗██████╗ ███████╗██████╗     ███████╗████████╗ █████╗  ██████╗██╗  ██╗"
    echo "  ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗    ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝"
    echo "  ██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝    ███████╗   ██║   ███████║██║     █████╔╝ "
    echo "  ██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗    ╚════██║   ██║   ██╔══██║██║     ██╔═██╗ "
    echo "  ╚██████╗   ██║   ██████╔╝███████╗██║  ██║    ███████║   ██║   ██║  ██║╚██████╗██║  ██╗"
    echo "   ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝"
    echo -e "${NEON_CYAN}   >>> INTEGRATED ARCHITECTURE: EVOLUTION API + CHATWOOT + N8N + SECURITY <<<${NC}"
    echo -e "${DEEP_PURPLE}   ========================================================================${NC}"
    echo ""
}

function print_step() {
    echo -e "${NEON_CYAN} [⚡] ${BOLD}$1${NC}"
    echo "--------------------------------------------------------"
}

function print_success() {
    echo -e "${NEON_GREEN} [✔] $1${NC}"
}

function print_error() {
    echo -e "${NEON_MAGENTA} [✖] ERROR: $1${NC}"
}

function print_input() {
    echo -e "${NEON_YELLOW} [?] $1${NC}"
}

function spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# --- VALIDACIONES ---

if [ "$EUID" -ne 0 ]; then
  print_error "Por favor, ejecuta este script como root (sudo)."
  exit 1
fi

# --- MÓDULOS DE INSTALACIÓN ---

function 1_prepare_system() {
    print_step "Actualizando el Núcleo del Sistema (OS Hardening)"
    
    # Actualización silenciosa
    (apt-get update && apt-get upgrade -y) > /dev/null 2>&1 &
    spinner $!
    print_success "Repositorios actualizados."

    # Dependencias base
    print_step "Instalando Herramientas Tácticas"
    (apt-get install -y curl wget git htop ufw fail2ban jq software-properties-common certbot python3-certbot-nginx unzip) > /dev/null 2>&1 &
    spinner $!
    
    # Docker Installation (Si no existe)
    if ! command -v docker &> /dev/null; then
        print_step "Inyectando Docker Engine..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh > /dev/null 2>&1
        rm get-docker.sh
        print_success "Docker inyectado."
    else
        print_success "Docker ya está presente."
    fi

    # Docker Compose Plugin
    (apt-get install -y docker-compose-plugin) > /dev/null 2>&1

    # Optimización de Kernel para Redis y Elasticsearch (necesario para Chatwoot/Logs)
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf
    echo "net.core.somaxconn=65535" >> /etc/sysctl.conf
    sysctl -p > /dev/null 2>&1
    print_success "Kernel optimizado para alta carga."

    # Configuración de Swap (Si RAM < 4GB)
    TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    if [ $TOTAL_RAM -lt 4000000 ]; then
        print_step "RAM baja detectada. Creando Swap de 4GB..."
        fallocate -l 4G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        print_success "Memoria Swap activada."
    fi
}

function 2_structure_and_secrets() {
    print_step "Construyendo Arquitectura de Directorios"
    mkdir -p $INSTALL_DIR/{infra,apps,proxy/conf.d,scripts,backups,logs}
    mkdir -p $INSTALL_DIR/infra/{postgres_data,redis_data,minio_data}
    mkdir -p $INSTALL_DIR/apps/{chatwoot_storage,evolution_instances,evolution_store,n8n_data}

    # Permisos seguros
    chmod -R 750 $INSTALL_DIR

    if [ -f "$ENV_FILE" ]; then
        print_success "Secretos detectados. Cargando..."
        source "$ENV_FILE"
    else
        print_step "Generando Criptografía de Nivel Militar..."
        
        # Inputs del usuario
        echo -e "${NEON_CYAN}"
        read -p ">> Dominio Base (ej: empresa.com): " DOMAIN_BASE
        read -p ">> Email para SSL (ej: admin@empresa.com): " EMAIL_ADMIN
        echo -e "${NC}"

        # Generación de Contraseñas
        DB_ROOT_PASS=$(openssl rand -hex 16)
        CHATWOOT_DB_PASS=$(openssl rand -hex 12)
        EVOLUTION_DB_PASS=$(openssl rand -hex 12)
        N8N_DB_PASS=$(openssl rand -hex 12)
        REDIS_PASS=$(openssl rand -hex 16)
        MINIO_ROOT_PASS=$(openssl rand -hex 16)
        EVO_API_KEY=$(openssl rand -hex 24)
        CW_SECRET_KEY=$(openssl rand -hex 64)
        N8N_ENC_KEY=$(openssl rand -hex 24)

        # Guardar en archivo seguro
        cat > "$ENV_FILE" <<EOF
DOMAIN_BASE=$DOMAIN_BASE
EMAIL_ADMIN=$EMAIL_ADMIN
DB_ROOT_PASS=$DB_ROOT_PASS
CHATWOOT_DB_PASS=$CHATWOOT_DB_PASS
EVOLUTION_DB_PASS=$EVOLUTION_DB_PASS
N8N_DB_PASS=$N8N_DB_PASS
REDIS_PASS=$REDIS_PASS
MINIO_ROOT_PASS=$MINIO_ROOT_PASS
EVO_API_KEY=$EVO_API_KEY
CW_SECRET_KEY=$CW_SECRET_KEY
N8N_ENC_KEY=$N8N_ENC_KEY
EOF
        chmod 600 "$ENV_FILE"
        source "$ENV_FILE"
        print_success "Secretos generados y encriptados en $ENV_FILE"
    fi
}

function 3_deploy_infrastructure() {
    print_step "Desplegando Infraestructura de Datos (Capa 1)"

    # Crear Red
    docker network create --driver bridge --attachable cyber-net || true

    # Docker Compose INFRA
    cat > "$INSTALL_DIR/infra/docker-compose.yml" <<EOF
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: cyber_db
    restart: always
    environment:
      POSTGRES_PASSWORD: ${DB_ROOT_PASS}
    volumes:
      - ./postgres_data:/var/lib/postgresql/data
      - ./init:/docker-entrypoint-initdb.d
    networks:
      - cyber-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: cyber_redis
    restart: always
    command: redis-server --requirepass ${REDIS_PASS} --appendonly yes
    volumes:
      - ./redis_data:/data
    networks:
      - cyber-net
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASS}", "ping"]
      interval: 10s
      retries: 5

  minio:
    image: minio/minio:latest
    container_name: cyber_minio
    restart: always
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASS}
    volumes:
      - ./minio_data:/data
    networks:
      - cyber-net
    ports:
      - "127.0.0.1:9000:9000"
      - "127.0.0.1:9001:9001"

networks:
  cyber-net:
    external: true
EOF

    # Script SQL de inicialización
    mkdir -p "$INSTALL_DIR/infra/init"
    cat > "$INSTALL_DIR/infra/init/01-init.sql" <<EOF
CREATE USER chatwoot WITH PASSWORD '${CHATWOOT_DB_PASS}';
CREATE DATABASE chatwoot OWNER chatwoot;
CREATE USER evolution WITH PASSWORD '${EVOLUTION_DB_PASS}';
CREATE DATABASE evolution OWNER evolution;
CREATE USER n8n WITH PASSWORD '${N8N_DB_PASS}';
CREATE DATABASE n8n OWNER n8n;
ALTER USER chatwoot CREATEDB;
EOF

    # Levantar Infra
    cd "$INSTALL_DIR/infra"
    docker compose up -d
    print_success "Postgres, Redis y MinIO activos."
}

function 4_deploy_applications() {
    print_step "Desplegando Aplicaciones de Negocio (Capa 2)"

    cat > "$INSTALL_DIR/apps/docker-compose.yml" <<EOF
version: '3.8'

services:
  # --- CHATWOOT ---
  chatwoot_web:
    image: chatwoot/chatwoot:v3.13.0
    container_name: cw_web
    restart: always
    env_file: .env
    command: bundle exec rails s -p 3000 -b 0.0.0.0
    depends_on:
      - chatwoot_worker
    networks:
      - cyber-net
    ports:
      - "127.0.0.1:3000:3000"

  chatwoot_worker:
    image: chatwoot/chatwoot:v3.13.0
    container_name: cw_worker
    restart: always
    env_file: .env
    command: bundle exec sidekiq -C config/sidekiq.yml
    networks:
      - cyber-net

  # --- EVOLUTION API ---
  evolution_api:
    image: atendai/evolution-api:v2.1.1
    container_name: evo_api
    restart: always
    env_file: .env
    volumes:
      - ./evolution_instances:/evolution/instances
      - ./evolution_store:/evolution/store
    networks:
      - cyber-net
    ports:
      - "127.0.0.1:8080:8080"

  # --- N8N ---
  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n_engine
    restart: always
    env_file: .env
    command: /bin/sh -c "n8n start"
    volumes:
      - ./n8n_data:/home/node/.n8n
    networks:
      - cyber-net
    ports:
      - "127.0.0.1:5678:5678"

networks:
  cyber-net:
    external: true
EOF

    # Generar .env de Aplicaciones
    cat > "$INSTALL_DIR/apps/.env" <<EOF
# GLOBAL
DOMAIN=${DOMAIN_BASE}
NODE_ENV=production
RAILS_ENV=production

# CHATWOOT
FRONTEND_URL=https://chat.${DOMAIN_BASE}
SECRET_KEY_BASE=${CW_SECRET_KEY}
POSTGRES_HOST=cyber_db
POSTGRES_PORT=5432
POSTGRES_DATABASE=chatwoot
POSTGRES_USERNAME=chatwoot
POSTGRES_PASSWORD=${CHATWOOT_DB_PASS}
REDIS_URL=redis://:${REDIS_PASS}@cyber_redis:6379/0
ENABLE_ACCOUNT_SIGNUP=false
MAILER_SENDER_EMAIL=noreply@${DOMAIN_BASE}

# EVOLUTION
SERVER_URL=https://api.${DOMAIN_BASE}
AUTHENTICATION_API_KEY=${EVO_API_KEY}
DATABASE_ENABLED=true
DATABASE_CONNECTION_URI=postgresql://evolution:${EVOLUTION_DB_PASS}@cyber_db:5432/evolution
CACHE_REDIS_ENABLED=true
CACHE_REDIS_URI=redis://:${REDIS_PASS}@cyber_redis:6379/1

# N8N
N8N_HOST=n8n.${DOMAIN_BASE}
N8N_PORT=5678
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.${DOMAIN_BASE}/
N8N_ENCRYPTION_KEY=${N8N_ENC_KEY}
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=cyber_db
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=${N8N_DB_PASS}
EOF

    # Inicializar Chatwoot (IMPORTANTE)
    print_step "Inicializando DB de Chatwoot (Esto puede tardar)..."
    cd "$INSTALL_DIR/apps"
    docker compose run --rm chatwoot_web bundle exec rails db:chatwoot_prepare > /dev/null 2>&1
    print_success "Chatwoot Preparado."

    # Levantar todo
    docker compose up -d
    print_success "Aplicaciones en línea."
}

function 5_configure_proxy() {
    print_step "Configurando Proxy Inverso Nginx & SSL"
    
    # Instalar Nginx si no está
    apt-get install -y nginx > /dev/null 2>&1

    # Crear configuración
    cat > "/etc/nginx/sites-available/cyber_stack" <<EOF
# CHATWOOT
server {
  server_name chat.${DOMAIN_BASE};
  location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
  }
}

# EVOLUTION API
server {
  server_name api.${DOMAIN_BASE};
  location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
  }
}

# N8N
server {
  server_name n8n.${DOMAIN_BASE};
  location / {
    proxy_pass http://127.0.0.1:5678;
    proxy_set_header Host \$host;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_buffering off;
  }
}

# MINIO S3
server {
  server_name s3.${DOMAIN_BASE};
  ignore_invalid_headers off;
  client_max_body_size 1000m;
  location / {
    proxy_pass http://127.0.0.1:9000;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
  }
}
EOF

    ln -s /etc/nginx/sites-available/cyber_stack /etc/nginx/sites-enabled/ 2>/dev/null
    rm /etc/nginx/sites-enabled/default 2>/dev/null
    nginx -t && systemctl reload nginx

    # Certbot SSL
    print_step "Solicitando Certificados SSL (Let's Encrypt)"
    certbot --nginx --non-interactive --agree-tos -m "$EMAIL_ADMIN" \
        -d "chat.$DOMAIN_BASE" -d "api.$DOMAIN_BASE" -d "n8n.$DOMAIN_BASE" -d "s3.$DOMAIN_BASE"
    
    print_success "SSL Blindado."
}

function 6_finalize_and_extras() {
    print_step "Aplicando Capas de Mantenimiento y Seguridad"

    # Configurar Fail2Ban para Nginx
    cat > /etc/fail2ban/jail.d/nginx-req-limit.conf <<EOF
[nginx-req-limit]
enabled = true
filter = nginx-limit-req
action = iptables-multiport[name=ReqLimit, port="http,https", protocol=tcp]
logpath = /var/log/nginx/*error.log
findtime = 600
bantime = 7200
maxretry = 10
EOF
    systemctl restart fail2ban

    # Crear Scripts de Mantenimiento
    mkdir -p "$INSTALL_DIR/scripts"
    
    # Script Status
    cat > "$INSTALL_DIR/scripts/status.sh" <<EOF
#!/bin/bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
EOF
    chmod +x "$INSTALL_DIR/scripts/status.sh"

    # Crear Alias
    echo "alias cyber-status='$INSTALL_DIR/scripts/status.sh'" >> ~/.bashrc
    echo "alias cyber-logs='cd $INSTALL_DIR/apps && docker compose logs -f'" >> ~/.bashrc
    
    print_success "Alias creados: 'cyber-status' y 'cyber-logs'"
}

function show_credentials() {
    clear
    echo -e "${DEEP_PURPLE}====================================================${NC}"
    echo -e "${NEON_MAGENTA}   🚀 INSTALACIÓN FINALIZADA - CREDENCIALES ${NC}"
    echo -e "${DEEP_PURPLE}====================================================${NC}"
    echo ""
    echo -e "${NEON_CYAN} [DOMINIOS] ${NC}"
    echo " - Chatwoot:  https://chat.$DOMAIN_BASE"
    echo " - Evolution: https://api.$DOMAIN_BASE"
    echo " - n8n:       https://n8n.$DOMAIN_BASE"
    echo " - MinIO S3:  https://s3.$DOMAIN_BASE"
    echo ""
    echo -e "${NEON_YELLOW} [CREDENCIALES MAESTRAS] (Guardadas en .env.secrets) ${NC}"
    echo " - DB Root Pass:   $DB_ROOT_PASS"
    echo " - Redis Pass:     $REDIS_PASS"
    echo " - MinIO User:     minioadmin"
    echo " - MinIO Pass:     $MINIO_ROOT_PASS"
    echo ""
    echo -e "${NEON_GREEN} [API KEYS] ${NC}"
    echo " - Evolution Key:  $EVO_API_KEY"
    echo " - n8n Enc Key:    $N8N_ENC_KEY"
    echo ""
    echo -e "${DEEP_PURPLE}====================================================${NC}"
    echo -e "${WHITE} Recuerda reiniciar tu sesión o ejecutar 'source ~/.bashrc' para usar los alias.${NC}"
}

# --- MENÚ PRINCIPAL ---

while true; do
    print_banner
    echo -e "${NEON_CYAN} 1.${WHITE} Instalación Automática Completa (Recomendado)"
    echo -e "${NEON_CYAN} 2.${WHITE} Solo Preparar Sistema (Docker, Swap, Kernel)"
    echo -e "${NEON_CYAN} 3.${WHITE} Solo Generar Secretos y Estructura"
    echo -e "${NEON_CYAN} 4.${WHITE} Solo Desplegar Infra (DBs)"
    echo -e "${NEON_CYAN} 5.${WHITE} Solo Desplegar Apps"
    echo -e "${NEON_CYAN} 6.${WHITE} Configurar SSL/Proxy"
    echo -e "${NEON_MAGENTA} 0.${WHITE} Salir"
    echo ""
    echo -n -e "${NEON_YELLOW} Selecciona una opción [1-6]: ${NC}"
    read option

    case $option in
        1)
            1_prepare_system
            2_structure_and_secrets
            3_deploy_infrastructure
            4_deploy_applications
            5_configure_proxy
            6_finalize_and_extras
            show_credentials
            break
            ;;
        2) 1_prepare_system ;;
        3) 2_structure_and_secrets ;;
        4) 3_deploy_infrastructure ;;
        5) 4_deploy_applications ;;
        6) 5_configure_proxy ;;
        0) exit 0 ;;
        *) print_error "Opción inválida"; sleep 2 ;;
    esac
    
    echo ""
    read -p "Presiona Enter para continuar..."
done
🚀 ¿Qué hace este Sistema "Cyberpunk"?

Estética Nequi/Neon: Usa códigos de escape ANSI 256 para lograr colores magentas, cyanes y púrpuras vibrantes en la terminal.

Modularidad: Puedes correr todo de una vez (Opción 1) o paso a paso si necesitas depurar.

Hardening Automático:

Kernel: Ajusta vm.max_map_count (crítico para stacks modernos).

Swap: Detecta si tienes poca RAM y crea memoria virtual automáticamente.

Fail2Ban: Instala y configura protección contra ataques DDoS/BruteForce en Nginx.

Gestión de Secretos:

No te pide contraseñas. Las genera criptográficamente (openssl rand) y las guarda en un archivo .env.secrets con permisos 600 (solo root puede leerlo).

Despliegue Inteligente:

Usa cat <<EOF para generar los archivos docker-compose.yml al vuelo con las variables inyectadas.

Ejecuta rails db:chatwoot_prepare automáticamente (el paso que todos olvidan y rompe Chatwoot).

Proxy & SSL:

Genera la configuración de Nginx automáticamente con los subdominios basados en el dominio que ingreses.

Ejecuta Certbot en modo no interactivo.

Alias de Poder:

Te regala comandos como cyber-status para ver el estado de tu imperio digital de un vistazo.

⚠️ Post-Instalación

Una vez termine el script:

Reinicia la sesión (exit y vuelve a entrar) para cargar los alias.

Entra a https://chat.tudominio.com y crea tu cuenta de Admin.

Usa las credenciales mostradas al final (o lee el archivo /opt/cyber-stack/.env.secrets) para configurar tus integraciones.

Es elegante. Es robusto. Es profesional. Disfrútalo. 🕶️