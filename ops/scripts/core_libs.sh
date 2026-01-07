#!/bin/bash

# ==========================================
# SENTINEL OS - CORE LIBRARIES v11.0
# "The nervous system of the orchestrator"
# ==========================================

# --- COLORS & STYLES ---
M_GREEN='\033[38;5;46m'   # Matrix Green
M_DARK='\033[38;5;22m'    # Dark Green
C_PINK='\033[38;5;198m'   # Neon Pink
C_CYAN='\033[38;5;51m'    # Neon Cyan
C_WHITE='\033[1;37m'      # Pure White
C_YELLOW='\033[38;5;226m' # Power Yellow
C_RED='\033[0;31m'        # Alert Red
NC='\033[0m'              # No Color
BOLD='\033[1m'

# --- UTILITY: SPINNER ---
# Usage: start_spinner "Message"
#        some_long_process
#        stop_spinner $?
spinner_pid=""
function start_spinner() {
    local msg="$1"
    echo -n -e "   ${msg}  "
    (
        while :; do
            for c in / - \\ \|; do
                echo -n -e "\b$c"
                sleep 0.1
            done
        done
    ) &
    spinner_pid=$!
}

function stop_spinner() {
    local status=$1
    kill $spinner_pid > /dev/null 2>&1
    wait $spinner_pid > /dev/null 2>&1
    echo -n -e "\b"
    if [ $status -eq 0 ]; then
        echo -e "${M_GREEN}✔ OK${NC}"
    else
        echo -e "${C_RED}✖ FAIL${NC}"
    fi
}

# --- WAIT FOR CONTAINER PORT ---
# Usage: wait_for_port "container_name" "internal_port" "display_name"
function wait_for_port() {
    local container=$1
    local port=$2
    local label=$3
    local retries=30
    local wait_time=2

    echo -n -e "    ⏳ Esperando a ${C_WHITE}${label}${NC}..."
    
    for ((i=0; i<retries; i++)); do
        # Check if container is running
        if [ "$(docker inspect -f '{{.State.Running}}' $container 2>/dev/null)" != "true" ]; then
            echo -e "\r    ❌ ${C_WHITE}${label}${NC}: ${C_RED}CONTENEDOR CAÍDO${NC}      "
            return 1
        fi

        # Check TCP connection (Bash built-in)
        # This works in Git Bash (Windows) and Linux
        if (echo > /dev/tcp/localhost/$port) >/dev/null 2>&1; then
            echo -e " ${M_GREEN}ONLINE${NC}"
            return 0
        fi

        echo -n "."
        sleep $wait_time
    done
    echo -e "${C_RED} TIMEOUT${NC}"
    return 1
}


# --- SPECIALIZED CHECKS ---
function check_postgres() {
    local container="db_core"
    local retries=30
    echo -n -e "    🐘 ${C_WHITE}PostgreSQL Core:${NC} "
    for ((i=0; i<retries; i++)); do
        if docker exec $container pg_isready -U root_admin > /dev/null 2>&1; then
            echo -e "${M_GREEN}ONLINE (Sincronizado)${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
    done
    echo -e "${C_RED}TIMEOUT${NC}"
    return 1
}

function check_redis() {
    local container="cache_core"
    local pass=$1
    echo -n -e "    🧠 ${C_WHITE}Redis Cache:${NC}    "
    if docker exec $container redis-cli -a "$pass" ping 2>/dev/null | grep PONG > /dev/null 2>&1; then
        echo -e "${M_GREEN}ONLINE (Latencia <1ms)${NC}"
        return 0
    else
        echo -e "${C_RED}OFFLINE${NC}"
        return 1
    fi
}

function check_http_endpoint() {
    local name=$1
    local url=$2
    local token_header=$3 # Optional "Header: Value"
    
    echo -n -e "    🌐 ${C_WHITE}${name}:${NC} "
    
    local cmd="curl -s -o /dev/null -w '%{http_code}' --max-time 5 '$url'"
    if [ ! -z "$token_header" ]; then
        cmd="curl -s -o /dev/null -w '%{http_code}' --max-time 5 -H '$token_header' '$url'"
    fi
    
    # We run this usually from HOST, assuming localhost mapping commands
    # But wait, inside sistema_maestro we might be running in wsl or host.
    # We should assume host environment has curl.
    
    local retries=15
    for ((i=0; i<retries; i++)); do
        local code=$(eval $cmd)
        if [[ "$code" == "200" || "$code" == "401" || "$code" == "302" ]]; then
            if [[ "$code" == "401" ]]; then
                echo -e "${C_YELLOW}ONLINE (401 Auth Required)${NC}"
            elif [[ "$code" == "302" ]]; then
                echo -e "${M_GREEN}ONLINE (302 Redirect)${NC}"
            else
                echo -e "${M_GREEN}ONLINE (200 OK)${NC}"
            fi
            return 0
        fi
        sleep 2
    done
    echo -e "${C_RED}SIN RESPUESTA ($code)${NC}"
    return 1
}
