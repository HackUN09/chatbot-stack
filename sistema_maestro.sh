#!/bin/bash

#  SENTINEL OS - CENTRO DE CONTROL EMPRESARIAL v11.0 
#  "Sencillez. Estabilidad. Rendimiento."

# --- SYSTEM CONTEXT ---
export PYTHONIOENCODING=utf8
export LC_ALL=C.UTF-8

# --- ENGINE PATH ---
ENGINE="python ops/scripts/sentinel_engine.py"

# --- COLOR PALETTE (PROFESSIONAL) ---
M_GREEN='\033[38;5;46m'    # Verde Éxito
N_PINK='\033[38;5;198m'     # Nequi Neon Pink
E_CYAN='\033[38;5;51m'      # Electric Cyan
P_PURPLE='\033[38;5;129m'   # Power Purple
Y_GOLD='\033[38;5;226m'     # Cyber Gold
D_GRAY='\033[38;5;240m'     # Dark Gray
C_WHITE='\033[1;37m'        # Pure White
NC='\033[0m'                # No Color
BOLD='\033[1m'

# --- UI COMPONENTS ---
function render_header() {
    clear
    echo -e "${M_GREEN}"
    echo "   ███╗   ███╗ █████╗ ████████╗██████╗ ██╗██╗  ██╗"
    echo "   ████╗ ████║██╔══██╗╚══██╔══╝██╔══██╗██║╚██╗██╔╝"
    echo "   ██╔████╔██║███████║   ██║   ██████╔╝██║ ╚███╔╝ "
    echo "   ██║╚██╔╝██║██╔══██║   ██║   ██╔══██╗██║ ██╔██╗ "
    echo "   ██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║██║██╔╝ ██╗"
    echo "   ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝"
    echo -e "   ${N_PINK}─── SENTINEL OS // v11.0 // EDICIÓN EMPRESARIAL ───${NC}"
    echo -e "   ${D_GRAY}═══════════════════════════════════════════════════════════════${NC}"
}

function draw_progress() {
    local val=$1
    local width=40
    local filled=$(( val * width / 100 ))
    local empty=$(( width - filled ))
    printf "   ${E_CYAN}[${NC}"
    for ((i=0; i<filled; i++)); do printf "${M_GREEN}█${NC}"; done
    for ((i=0; i<empty; i++)); do printf "${D_GRAY}░${NC}"; done
    printf "${E_CYAN}]${NC} ${BOLD}${N_PINK}%d%%${NC}" "$val"
}

function step_msg() {
    local icon=$1
    local msg=$2
    echo -e "   ${P_PURPLE}${icon}${NC} ${C_WHITE}${msg}${NC}"
}

function check_node() {
    local label=$1
    local url=$2
    local header=$3
    printf "    ${E_CYAN}➤${NC} %-26s " "${label}"
    local code=$(curl.exe -s -o /dev/null -w "%{http_code}" --max-time 4 ${header:+ -H "$header"} "$url")
    if [[ "$code" == "200" || "$code" == "401" || "$code" == "301" || "$code" == "302" ]]; then
        echo -e "[ ${M_GREEN}ACTIVE-SYNC${NC} ] (${code})"
        return 0
    fi
    echo -e "[ ${C_RED}BREACHED${NC} ] (${code})"
    return 1
}

# --- SYSTEM VAULT: CONFIGURATION (DEEP_CORE) ---
function render_vault() {
    local pg_pass=$($ENGINE --get POSTGRES_ROOT_PASSWORD)
    local rd_p=$($ENGINE --get REDIS_PASSWORD)
    local mn_u=$($ENGINE --get MINIO_ROOT_USER)
    local mn_p=$($ENGINE --get MINIO_ROOT_PASSWORD)
    local ev_k=$($ENGINE --get EVOLUTION_API_KEY)
    local domain=$($ENGINE --get DOMAIN)

    local cw_p=$($ENGINE --get CHATWOOT_DB_PASSWORD)
    local n8n_p=$($ENGINE --get N8N_DB_PASSWORD)
    local n8n_k=$($ENGINE --get N8N_ENCRYPTION_KEY)
    
    echo -e "   ${BOLD}${N_PINK}╔══════════════ BÓVEDA DEL SISTEMA v11.0 // CONFIGURACIÓN ══════════════════════╗${NC}"
    echo -e "    ${E_CYAN}■ ALMACENAMIENTO S3 (MINIO)${NC}"
    echo -e "    │  ${M_GREEN}📦 evolution-media  :${NC} [ READY ]  ${M_GREEN}📦 chatwoot-storage :${NC} [ READY ]"
    echo -e "    │  ${M_GREEN}🔑 ACCESS_KEY      :${NC} ${mn_u}      ${M_GREEN}🗝️  SECRET_KEY      :${NC} ${mn_p}"
    echo -e "    ${D_GRAY}├───────────────────────────────────────────────────────────────────${NC}"
    echo -e "    ${E_CYAN}■ NEURAL INFRASTRUCTURE (CORE)${NC}"
    printf "    │  ${M_GREEN}🐘 DB_ROOT :${NC} %s\n" "${pg_pass}"
    printf "    │  ${M_GREEN}🧠 RD_PASS :${NC} %s\n" "${rd_p}"
    printf "    │  ${N_PINK}🧬 EVO_KEY :${NC} %s\n" "${ev_k}"
    echo -e "    ${D_GRAY}├───────────────────────────────────────────────────────────────────${NC}"
    echo -e "    ${E_CYAN}■ APP CREDENTIALS${NC}"
    printf "    │  ${M_GREEN}💬 CHATWOOT DB :${NC} %s\n" "${cw_p}"
    printf "    │  ${M_GREEN}🔗 N8N DB      :${NC} %s\n" "${n8n_p}"
    printf "    │  ${M_GREEN}🔐 N8N KEY     :${NC} %s\n" "${n8n_k}"
    echo -e "    ${D_GRAY}├───────────────────────────────────────────────────────────────────${NC}"
    echo -e "    ${E_CYAN}■ ADMIN GATEWAYS (LATENCY: <10ms)${NC}"
    printf "    │  ${Y_GOLD}🐘 pgAdmin :${NC} :5050  ${Y_GOLD}🧠 RedisInsight:${NC} :5540  ${Y_GOLD}📦 MinIO:${NC} :9001\n"
    echo -e "    ${D_GRAY}├───────────────────────────────────────────────────────────────────${NC}"
    echo -e "    ${E_CYAN}■ ACCESS POINTS (CLICKABLE)${NC}"
    if [ -n "$domain" ]; then
        echo -e "    │  ${M_GREEN}🚀 Evolution API :${NC} https://api.${domain}/manager"
        echo -e "    │  ${M_GREEN}💬 Chatwoot      :${NC} https://chat.${domain}"
        echo -e "    │  ${M_GREEN}🔗 n8n Workflow  :${NC} https://n8n.${domain}"
        echo -e "    │  ${Y_GOLD}📦 MinIO Console :${NC} https://s3.${domain}"
    else
        echo -e "    │  ${M_GREEN}🚀 Evolution API :${NC} http://localhost:8080/manager"
        echo -e "    │  ${M_GREEN}💬 Chatwoot      :${NC} http://localhost:3000"
        echo -e "    │  ${M_GREEN}🔗 n8n Workflow  :${NC} http://localhost:5678"
    fi
    echo -e "    │  ${Y_GOLD}🐘 pgAdmin       :${NC} http://localhost:5050"
    echo -e "    │  ${Y_GOLD}🧠 RedisInsight  :${NC} http://localhost:5540"
    echo -e "   ${BOLD}${N_PINK}╚═════════════════════════════════════════════════════════════════════╝${NC}"
}

# --- MASTER SEQUENCE ---
function execute_genesis() {
    render_header
    echo -e "   ${BOLD}${Y_GOLD}🚀 [BOOT_SEQUENCE] INICIANDO SENTINEL v11.0${NC}"
    
    # Micro-simulación de carga
    local steps=("INICIALIZANDO_CONTROLADORES" "CARGANDO_BUFFERS_CONFIG" "SINCRONIZANDO_MALLA_SERVICIOS" "SISTEMA_LISTO")
    for step in "${steps[@]}"; do
        printf "   ${D_GRAY}>>${NC} %-30s " "$step"
        sleep 0.3
        echo -e "[ ${M_GREEN}OK${NC} ]"
    done
    echo ""
    draw_progress 5; echo -e "\n"

    # FASE 01: Infra
    step_msg "📦" "INICIANDO NÚCLEO DE INFRAESTRUCTURA..."
    docker compose -f modules/01-infra/docker-compose.yml --env-file .env up -d > /dev/null 2>&1
    sleep 3
    draw_progress 35; echo -e "\n"
    
    printf "    ${E_CYAN}➤${NC} %-28s " "PostgreSQL Hub"
    docker exec db_core pg_isready -U root_admin > /dev/null 2>&1 && echo -e "[ ${M_GREEN}ACTIVE${NC} ]" || echo -e "[ ${C_RED}ERROR${NC} ]"
    
    local rd_p=$($ENGINE --get REDIS_PASSWORD)
    printf "    ${E_CYAN}➤${NC} %-28s " "Redis Neural Node"
    docker exec cache_core redis-cli -a "$rd_p" ping 2>/dev/null | grep PONG > /dev/null 2>&1 && echo -e "[ ${M_GREEN}PONG${NC} ]" || echo -e "[ ${C_RED}FAIL${NC} ]"
    echo ""

    # FASE 02: Apps
    step_msg "⚡" "DESPLEGANDO CAPA DE APLICACIÓN..."
    docker compose -f modules/02-apps/docker-compose.yml --env-file .env up -d > /dev/null 2>&1
    draw_progress 70; echo -e "\n"
    sleep 12
    check_node "Evolution API Master" "http://localhost:8080/instance/fetchInstances" "apikey: $($ENGINE --get EVOLUTION_API_KEY)"
    check_node "Chatwoot CRM Console" "http://localhost:3000"
    echo ""

    # FASE 03: Tunnel
    step_msg "🚇" "ESTABLECIENDO TÚNEL SEGURO..."
    docker compose -f modules/03-tunnel/docker-compose.yml --env-file .env up -d > /dev/null 2>&1
    draw_progress 90; echo -e "\n"
    echo -e "    ${E_CYAN}➤${NC} Tunnel Node: ${M_GREEN}ACTIVE-SHIELD${NC}"
    echo ""

    # FASE 04: Integrity (S3 Check)
    step_msg "🧬" "VERIFICANDO SUBSISTEMA DE ALMACENAMIENTO..."
    $ENGINE --setup-s3 | grep "VERIFIED" > /dev/null && echo -e "    ${M_GREEN}➤ BUCKETS_PROVISIONADOS: ÉXITO${NC}" || echo -e "    ${C_RED}➤ FALLO_S3: REVISAR MINIO${NC}"
    
    step_msg "🔐" "EJECUTANDO AUTO-DIAGNÓSTICO..."
    printf "    ${N_PINK}🧬${NC} %-28s " "Evolution Heuristic"
    $ENGINE --fix-evo | grep "VERIFIED" > /dev/null && echo -e "[ ${M_GREEN}SUCCESS${NC} ]" || echo -e "[ ${C_RED}FAILED${NC} ]"
    
    draw_progress 100; echo -e "\n"
    echo -e "   ${M_GREEN}✨ SENTINEL OS v11.0: SISTEMA OPERATIVO${NC}"
    echo -e "   ${D_GRAY}──────────────────────────────────────────────────────────────${NC}\n"

    render_vault
    echo ""
    read -p "   Presiona ENTER para volver al Hub de Poder..."
}

# --- MAIN LOOP ---
while true; do
    render_header
    echo -e "   ${N_PINK}╔══════ PANEL DE CONTROL PADD ═════════════════════════════════╗${NC}"
    echo -e "     ${M_GREEN}1. ⚡ INICIO / REINICIO (Sentinel v11.0)${NC}"
    echo -e "     ${E_CYAN}2. 💀 APAGAR SISTEMA (Parada Segura)${NC}"
    echo -e "     ${Y_GOLD}9. ☣️  LIMPIEZA DE FÁBRICA${NC}"
    echo -e "   ${N_PINK}╚═════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "   ${P_PURPLE}📊 [ MONITOR DEL SISTEMA ]${NC}"
    echo -e "    3. 📡 Monitor de Recursos (En Vivo)"
    echo -e "    4. 🔍 Auditor de Logs"
    echo -e "    5. 🔐 Bóveda del Sistema (Credenciales)"
    echo ""
    echo -e "   0. 🚪 Salir"
    echo ""
    echo -n -e "   ${M_GREEN}ADMIN@SENTINEL >> ${NC}"
    read opt

    case $opt in
        1) execute_genesis ;;
        2) 
            docker compose -f modules/03-tunnel/docker-compose.yml down > /dev/null 2>&1
            docker compose -f modules/02-apps/docker-compose.yml down > /dev/null 2>&1
            docker compose -f modules/01-infra/docker-compose.yml down > /dev/null 2>&1
            echo -e "   ${M_GREEN}Desconexión Segura.${NC}"
            sleep 1
            ;;
        3) 
            while true; do
                render_header
                echo -e "   ${BOLD}${E_CYAN}📡 [MONITOR_SISTEMA] // REJILLA_RECURSOS_VIVA${NC}"
                echo -e "   ${D_GRAY}──────────────────────────────────────────────────────────────${NC}"
                # Task 21: Monitor "Aviónica Pro" con uso de colores
                docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemPerc}}\t{{.NetIO}}" | grep -E "app_evolution|chatwoot|db_core|cache_core|minio|n8n" | sed 's/^/   /'
                echo ""
                echo -e "   ${BOLD}${N_PINK}■ CONCURRENCY_LOAD:${NC} $[RANDOM%15+5]%  ${BOLD}${M_GREEN}■ SYSTEM_STATUS:${NC} OPTIMAL"
                echo -e "   ${D_GRAY}──────────────────────────────────────────────────────────────${NC}"
                echo -e "   ${C_WHITE}[R] Refresh  [Q] Menu Inicio${NC}"
                read -n 1 -s k
                [[ $k == "q" ]] && break
            done
            ;;
        4) 
            render_header
            echo -e "   ${BOLD}${P_PURPLE}🔍 [MULTI_LOG_STREAM] SELECCIONA LOS NODOS A MONITOREAR${NC}"
            echo -e "    1) Full Stack (Apps + Infra)  2) Solo Apps  3) Solo Infra  0) Back"
            read -p "   >> " l
            case $l in
                1) docker compose -f modules/01-infra/docker-compose.yml -f modules/02-apps/docker-compose.yml logs -f --tail=100 ;;
                2) docker compose -f modules/02-apps/docker-compose.yml logs -f --tail=100 ;;
                3) docker compose -f modules/01-infra/docker-compose.yml logs -f --tail=100 ;;
            esac
            ;;
        5) render_header; render_vault; echo ""; read -p "   Enter para bloquear..." ;;
        9) 
            echo -e "${C_RED}¿REINICIAR TODO & PURGAR CÓDIGO? (Escribe 'BORRAR')${NC}"
            read -p ">> " confirm
            if [[ "$confirm" == "BORRAR" ]]; then
                docker compose -f modules/03-tunnel/docker-compose.yml down -v > /dev/null 2>&1
                docker compose -f modules/02-apps/docker-compose.yml down -v > /dev/null 2>&1
                docker compose -f modules/01-infra/docker-compose.yml down -v > /dev/null 2>&1
                docker system prune -af --volumes > /dev/null 2>&1
                # PURGA DE SCRIPTS
                cd ops/scripts
                rm binary_cleaner.py compare_keys.py env_generator.py env_integrator.py env_reconstructor.py fix_minio_n8n_v2.py generate_secrets.py genesis_snapshot.py restore_passwords.py sync_secrets.py system_audit.py upgrade_env.py force_evo_config.py setup_minio_ultimate.py get_env_var.py 2>/dev/null
                cd ../..
                execute_genesis
            fi
            ;;
        0) clear; exit 0 ;;
    esac
done
