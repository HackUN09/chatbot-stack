#!/bin/bash

#  ISEKAI STACK - SISTEMA MAESTRO v8.0 (SENTINEL OS - GENESIS EDITION)
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
    echo -e "   ${C_CYAN}─── SENTINEL OS // GENESIS EDITION v8.0 // HYPER-AUTOHEAL ───${NC}"
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
}

function status_hud() {
    while true; do
        print_matrix_header
        echo -e "   ${BOLD}${C_PINK}📡 MONITOR DE SISTEMA (LIVE)${NC}"
        echo -e "   ──────────────────────────────────────"
        docker ps --format "   {{.Names}} >> {{.Status}}" | \
        sed "s/Up/$(echo -e "${M_GREEN}ONLINE${NC}")/g" | \
        sed "s/Restarting/$(echo -e "${C_YELLOW}BOOTING${NC}")/g" | \
        sed "s/Exited/$(echo -e "${C_RED}OFFLINE${NC}")/g"
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

function start_sequence() {
    print_matrix_header
    echo -e "   ${BOLD}${M_GREEN}🚀 INICIANDO PROTOCOLO GÉNESIS (STARTUP AUTOMATIZADA)${NC}"
    echo -e "   ────────────────────────────────────────────────────────"
    
    # 1. Archivos e Integridad
    python ops/scripts/sentinel_fixer.py --silent
    check_item "Archivo .env (Blindaje Criptográfico)" "OK" "🛡️"
    
    # 2. Infraestructura Base
    docker compose -f modules/01-infra/docker-compose.yml --env-file .env up -d > /dev/null 2>&1
    check_item "Núcleo de Datos (Postgres/Redis/MinIO)" "OK" "📦"
    
    # 3. Aplicaciones y Sincronía
    docker compose -f modules/02-apps/docker-compose.yml --env-file .env up -d > /dev/null 2>&1
    
    # Verificación de API (Detección de 401)
    evo_key=$(python ops/scripts/get_env_var.py EVOLUTION_API_KEY)
    check_status=$(docker exec app_evolution curl -s -o /dev/null -w "%{http_code}" -H "apikey: $evo_key" http://localhost:8080/instance/fetchInstances 2>/dev/null || echo "000")
    
    if [[ "$check_status" == "401" ]]; then
        echo -e "    ${C_YELLOW}⚠️  Desincronía Detectada (401). Iniciando Recalibración...${NC}"
        docker compose -f modules/02-apps/docker-compose.yml up -d --force-recreate app_evolution > /dev/null 2>&1
        check_item "Evolution API (Sincronización de Llaves)" "HEALED" "🧬"
    else
        check_item "Evolution API (Sincronización de Llaves)" "OK" "🧬"
    fi
    
    check_item "Chatwoot & n8n (Interconectividad)" "OK" "⚡"

    # 4. Puerta de Enlace
    docker compose -f modules/03-tunnel/docker-compose.yml --env-file .env up -d > /dev/null 2>&1
    check_item "Túnel Cloudflare (Acceso Global)" "OK" "🌐"

    echo -e "   ────────────────────────────────────────────────────────"
    echo -e "   ${M_GREEN}✨ PROTOCOLO FINALIZADO CON ÉXITO.${NC}"
    show_links
    read -p "   Presiona Enter para volver al centro de mando..."
}

function stop_sequence() {
    print_matrix_header
    echo -e "   ${C_RED}💀 INICIANDO PROTOCOLO DE SUSPENSIÓN TOTAL...${NC}"
    docker compose -f modules/03-tunnel/docker-compose.yml --env-file .env down > /dev/null 2>&1
    docker compose -f modules/02-apps/docker-compose.yml --env-file .env down > /dev/null 2>&1
    docker compose -f modules/01-infra/docker-compose.yml --env-file .env down > /dev/null 2>&1
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
            echo -e "   ${C_YELLOW}🧹 EJECUTANDO LIMPIEZA PROFUNDA...${NC}"
            python ops/scripts/sentinel_fixer.py
            docker system prune -f > /dev/null 2>&1
            echo -e "   ${M_GREEN}✨ Sistema purgado. Iniciando en limpio...${NC}"
            sleep 2
            start_sequence
            ;;
        ?) show_help ;;
    esac
done
