#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="$SCRIPT_DIR"

# Load .env if present (from project root)
ENV_FILE="$(cd "$SCRIPT_DIR/../.." && pwd)/.env"
if [[ -f "$ENV_FILE" ]]; then
	set -a
	source "$ENV_FILE"
	set +a
fi

usage() {
	echo "Usage: $0 [OPTIONS]"
	echo ""
	echo "Generate self-signed SSL certificates for Nginx."
	echo ""
	echo "Options:"
	echo "  --ip IP_ADDRESS        IP address for the certificate (default: prompt)"
	echo "  --san SAN_VALUE        SubjectAltName (default: same as IP)"
	echo "  --domain DOMAIN        Domain name for server_name (default: IP)"
	echo "  --days DAYS            Certificate validity in days (default: 365)"
	echo "  --non-interactive      Skip prompts, fail if required vars missing"
	echo "  -h, --help             Show this help"
	echo ""
	echo "Environment variables (used with --non-interactive):"
	echo "  SSL_IP                 IP address"
	echo "  SSL_SAN                SubjectAltName (optional, defaults to SSL_IP)"
	echo "  NGINX_SERVER_NAME      Domain name (optional, defaults to SSL_IP)"
	echo "  SSL_DAYS               Validity in days (optional, defaults to 365)"
	exit 0
}

# Parse args
POSITIONAL=()
while [[ $# -gt 0 ]]; do
	case $1 in
	--ip)
		SSL_IP="$2"
		shift 2
		;;
	--san)
		SSL_SAN="$2"
		shift 2
		;;
	--domain)
		NGINX_SERVER_NAME="$2"
		shift 2
		;;
	--days)
		SSL_DAYS="$2"
		shift 2
		;;
	--non-interactive)
		NON_INTERACTIVE=1
		shift
		;;
	-h | --help)
		usage
		;;
	*)
		echo "Unknown option: $1"
		usage
		;;
	esac
done

SSL_DAYS="${SSL_DAYS:-365}"

# Get IP address
if [[ -z "$SSL_IP" ]]; then
	if [[ "$NON_INTERACTIVE" == "1" ]]; then
		echo "Error: --ip or SSL_IP is required in non-interactive mode"
		exit 1
	fi
	read -p "Ingrese la IP para el certificado (ej. 10.10.73.201): " SSL_IP
fi

if ! [[ "$SSL_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
	echo "Error: IP '$SSL_IP' no es válida."
	exit 1
fi

# SubjectAltName
if [[ -z "$SSL_SAN" ]]; then
	if [[ "$NON_INTERACTIVE" != "1" ]]; then
		read -p "Ingrese subjectAltName (Enter para usar IP): " SSL_SAN
	fi
	SSL_SAN="${SSL_SAN:-$SSL_IP}"
fi

if ! [[ "$SSL_SAN" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && ! [[ "$SSL_SAN" =~ ^[a-zA-Z0-9.-]+$ ]]; then
	echo "Error: SAN '$SSL_SAN' no es válido (debe ser IP o dominio)."
	exit 1
fi

# Determine SAN type
if [[ "$SSL_SAN" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
	SAN_ENTRY="IP:$SSL_SAN"
else
	SAN_ENTRY="DNS:$SSL_SAN"
fi

cd "$CERTS_DIR"

openssl req -x509 -nodes -days "$SSL_DAYS" -newkey rsa:2048 \
	-keyout nginx-selfsigned.key \
	-out nginx-selfsigned.crt \
	-subj "/CN=$SSL_IP" \
	-addext "subjectAltName=$SAN_ENTRY" 2>/dev/null || {
	# Fallback for older OpenSSL (< 1.1.1)
	openssl req -x509 -nodes -days "$SSL_DAYS" -newkey rsa:2048 \
		-keyout nginx-selfsigned.key \
		-out nginx-selfsigned.crt \
		-subj "/CN=$SSL_IP"
}

chmod 600 nginx-selfsigned.key
echo "Certificado SSL generado exitosamente."
echo "  IP/Domain:    $SSL_IP"
echo "  SAN:          $SAN_ENTRY"
echo "  Validity:     ${SSL_DAYS} dias"
echo "  Private key:  nginx-selfsigned.key"
echo "  Certificate:  nginx-selfsigned.crt"
