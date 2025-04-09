#!/bin/bash

# Solicitar la IP al usuario
read -p "Ingrese la IP para el certificado (por ejemplo, 10.10.73.201): " ip_address

# Validar que se haya ingresado una IP
if [[ -z "$ip_address" ]]; then
    echo "Error: La IP no puede estar vacía."
    exit 1
fi

# Validar que la IP tenga un formato válido
if ! [[ "$ip_address" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "Error: La IP ingresada no es válida."
    exit 1
fi

# Solicitar el subjectAltName al usuario
read -p "Ingrese el valor para subjectAltName (deje en blanco para usar la misma IP): " san_value

# Si el usuario no proporciona un valor para subjectAltName, usar la misma IP ingresada
if [[ -z "$san_value" ]]; then
    san_value="$ip_address"
else
    # Validar que el valor de subjectAltName sea una IP válida si no está en blanco
    if ! [[ "$san_value" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "Error: El valor de subjectAltName no es una IP válida."
        exit 1
    fi
fi

# Construir el valor de -subj correctamente
subj="/CN=$ip_address"

# Generar el certificado autofirmado con los valores proporcionados
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx-selfsigned.key \
    -out nginx-selfsigned.crt \
    -subj "$subj" \
    -addext "subjectAltName=IP:$san_value"

# Verificar si el comando se ejecutó correctamente
if [[ $? -eq 0 ]]; then
    echo "Certificado generado exitosamente."
    echo "Clave privada: nginx-selfsigned.key"
    echo "Certificado: nginx-selfsigned.crt"
else
    echo "Error al generar el certificado."
    exit 1
fi