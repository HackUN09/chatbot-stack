#!/bin/bash

# ==============================================================================
# 🛡️ SENTINEL OS - MASTER ORCHESTRATOR v11.1 (MODULAR NEXUS)
# ==============================================================================
# "Zero Dashboard. Infinite Resilience. Total Control."
# ==============================================================================

# --- SYSTEM CONTEXT ---
export LC_ALL=C.UTF-8

# Force Anaconda Python path directly to avoid bash cross-platform if-file checks
USER_PYTHON="C:/Users/wamr1/anaconda3/python.exe"
if command -v python >/dev/null 2>&1; then
    PY_CMD="python"
else
    PY_CMD="$USER_PYTHON"
fi

ENGINE="$PY_CMD ops/scripts/sentinel_engine.py"
STRESS="$PY_CMD ops/scripts/stress_test_enigma.py"

# --- ENV NEXUS RECONCILIATION ---
if [ ! -f .env ]; then
    echo -e "${R}[!] ERROR: .env no encontrado.${NC}"
    echo -e "${Y}[!] Por favor, crea un archivo .env basado en .env.example con tus credenciales reales.${NC}"
    exit 1
fi

# Cargar variables para que Docker Compose no de advertencias
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# --- COLOR PALETTE (PROFESSIONAL HIGHLIGHTS) ---
G='\033[38;5;46m'    # Success Green
R='\033[38;5;196m'   # Alert Red
B='\033[38;5;51m'    # Electric Cyan
P='\033[38;5;129m'   # Power Purple
Y='\033[38;5;226m'   # Warning Gold
D='\033[38;5;240m'   # Muted Gray
W='\033[1;37m'       # Pure White
NC='\033[0m'         # Reset

# --- UI COMPONENTS ---
function render_header() {
    clear
    echo -e "${P}"
    echo "    ███████╗███████╗███╗   ██╗████████╗██╗███╗   ██╗███████╗██╗     "
    echo "    ██╔════╝██╔════╝████╗  ██║╚══██╔══╝██║████╗  ██║██╔════╝██║     "
    echo "    ███████╗█████╗  ██╔██╗ ██║   ██║   ██║██╔██╗ ██║█████╗  ██║     "
    echo "    ╚════██║██╔══╝  ██║╚██╗██║   ██║   ██║██║╚██╗██║██╔══╝  ██║     "
    echo "    ███████║███████╗██║ ╚████║   ██║   ██║██║ ╚████║███████╗███████╗"
    echo "    ╚══════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝"
    echo -e "    ${B}─── SENTINEL OS // MODULAR NEXUS // ORQUESTADOR v11.0 ───${NC}"
    echo -e "    ${D}════════════════════════════════════════════════════════════════${NC}"
}

function tag() { echo -e "  ${P}[$1]${NC} ${W}$2${NC}"; }

function draw_progress() {
    local val=$1
    local width=40
    local filled=$(( val * width / 100 ))
    local empty=$(( width - filled ))
    printf "    ${B}[${NC}"
    for ((i=0; i<filled; i++)); do printf "${G}█${NC}"; done
    for ((i=0; i<empty; i++)); do printf "${D}░${NC}"; done
    printf "${B}]${NC} ${G}%d%%${NC}\n" "$val"
}

# --- CORE LOGIC ---
function check_node() {
    local name=$1
    local url=$2
    printf "    ${D}➤${NC} %-25s " "$name"
    local status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$url")
    if [[ "$status" =~ ^(200|301|302|401)$ ]]; then
        echo -e "[ ${G}ONLINE${NC} ] (${status})"
    else
        echo -e "[ ${R}OFFLINE${NC} ] (${status})"
    fi
}

function render_access_dashboard() {
    local domain=$(grep "DOMAIN=" .env | cut -d'=' -f2)
    echo -e "\n  ${P}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${P}│${NC}  ${W}🛡️  OMEGA VAULT - DEPLOYMENT COMPLETE                       ${P}│${NC}"
    echo -e "  ${P}└──────────────────────────────────────────────────────────────┘${NC}"
    echo -e "  ${B}  ➤ FRONTEND ACCESS CENTERS:${NC}"
    echo -e "    ${D}•${NC} ${G}Chatwoot CRM:${NC}    ${W}https://chat.${domain}${NC}"
    echo -e "    ${D}•${NC} ${G}Evolution API:${NC}   ${W}https://api.${domain}${NC}"
    echo -e "    ${D}•${NC} ${G}n8n Workflows:${NC}   ${W}https://n8n.${domain}${NC}"
    echo -e "    ${D}•${NC} ${G}MinIO Storage:${NC}   ${W}http://localhost:9001${NC}"
    echo -e "    ${D}•${NC} ${G}pgAdmin Panel:${NC}   ${W}http://localhost:5050${NC}"
    echo -e "    ${D}•${NC} ${G}Redis Insight:${NC}   ${W}http://localhost:5540${NC}"
    echo -e "\n  ${B}  ➤ CREDENCIALES POR SERVICIO (OMEGA VAULT):${NC}"
    echo -e "\n    ${P}━━━ CHATWOOT CRM ━━━${NC}"
    echo -e "    ${D}•${NC} ${Y}Usuario:${NC}      ${W}$($ENGINE --get CHATWOOT_ADMIN_EMAIL)${NC}"
    echo -e "    ${D}•${NC} ${Y}Contraseña:${NC}   ${W}$($ENGINE --get CHATWOOT_ADMIN_PASSWORD)${NC}"
    echo -e "    ${D}•${NC} ${Y}Token API:${NC}    ${W}$($ENGINE --get CHATWOOT_GLOBAL_TOKEN)${NC}"
    echo -e "\n    ${P}━━━ EVOLUTION API ━━━${NC}"
    echo -e "    ${D}•${NC} ${Y}API Key:${NC}      ${W}$($ENGINE --get EVOLUTION_API_KEY)${NC}"
    echo -e "    ${D}•${NC} ${D}(Autenticación vía Header 'apikey')${NC}"
    echo -e "\n    ${P}━━━ N8N WORKFLOWS ━━━${NC}"
    echo -e "    ${D}•${NC} ${Y}Usuario:${NC}      ${W}$($ENGINE --get CHATWOOT_ADMIN_EMAIL)${NC}"
    echo -e "    ${D}•${NC} ${Y}Contraseña:${NC}   ${W}$($ENGINE --get CHATWOOT_ADMIN_PASSWORD)${NC}"
    echo -e "\n    ${P}━━━ MINIO S3 STORAGE ━━━${NC}"
    echo -e "    ${D}•${NC} ${Y}Usuario:${NC}      ${W}minioadmin${NC}"
    echo -e "    ${D}•${NC} ${Y}Contraseña:${NC}   ${W}$($ENGINE --get MINIO_ROOT_PASSWORD)${NC}"
    echo -e "    ${D}•${NC} ${D}(Acceso Web Console: http://localhost:9001)${NC}"
    echo -e "\n    ${P}━━━ PGADMIN PANEL ━━━${NC}"
    echo -e "    ${D}•${NC} ${Y}Usuario:${NC}      ${W}$($ENGINE --get PGADMIN_DEFAULT_EMAIL)${NC}"
    echo -e "    ${D}•${NC} ${Y}Contraseña:${NC}   ${W}$($ENGINE --get PGADMIN_DEFAULT_PASSWORD)${NC}"
    echo -e "\n    ${P}━━━ CREDENCIALES DE INFRAESTRUCTURA ━━━${NC}"
    echo -e "    ${D}•${NC} ${B}PostgreSQL Root:${NC}  ${W}$($ENGINE --get POSTGRES_ROOT_PASSWORD)${NC}"
    echo -e "    ${D}•${NC} ${B}Redis Password:${NC}   ${W}$($ENGINE --get REDIS_PASSWORD)${NC}"
    echo -e "  ${P}────────────────────────────────────────────────────────────────${NC}"
}

function execute_genesis() {
    render_header
    tag "GENESIS" "Iniciando Despliegue Modular Seguro (Multimedia + Auto-Config)..."
    
    # 0. Red de Seguridad (Global para módulos)
    docker network create secure-net 2>/dev/null || true
    tag "NET" "Red secure-net garantizada."

    # 1. Capa de Infraestructura (01-infra)
    tag "INFRA" "Levantando Base de Datos, Cache y Almacenamiento S3..."
    docker compose -p 01-infra --env-file .env -f modules/01-infra/docker-compose.yml up -d
    draw_progress 15

    # 2. DB User Integrity Fix (corre en paralelo mientras infra arranca)
    tag "DB" "Garantizando integridad de usuarios de Base de Datos..."
    $ENGINE --fix-db
    draw_progress 30
    
    # 3. Capa de Aplicaciones (02-apps)
    tag "APPS" "Levantando Chatwoot, Evolution API, n8n..."
    docker compose -p 02-apps --env-file .env -f modules/02-apps/docker-compose.yml up -d
    draw_progress 50
    
    # 4. Capa de Túnel (03-tunnel)
    tag "TUNNEL" "Abriendo puente seguro con Cloudflare Zero Trust..."
    docker compose -p 03-tunnel --env-file .env -f modules/03-tunnel/docker-compose.yml up -d
    draw_progress 60

    # 5. Esperar a que TODOS los servicios respondan (Health Gate)
    tag "WAIT" "⏳ Esperando que todos los servicios estén operativos (Health Gate)..."
    $ENGINE --wait
    draw_progress 75

    # 6. Configurar S3: Crear Buckets + Aplicar Políticas Públicas (Multimedia Ready)
    tag "S3" "🪣 Garantizando buckets MinIO con acceso público (imágenes, videos, PDFs)..."
    $ENGINE --setup-s3
    draw_progress 85

    # 7. Configurar Chatwoot Admin + Auto-injectar Token en .env (Idempotente)
    tag "CW" "💬 Inicializando Chatwoot Admin e inyectando token en .env..."
    $ENGINE --setup-cw
    draw_progress 92

    # 8. Sincronizar Evolution API con Chatwoot (Webhook + Inbox)
    tag "EVO" "🤖 Sincronizando Evolution API → Chatwoot (Bridge)..."
    $ENGINE --fix-evo
    draw_progress 100
    
    echo -e "\n  ${G}✅ SISTEMA COMPLETAMENTE DESPLEGADO Y SINCRONIZADO.${NC}"
    echo -e "  ${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${Y}• Multimedia (imágenes, videos, stickers, PDFs): ACTIVO${NC}"
    echo -e "  ${Y}• Chatwoot ↔ Evolution: SINCRONIZADOS${NC}"
    echo -e "  ${Y}• S3 Buckets (públicos): GARANTIZADOS${NC}"
    
    render_access_dashboard
    
    echo -e "\n"
    read -p "  Presiona ENTER para volver..."
}

# --- MAIN MENU ---
while true; do
    render_header
    echo -e "  ${P}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${P}║${NC}  ${B}⚡ SISTEMA OPERATIVO DISPONIBLE${NC}                              ${P}║${NC}"
    echo -e "  ${P}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${P}║${NC}                                                               ${P}║${NC}"
    echo -e "  ${P}║${NC}  ${B}[1]${NC} ${W}▸ DEPLOY STACK${NC}          ${D}Infraestructura + Apps${NC}       ${P}║${NC}"
    echo -e "  ${P}║${NC}      ${D}└─ Levanta Docker, DB Fix, Dashboard${NC}                ${P}║${NC}"
    echo -e "  ${P}║${NC}                                                               ${P}║${NC}"
    echo -e "  ${P}╠───────────────────────────────────────────────────────────────╣${NC}"
    echo -e "  ${P}║${NC}  ${G}[2]${NC} ${W}▸ AEGIS SENSORS${NC}         ${D}Monitor en Tiempo Real${NC}       ${P}║${NC}"
    echo -e "  ${P}║${NC}  ${Y}[3]${NC} ${W}▸ CIPHER VAULT${NC}          ${D}Credenciales Master${NC}          ${P}║${NC}"
    echo -e "  ${P}║${NC}  ${D}[4]${NC} ${W}▸ REPAIR & SYNC${NC}         ${D}DB/Buckets/Evolution${NC}         ${P}║${NC}"
    echo -e "  ${P}║${NC}  ${B}[5]${NC} ${W}▸ STRESS TEST${NC}           ${D}Pruebas de Carga${NC}             ${P}║${NC}"
    echo -e "  ${P}║${NC}  ${D}[6]${NC} ${W}▸ LIVE LOGS${NC}             ${D}Stream en Vivo${NC}               ${P}║${NC}"
    echo -e "  ${P}║${NC}  ${R}[7]${NC} ${W}▸ SYSTEM SHUTDOWN${NC}       ${D}Apagar Todo${NC}                  ${P}║${NC}"
    echo -e "  ${P}║${NC}                                                               ${P}║${NC}"
    echo -e "  ${P}╠───────────────────────────────────────────────────────────────╣${NC}"
    echo -e "  ${P}║${NC}  ${R}[9]${NC} ${W}▸ FACTORY RESET${NC}         ${D}⚠️  Borrado Nuclear${NC}           ${P}║${NC}"
    echo -e "  ${P}║${NC}  ${W}[0]${NC} ${W}▸ EXIT${NC}                  ${D}Salir del Sistema${NC}            ${P}║${NC}"
    echo -e "  ${P}║${NC}                                                               ${P}║${NC}"
    echo -e "  ${P}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n  ${B}┌─[${P}SENTINEL${B}@${P}ADMIN${B}]${NC}"
    echo -e "  ${B}└──▸${NC} \c"
    read opt

    case $opt in
        1) execute_genesis ;;
        2)
            while true; do
                render_header
                tag "SENSORS" "Monitoría de Aviónica en Vivo"
                echo -e "  ${D}────────────────────────────────────────────────────────────────${NC}"
                check_node "Evolution API Master" "http://localhost:8080"
                check_node "Chatwoot CRM" "http://localhost:3000"
                check_node "n8n Engine" "http://localhost:5678"
                check_node "MinIO S3" "http://localhost:9000"
                echo -e "  ${D}────────────────────────────────────────────────────────────────${NC}"
                docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -E "app_|chatwoot|db_|cache_|minio"
                echo -e "\n  ${W}[Q] Volver${NC}"
                read -n 1 -s k; [[ $k == "q" ]] && break
            done
            ;;
        3)
            render_header
            tag "VAULT" "Acceso Maestro a Secretos de Red"
            echo -e "  ${D}────────────────────────────────────────────────────────────────${NC}"
            echo -e "  ${G}DB_ROOT_PASS:${NC} $($ENGINE --get POSTGRES_ROOT_PASSWORD)"
            echo -e "  ${G}REDIS_PASS:  ${NC} $($ENGINE --get REDIS_PASSWORD)"
            echo -e "  ${G}MINIO_PASS:  ${NC} $($ENGINE --get MINIO_ROOT_PASSWORD)"
            echo -e "  ${B}EVO_API_KEY: ${NC} $($ENGINE --get EVOLUTION_API_KEY)"
            echo -e "  ${D}────────────────────────────────────────────────────────────────${NC}"
            read -p "  Enter para cerrar bóveda..."
            ;;
        4)
            render_header
            tag "NEXUS" "Forzando Sincronización de Estado (Repair & Sync)..."
            echo -e "  ${D}Esta operación es IDEMPOTENTE: no borra datos, solo repara estado.${NC}\n"
            $ENGINE --wait
            $ENGINE --fix-db
            $ENGINE --setup-s3
            $ENGINE --setup-cw
            $ENGINE --fix-evo
            echo -e "\n  ${G}✅ Nexus Sincronizado. Sistema en estado óptimo.${NC}"
            echo -e "\n"
            read -p "  Presiona ENTER para volver..."
            ;;
        5)
            render_header
            tag "STRESS" "Iniciando Aegis Stress Engine (Enigma)..."
            $STRESS
            read -p "  Enter para volver..."
            ;;
        6)
            render_header
            tag "LOGS" "Streaming de Auditoría (CTRL+C para salir)..."
            docker compose -p 01-infra -f modules/01-infra/docker-compose.yml logs -f --tail=100 &
            docker compose -p 02-apps -f modules/02-apps/docker-compose.yml logs -f --tail=100 &
            docker compose -p 03-tunnel -f modules/03-tunnel/docker-compose.yml logs -f --tail=100 &
            wait
            ;;
        7)
            render_header
            tag "SHUTDOWN" "Desconectando nodos de la red..."
            docker compose -p 03-tunnel -f modules/03-tunnel/docker-compose.yml down
            docker compose -p 02-apps -f modules/02-apps/docker-compose.yml down
            docker compose -p 01-infra -f modules/01-infra/docker-compose.yml down
            echo -e "  ${G}Sistema apagado correctamente.${NC}"
            echo -e "\n"
            read -p "  Presiona ENTER para volver..."
            ;;
        9)
            echo -e "  ${R}⚠️  ALERTA DE PURGA NUCLEAR: Se borrarán TODOS los datos (Docker + Persistencia Local). Escribe 'PURGAR'${NC}"
            read -p "  >> " confirm
            if [[ "$confirm" == "PURGAR" ]]; then
                tag "PURGE" "Iniciando Protocolo de Limpieza Nuclear..."
                
                # Ejecutar script de limpieza especializado
                bash ops/scripts/clean-docker.sh
                
                echo -e "  ${Y}[LIMPIEZA] Eliminando datos de persistencia local...${NC}"
                rm -rf persistence/*
                
                # Re-create empty persistence folders
                mkdir -p persistence/postgres persistence/redis persistence/minio persistence/n8n persistence/evolution persistence/pgadmin
                
                echo -e "  ${G}✅ Purga Completada. El sistema modular está como un lienzo en blanco.${NC}"
                echo -e "\n"
                read -p "  Presiona ENTER para volver..."
            fi
            ;;
        0) exit 0 ;;
    esac
done
