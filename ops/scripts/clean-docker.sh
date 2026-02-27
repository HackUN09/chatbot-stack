#!/bin/bash

# ==============================================================================
# 🧹 DOCKER NUCLEAR CLEANUP - SENTINEL OS v11.0
# ==============================================================================

# Colores para salida profesional
R='\033[38;5;196m'   # Alert Red
G='\033[38;5;46m'    # Success Green
Y='\033[38;5;226m'   # Warning Gold
B='\033[38;5;51m'    # Electric Cyan
NC='\033[0m'         # Reset

echo -e "${R}"
echo "    ██████╗ ██╗     ███████╗ █████╗ ███╗   ██╗██╗   ██╗██████╗ "
echo "    ██╔══██╗██║     ██╔════╝██╔══██╗████╗  ██║██║   ██║██╔══██╗"
echo "    ██║  ██║██║     █████╗  ███████║██╔██╗ ██║██║   ██║██████╔╝"
echo "    ██║  ██║██║     ██╔══╝  ██╔══██║██║╚██╗██║██║   ██║██╔═══╝ "
echo "    ██████╔╝███████╗███████╗██║  ██║██║ ╚████║╚██████╔╝██║     "
echo "    ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     "
echo -e "${B}    ──── CLEAN INSTALL ENGINE // NEXUS PURGE PROTOCOL ────${NC}\n"

# 1. Detener containers del proyecto
echo -e "${Y}[1/5] Deteniendo contenedores de Sentinel OS...${NC}"
docker compose -p 03-tunnel -f modules/03-tunnel/docker-compose.yml down 2>/dev/null
docker compose -p 02-apps -f modules/02-apps/docker-compose.yml down 2>/dev/null
docker compose -p 01-infra -f modules/01-infra/docker-compose.yml down 2>/dev/null

# 2. Forzar limpieza de contenedores huerfanos del proyecto
echo -e "${Y}[2/5] Removiendo contenedores huérfanos del proyecto...${NC}"
docker ps -a --filter "name=chatwoot|evolution|n8n|postgres|redis|minio|cloudflared" -q | xargs -r docker rm -f 2>/dev/null || true

# 3. Eliminar redes
echo -e "${Y}[3/5] Limpiando redes de Sentinel OS...${NC}"
docker network rm secure-net 2>/dev/null || true

# 4. Eliminar imágenes (incluyendo dangling)
echo -e "${Y}[4/5] Purgando imágenes de Docker...${NC}"
echo -e "${D}Esto borrará todas las imágenes locales para forzar redescarga limpia.${NC}"
docker image prune -af

# 5. Purga de Volúmenes (Opcional pero recomendado para Clean Install)
echo -e "${R}[!] ADVERTENCIA CRÍTICA: ¿Deseas borrar TODOS los VOLÚMENES?${NC}"
echo -e "${R}    Esto eliminará bases de datos y archivos permanentes.${NC}"
read -p "    ¿Confirmar borrado de volúmenes? (s/N): " confirm_vol
if [[ "$confirm_vol" =~ ^([sS][iI]|[sS])$ ]]; then
    echo -e "${Y}[5/5] Purgando volúmenes de Docker...${NC}"
    docker volume rm 01-infra_pgadmin_data 01-infra_postgres_data 01-infra_redis_data 01-infra_minio_data 02-apps_chatwoot_data 02-apps_chatwoot_redis_data 02-apps_n8n_data 02-apps_evolution_data 2>/dev/null || true
    echo -e "${G}✅ Volúmenes eliminados.${NC}"
else
    echo -e "${B}[SKIP] Volúmenes omitidos. La data persistirá.${NC}"
fi

echo -e "\n${G}✨ LIMPIEZA COMPLETADA.${NC}"
echo -e "${B}El entorno de Docker está listo para un despliegue desde cero.${NC}\n"
