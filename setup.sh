#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Web Balancer - Setup ===${NC}"
echo ""

# 1. .env
if [[ ! -f ".env" ]]; then
	echo -e "${YELLOW}[1/4]${NC} Creando .env desde .env.example..."
	cp .env.example .env
	echo "  .env creado. Editalo con tus valores antes de continuar."
	echo ""
	read -p "Presiona Enter para continuar (o Ctrl+C para salir y editar)..." _
else
	echo -e "${YELLOW}[1/4]${NC} .env ya existe, saltando."
fi

# Load env vars
set -a
source .env
set +a

# 2. Generate SSL
echo -e "${YELLOW}[2/4]${NC} Generando certificados SSL..."
if [[ -f "nginx/ssl/nginx-selfsigned.crt" ]]; then
	echo "  Certificados ya existen. Usa --force para regenerar."
else
	bash nginx/ssl/generate_ssl.sh --non-interactive
fi

# 3. Generate nginx.conf
echo -e "${YELLOW}[3/4]${NC} Generando nginx/nginx.conf..."
if command -v envsubst &>/dev/null; then
	export NGINX_SERVER_NAME="${NGINX_SERVER_NAME:-localhost}"
	envsubst '${NGINX_SERVER_NAME}' < nginx/nginx.conf.template > nginx/nginx.conf
	echo "  nginx.conf generado con server_name=${NGINX_SERVER_NAME}"
else
	echo "  envsubst no disponible, copiando template directamente."
	cp nginx/nginx.conf.template nginx/nginx.conf
fi

# 4. Create directories
echo -e "${YELLOW}[4/4]${NC} Creando directorios necesarios..."
mkdir -p backups
echo "  directorios listos."

echo ""
echo -e "${GREEN}✓ Setup completado.${NC}"
echo ""
echo "Para iniciar los servicios:"
echo "  docker compose up -d"
echo ""
echo "Para ver logs:"
echo "  docker compose logs -f"
