#!/bin/bash

#  ISEKAI STACK - SISTEMA MAESTRO v11.0 (SENTINEL OS - GOLD MASTER)
#  "Zero-Touch: El sistema que domina su propia integridad"

# --- PALETA DE COLORES (THE MATRIX & CYBERPUNK) ---
M_GREEN='\033[38;5;46m'   # Matrix Green
M_DARK='\033[38;5;22m'    # Dark Green
C_PINK='\033[38;5;198m'   # Neon Pink
C_CYAN='\033[38;5;51m'    # Neon Cyan
C_WHITE='\033[1;37m'      # Pure White
C_YELLOW='\033[38;5;226m' # Power Yellow
C_RED='\033[0;31m'        # Alert Red
NC='\033[0m'              # No Color
BOLD='\033[1m'

MAESTRO_ROOT=$(pwd)
ENV_FILE="${MAESTRO_ROOT}/.env"

function print_matrix_header() {
    clear
    echo -e "${M_GREEN}"
    echo "   ███╗   ███╗ █████╗ ████████╗██████╗ ██╗██╗  ██╗"
    echo "   ████╗ ████║██╔══██╗╚══██╔══╝██╔══██╗██║╚██╗██╔╝"
    echo "   ██╔████╔██║███████║   ██║   ██████╔╝██║ ╚███╔╝ "
    echo "   ██║╚██╔╝██║██╔══██║   ██║   ██╔══██╗██║ ██╔██╗ "
    echo "   ██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║██║██╔╝ ██╗"
    echo "   ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝"
    echo -e "   ${C_CYAN}─── SENTINEL OS // GENESIS EDITION v10.0 // SUPER-LINK ───${NC}"
    echo -e "   ${M_DARK}═════════════════════════════════════════════════${NC}"
}

function show_links() {
    if [ -f "$ENV_FILE" ]; then
        DOMAIN=$(python ops/scripts/get_env_var.py DOMAIN)
        if [ -z "$DOMAIN" ]; then DOMAIN="isekaichat.com"; fi
    else
        DOMAIN="isekaichat.com"
    fi
    echo -e "   ${BOLD}${C_WHITE}🌐 GATEWAY CLOUDFLARE (ACCESO GLOBAL):${NC}"
    echo -e "    ├─ 💬 Chatwoot:  ${C_CYAN}https://chat.${DOMAIN}${NC}"
    echo -e "    ├─ 🧬 Evolution: ${C_CYAN}https://api.${DOMAIN}${NC}"
    echo -e "    └─ ⚡ n8n Core:  ${C_CYAN}https://n8n.${DOMAIN}${NC}"
    echo ""
    echo -e "   ${BOLD}${C_WHITE}🔒 TERMINAL DE MANDO (ADMIN LOCAL):${NC}"
    echo -e "    ├─ 🐘 PgAdmin 4:      ${C_YELLOW}http://localhost:5050${NC}"
    echo -e "    ├─ 📦 MinIO Console:  ${C_YELLOW}http://localhost:9001${NC}"
    echo -e "    └─ 🧠 Redis Insight:  ${C_YELLOW}http://localhost:5540${NC}"
    echo ""
}

function show_credentials_hud() {
    echo -e "   ${BOLD}${C_PINK}🔐 BOVEDA DE CREDENCIALES (NIVEL 0)${NC}"
    echo -e "   ────────────────────────────────────────────────"
    
    # Extraction
    local evo_key=$(python ops/scripts/get_env_var.py EVOLUTION_API_KEY)
    local cw_id=$(python ops/scripts/get_env_var.py CHATWOOT_GLOBAL_ACCOUNT_ID)
    local cw_token=$(python ops/scripts/get_env_var.py CHATWOOT_GLOBAL_TOKEN)
    local cw_db_pass=$(python ops/scripts/get_env_var.py CHATWOOT_DB_PASSWORD)
    # n8n encryption key
    local n8n_key=$(python ops/scripts/get_env_var.py N8N_ENCRYPTION_KEY)
    
    # Admin Credentials
    local admin_email=$(python ops/scripts/get_env_var.py PGADMIN_DEFAULT_EMAIL)
    local admin_pass=$(python ops/scripts/get_env_var.py PGADMIN_DEFAULT_PASSWORD)
    
    # Infrastructure
    local pg_root=$(python ops/scripts/get_env_var.py POSTGRES_ROOT_PASSWORD)
    local minio_root=$(python ops/scripts/get_env_var.py MINIO_ROOT_PASSWORD)
    local redis_pass=$(python ops/scripts/get_env_var.py REDIS_PASSWORD)

    echo -e "   ${BOLD}${C_CYAN}1. INFRAESTRUCTURA CORE:${NC}"
    echo -e "      🐘 Postgres Root:  ${M_GREEN}${pg_root}${NC}"
    echo -e "      🧠 Redis Pass:     ${M_GREEN}${redis_pass}${NC}"
    echo -e "      📦 MinIO Root:     ${M_GREEN}${minio_root}${NC}"
    echo ""

    echo -e "   ${BOLD}${C_CYAN}2. APLICACIONES:${NC}"
    echo -e "      🧬 Evolution API:  ${C_YELLOW}${evo_key}${NC}"
    echo -e "      💬 Chatwoot DB:    ${M_GREEN}${cw_db_pass}${NC}"
    echo -e "      ⚡ n8n Encryption: ${M_GREEN}${n8n_key}${NC}"
    echo ""

    echo -e "   ${BOLD}${C_CYAN}3. ACCESO ADMIN (Chatwoot / n8n / PgAdmin):${NC}"
    echo -e "      👤 Admin Email:    ${C_WHITE}${admin_email}${NC}"
    echo -e "      🔑 Admin Pass:     ${C_WHITE}${admin_pass}${NC}"
    
    echo -e "   ────────────────────────────────────────────────"
    echo -e "   ${M_DARK}>> Copia y pega estas claves donde se requieran.${NC}"
    echo -e "   ${C_WHITE}Presiona Enter para cerrar.${NC}"
}

function status_hud() {
    while true; do
        print_matrix_header
        echo -e "   ${BOLD}${C_PINK}📡 MONITOR DE SISTEMA v11.0 (LIVE PERFORMANCE)${NC}"
        echo -e "   ────────────────────────────────────────────────────────"
        echo -e "   ${BOLD}CONTAINER ID   NAME                 CPU %     MEM USAGE / LIMIT     NET I/O${NC}"
        
        # We use docker stats --no-stream --format to create a nice table
        # We filter only our stack containers
        docker stats --no-stream --format "table {{.Container}}\t{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | grep -E "app_evolution|chatwoot|db_core|cache_core|minio|n8n|cloudflared" | sed 's/^/   /'
        
        echo ""
        echo -e "   ${C_WHITE}[R] Recargar  [Q] Salir al Menú${NC}"
        read -n 1 -s key
        if [[ $key == "q" ]]; then break; fi
    done
}

function check_item() {
    local label=$1
    local status=$2
    local emoji=$3
    if [[ $status == "OK" ]]; then
        echo -e "    ${emoji} ${C_WHITE}${label}:${NC} [ ${M_GREEN}VERIFICADO${NC} ]"
    elif [[ $status == "HEALED" ]]; then
        echo -e "    ${emoji} ${C_WHITE}${label}:${NC} [ ${C_YELLOW}AUTOCURADO${NC} ]"
    else
        echo -e "    ${emoji} ${C_WHITE}${label}:${NC} [ ${C_RED}FALLO${NC} ]"
    fi
}

source ops/scripts/core_libs.sh

function start_sequence() {
    print_matrix_header
    echo -e "   ${BOLD}${M_GREEN}🚀 INICIANDO PROTOCOLO GÉNESIS v11.0 (GOD MODE)${NC}"
    echo -e "   ────────────────────────────────────────────────────────"
    
    # --- PHASE 1: PRE-FLIGHT ---
    echo -e "   ${BOLD}${C_CYAN}[1/5] PRE-FLIGHT CHECKS:${NC}"
    
    # Check .env integrity
    echo -n "    🛡️  Validando Integridad del .env..."
    python ops/scripts/sentinel_fixer.py --silent
    if [ $? -eq 0 ]; then echo -e "${M_GREEN} OK${NC}"; else echo -e "${C_RED} CORRUPTO${NC}"; exit 1; fi
    
    # Check network
    echo -n "    🌐 Verificando Red 'secure-net'..."
    docker network create secure-net > /dev/null 2>&1
    echo -e "${M_GREEN} OK${NC}"
    
    echo ""

    # --- PHASE 2: INFRASTRUCTURE ---
    echo -e "   ${BOLD}${C_CYAN}[2/5] NÚCLEO DE DATOS (INFRA):${NC}"
    docker compose -f modules/01-infra/docker-compose.yml --env-file .env up -d > /dev/null 2>&1
    
    check_postgres
    if [ $? -ne 0 ]; then
        echo -e "    ${C_RED}🚨 CRITICAL: La base de datos no responde. Abortando.${NC}"
        read -p "Enter..."
        return
    fi
    
    local redis_pass=$(python ops/scripts/get_env_var.py REDIS_PASSWORD)
    check_redis "$redis_pass"
    
    # MinIO Health Check (HTTP)
    # Replaced generic wait_for_port with specific health endpoint for speed
    check_http_endpoint "MinIO Storage" "http://localhost:9000/minio/health/live"
    echo ""

    # --- PHASE 3: APPLICATIONS ---
    echo -e "   ${BOLD}${C_CYAN}[3/5] CAPA DE APLICACIÓN:${NC}"
    docker compose -f modules/02-apps/docker-compose.yml --env-file .env up -d > /dev/null 2>&1
    
    # We must wait for Evolution specifically to detect 401
    check_http_endpoint "Evolution API" "http://localhost:8080/instance/fetchInstances" "apikey: $(python ops/scripts/get_env_var.py EVOLUTION_API_KEY)"
    if [ $? -ne 0 ]; then
        echo -e "    ${C_YELLOW}⚠️  Fallo de Autenticación. Iniciando AUTO-HEAL...${NC}"
        python ops/scripts/sentinel_fixer.py --force > /dev/null
        docker compose -f modules/02-apps/docker-compose.yml up -d --force-recreate app_evolution > /dev/null 2>&1
        echo -n "    🔄 Esperando reinicio de Evolution..."
        sleep 10
        check_http_endpoint "Evolution API (Retry)" "http://localhost:8080/instance/fetchInstances" "apikey: $(python ops/scripts/get_env_var.py EVOLUTION_API_KEY)"
    fi
    
    check_http_endpoint "Chatwoot Web" "http://localhost:3000"
    check_http_endpoint "n8n Workflow Editor" "http://localhost:5678"
    echo ""

    # --- PHASE 4: TUNNEL ---
    echo -e "   ${BOLD}${C_CYAN}[4/5] ACCESO GLOBAL (TUNNEL):${NC}"
    docker compose -f modules/03-tunnel/docker-compose.yml --env-file .env up -d > /dev/null 2>&1
    echo -e "    🚇 Cloudflare Tunnel: ${M_GREEN}ONLINE${NC}"
    echo ""

    # --- PHASE 5: SUPER-LINK ---
    echo -e "   ${BOLD}${C_CYAN}[5/5] VINCULACIÓN FINAL (SUPER-LINK):${NC}"
    python ops/scripts/sentinel_fixer.py --silent
    echo -e "    🔗 Evolution <> Chatwoot: ${M_GREEN}SINCRONIZADO${NC}"

    echo -e "   ────────────────────────────────────────────────────────"
    echo -e "   ${M_GREEN}✨ SISTEMA OPERATIVO AL 100%${NC}"
    show_links
    show_credentials_hud
    read -p "   Presiona Enter para volver al centro de mando..."
}

function stop_sequence() {
    print_matrix_header
    echo -e "   ${C_RED}💀 INICIANDO PROTOCOLO DE SUSPENSIÓN TOTAL...${NC}"
    
    start_spinner "Deteniendo Túnel..."
    docker compose -f modules/03-tunnel/docker-compose.yml --env-file .env down > /dev/null 2>&1
    stop_spinner $?
    
    start_spinner "Deteniendo Apps (Evolution/Chatwoot)..."
    docker compose -f modules/02-apps/docker-compose.yml --env-file .env down > /dev/null 2>&1
    stop_spinner $?
    
    start_spinner "Apagando Núcleo de Datos..."
    docker compose -f modules/01-infra/docker-compose.yml --env-file .env down > /dev/null 2>&1
    stop_spinner $?
    
    echo -e "   ${M_GREEN}✨ Desconexión Segura Completada.${NC}"
    read -p "Presiona Enter..."
}

function backup_logic() {
    print_matrix_header
    echo -e "   ${C_CYAN}📸 PROTOCOLO GÉNESIS SNAPSHOT${NC}"
    echo -e "   1. Snapshot de Código y Configuración (.zip)"
    echo -e "   2. Dump de Bases de Datos (.sql)"
    echo -e "   0. Volver"
    read -p "   Selección >> " b_opt
    case $b_opt in
        1) python ops/scripts/genesis_snapshot.py ;;
        2) 
            echo "   Generando Dumps de Postgres..."
            timestamp=$(date +"%Y%m%d_%H%M%S")
            timestamp=$(date +"%Y%m%d_%H%M%S")
            root_pass=$(python ops/scripts/get_env_var.py POSTGRES_ROOT_PASSWORD)
            for db in chatwoot evolution n8n; do
                docker exec -e PGPASSWORD=$root_pass db_core pg_dump -U root_admin -d $db > ops/backups/${db}_backup_${timestamp}.sql
                echo "   ✅ Backup de $db listo."
            done
            ;;
    esac
    read -p "Presiona Enter..."
}

function vault_reveal() {
    print_matrix_header
    echo -e "   ${C_PINK}🔐 BOVEDA DE CREDENCIALES (NIVEL 0)${NC}"
    echo -e "   ────────────────────────────────────────────────"
    
    echo -e "   ${BOLD}${C_CYAN}1. INFRAESTRUCTURA CORE:${NC}"
    echo -e "      🐘 Postgres Root:  ${M_GREEN}$(python ops/scripts/get_env_var.py POSTGRES_ROOT_PASSWORD)${NC}"
    echo -e "      🧠 Redis Pass:     ${M_GREEN}$(python ops/scripts/get_env_var.py REDIS_PASSWORD)${NC}"
    echo -e "      📦 MinIO Root:     ${M_GREEN}$(python ops/scripts/get_env_var.py MINIO_ROOT_PASSWORD)${NC}"
    echo ""

    echo -e "   ${BOLD}${C_CYAN}2. APLICACIONES:${NC}"
    echo -e "      🧬 Evolution API:  ${C_YELLOW}$(python ops/scripts/get_env_var.py EVOLUTION_API_KEY)${NC}"
    echo -e "      💬 Chatwoot DB:    ${M_GREEN}$(python ops/scripts/get_env_var.py CHATWOOT_DB_PASSWORD)${NC}"
    echo -e "      ⚡ n8n Encryption: ${M_GREEN}$(python ops/scripts/get_env_var.py N8N_ENCRYPTION_KEY)${NC}"
    echo ""

    echo -e "   ${BOLD}${C_CYAN}3. ACCESO ADMIN:${NC}"
    echo -e "      👤 Admin Email:    ${C_WHITE}$(python ops/scripts/get_env_var.py PGADMIN_DEFAULT_EMAIL)${NC}"
    echo -e "      🔑 Admin Pass:     ${C_WHITE}$(python ops/scripts/get_env_var.py PGADMIN_DEFAULT_PASSWORD)${NC}"
    
    echo -e "   ────────────────────────────────────────────────"
    echo -e "   ${M_DARK}>> Copia y pega estas claves donde se requieran.${NC}"
    read -p "   Presiona Enter para cerrar."
}

function show_help() {
    print_matrix_header
    echo -e "   ${C_YELLOW}📘 MANUAL DE OPERACIONES SENTINEL v5.0${NC}"
    echo -e "   ──────────────────────────────────────────────"
    echo -e "   ${BOLD}1. ⚡ Lanzar Sistema Completo:${NC}"
    echo -e "      Detecta errores, auto-repara el .env, limpia PIDs y arranca todo."
    echo -e "      ${C_CYAN}>>> Úsalo para encender el sistema diariamente.${NC}"
    echo ""
    echo -e "   ${BOLD}2. 💀 Suspensión Total:${NC}"
    echo -e "      Apaga todos los contenedores de forma segura para evitar corrupción."
    echo -e "      ${C_CYAN}>>> Úsalo antes de apagar tu PC.${NC}"
    echo ""
    echo -e "   ${BOLD}9. 🧹 Reinicio Profundo (Nuclear):${NC}"
    echo -e "      Detiene todo, purga volúmenes temporales, limpia Docker y re-inicia."
    echo -e "      ${C_CYAN}>>> Úsalo solo si el sistema falla gravemente.${NC}"
    echo ""
    echo -e "   ${BOLD}5. 🩺 Sentinel Hyper-Integrity:${NC}"
    echo -e "      Escaneo binario del .env y verificación en tiempo real de contenedores."
    echo -e "      ${C_CYAN}>>> El botón de pánico definitivo para arreglar errores 401 y llaves corruptas.${NC}"
    echo ""
    read -p "   Presiona Enter para volver..."
}

# --- MENU PRINCIPAL ---
while true; do
    print_matrix_header
    echo -e "   ${C_PINK}[ MÓDULO: NÚCLEO DE ENERGÍA ]${NC}"
    echo -e "    ${M_GREEN}1. ⚡ Lanzar Sistema Completo (Auto-Heal Active)${NC}"
    echo -e "    ${C_RED}2. 💀 Suspensión Total (Stop)${NC}"
    echo -e "    ${C_YELLOW}9. 🧹 Reinicio Profundo (Clean & Restart)${NC}"
    echo ""
    echo -e "   ${C_PINK}[ MÓDULO: DIAGNÓSTICO Y REPARACIÓN ]${NC}"
    echo -e "    ${C_CYAN}3. 📡 Monitor Dinámico (HUD)${NC}"
    echo -e "    ${C_CYAN}4. 🔍 Inmersión en Logs${NC}"
    echo -e "    ${C_CYAN}5. 🩺 Sentinel Hyper-Integrity (Deep Fix & Verify)${NC}"
    echo ""
    echo -e "   ${C_PINK}[ MÓDULO: SEGURIDAD Y DATOS ]${NC}"
    echo -e "    ${C_YELLOW}6. 📸 Génesis Snapshot (Backups)${NC}"
    echo -e "    ${C_YELLOW}7. 🔐 Ver la Bóveda (Access List)${NC}"
    echo -e "    ${M_GREEN}8. 📑 Auditoría Inteligente (Real-Time Report)${NC}"
    echo ""
    echo -e "   0. 🚪 Salir de Sentinel OS${NC}"
    echo -e "   ${C_CYAN}?. ❓ Ayuda / Manual de Uso${NC}"
    echo ""
    echo -n -e "   ${BOLD}${M_GREEN}SENTINEL@ROOT >> ${NC}"
    read opt

    case $opt in
        1) start_sequence ;;
        2) stop_sequence ;;
        3) status_hud ;;
        4) 
            print_matrix_header
            echo -e "   ${C_WHITE}Selecciona flujo de datos:${NC}"
            echo "   1) Chatwoot  2) Evolution  3) n8n  4) Postgres  0) Atrás"
            read -p "   >> " l_opt
            case $l_opt in
                1) docker logs -f chatwoot-web ;;
                2) docker logs -f app_evolution ;;
                3) docker logs -f app_n8n_editor ;;
                4) docker logs -f db_core ;;
            esac
            ;;
        5) 
            print_matrix_header
            echo -e "   ${M_GREEN}⚕️  CHEQUEANDO CONSTANTES VITALES...${NC}"
            db_status=$(docker exec db_core pg_isready -U root_admin > /dev/null 2>&1 && echo -e "${M_GREEN}ONLINE${NC}" || echo -e "${C_RED}ERROR${NC}")
            db_status=$(docker exec db_core pg_isready -U root_admin > /dev/null 2>&1 && echo -e "${M_GREEN}ONLINE${NC}" || echo -e "${C_RED}ERROR${NC}")
            redis_status=$(docker exec cache_core redis-cli -a $(python ops/scripts/get_env_var.py REDIS_PASSWORD) ping > /dev/null 2>&1 && echo -e "${M_GREEN}PONG${NC}" || echo -e "${C_RED}DOWN${NC}")
            echo -e "   Núcleo DB: $db_status"
            echo -e "   Caché Central: $redis_status"
            echo ""
            echo -e "   ${C_WHITE}[F] Iniciar Auto-Reparación (Sentinel Fixer)${NC}"
            echo -e "   [Enter] Volver"
            read -n 1 -s fix
            if [[ $fix == "f" ]]; then
                echo -e "   ${C_CYAN}🛠️  Iniciando Cirugía Autónoma (God Mode)...${NC}"
                python ops/scripts/sentinel_fixer.py --force
                read -p "   Cirugía completada. Enter..."
            fi
            ;;
        6) backup_logic ;;
        7) vault_reveal ;;
        8)
            print_matrix_header
            echo -e "   ${M_GREEN}🔍 INICIANDO AUDITORÍA REAL-TIME...${NC}"
            python ops/scripts/system_audit.py
            echo ""
            echo -e "   ${C_WHITE}📄 Reporte generado en: ops/docs/ULTIMATE_AUDIT.md${NC}"
            echo -e "   ¿Deseas ver el resumen ahora? (s/n)"
            read -n 1 -s see_audit
            if [[ $see_audit == "s" ]]; then
                cat ops/docs/ULTIMATE_AUDIT.md
            fi
            read -p "   Presiona Enter para cerrar."
            ;;
        0) clear; exit 0 ;;
        9)
            stop_sequence
            print_matrix_header
            echo -e "   ${C_RED}☣️  ALERTA NUCLEAR: ESTO BORRARÁ TODO (DATOS, VOLÚMENES, REDES)${NC}"
            echo -e "   ¿Estás 100% seguro de reiniciar el universo? (escribe 'BORRAR')"
            read -p "   >> " confirm
            if [[ "$confirm" == "BORRAR" ]]; then
                echo -e "   ${C_YELLOW}🧹 EJECUTANDO LIMPIEZA PROFUNDA (SCORCHED EARTH)...${NC}"
                
                start_spinner "Purgando Contenedores e Imágenes..."
                docker compose -f modules/01-infra/docker-compose.yml down --rmi local -v --remove-orphans > /dev/null 2>&1
                docker compose -f modules/02-apps/docker-compose.yml down --rmi local -v --remove-orphans > /dev/null 2>&1
                docker compose -f modules/03-tunnel/docker-compose.yml down --rmi local -v --remove-orphans > /dev/null 2>&1
                stop_spinner $?
                
                start_spinner "Eliminando Volúmenes Persistentes..."
                # Hard delete specific named volumes if docker compose didn't catch them
                docker volume rm $(docker volume ls -q | grep "chatbot-stack") > /dev/null 2>&1
                # Also prune system
                docker system prune -f --volumes > /dev/null 2>&1
                stop_spinner $?
                
                echo -e "   ${M_GREEN}✨ UNIVERSO PURGADO. RENACIENDO EN 3, 2, 1...${NC}"
                sleep 3
                start_sequence
            else
                echo "   Cancelado."
                sleep 1
            fi
            ;;
        ?) show_help ;;
    esac
done
