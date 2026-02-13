#!/bin/bash

# ==============================================================================
# 🧹 DOCKER NUCLEAR CLEANUP - SENTINEL OS v11.1
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
echo -e "${Y}[1/5] Deteniendo todos los contenedores...${NC}"
docker stop $(docker ps -aq) 2>/dev/null || echo "No hay contenedores corriendo."

# 2. Eliminar containers
echo -e "${Y}[2/5] Removiendo contenedores...${NC}"
docker rm $(docker ps -aq) 2>/dev/null || echo "No hay contenedores para borrar."

# 3. Eliminar redes
echo -e "${Y}[3/5] Limpiando redes de Docker...${NC}"
docker network prune -f

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
    docker volume rm $(docker volume ls -q) 2>/dev/null
    echo -e "${G}✅ Volúmenes eliminados.${NC}"
else
    echo -e "${B}[SKIP] Volúmenes omitidos. La data persistirá.${NC}"
fi

echo -e "\n${G}✨ LIMPIEZA COMPLETADA.${NC}"
echo -e "${B}El entorno de Docker está listo para un despliegue desde cero.${NC}\n"
