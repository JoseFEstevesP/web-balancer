# Sistema de Gestión

## Descripción General

Este es un sistema completo que integra varios servicios Docker, incluyendo un frontend, backend, bases de datos PostgreSQL y un servidor Nginx como proxy inverso con soporte SSL.

## Estructura del Proyecto

```
.
├── backend/
├── frontend/
├── nginx/
│   ├── ssl/
│   └── conf/
├── postgres/
├── backup-script.sh
├── docker-compose.yml
└── README.md
```

## Componentes Principales

### Docker Compose

El proyecto utiliza Docker Compose para orquestar los siguientes servicios:

- **nginx**: Servidor web principal (nginx:1.23-alpine)
- **frontend**: Aplicación frontend personalizada
- **backend**: API backend personalizada
- **postgres**: Base de datos principal (postgres:16-alpine)

### Nginx

Actúa como proxy inverso y maneja:

- Redirección de tráfico
- Terminación SSL
- Servicio de archivos estáticos

### SSL

La configuración SSL se maneja a través del script `generate_ssl.sh` en el directorio nginx/ssl.

### Backup

Sistema automatizado de copias de seguridad mediante el script `backup-script.sh`.

## Requisitos Previos

- Docker Engine
- Docker Compose
- Make (opcional, para comandos simplificados)
- OpenSSL (para generación de certificados SSL)

## Instrucciones de Instalación

1. Clonar el repositorio:

```bash
git clone [URL_DEL_REPOSITORIO]
cd [web-balancer]
```

2. Configurar variables de entorno:

```bash
cp .env.example .env
# Editar .env con los valores apropiados
```

3. Generar certificados SSL:

```bash
cd nginx/ssl
./generate_ssl.sh
```

4. Iniciar los servicios:

```bash
docker-compose up -d
```

## Configuración del Proyecto

### Volúmenes Docker

- **postgres_data**: Datos persistentes de PostgreSQL
- **nginx_ssl**: Certificados SSL
- **nginx_conf**: Configuración de Nginx

### Puertos

- Frontend: 3000
- Backend: 8000
- Nginx: 80 (HTTP) y 443 (HTTPS)
- PostgreSQL: 5432

## Mantenimiento

### Copias de Seguridad

Las copias de seguridad se realizan automáticamente mediante el script `backup-script.sh`.
Para ejecutar una copia de seguridad manual:

```bash
./backup-script.sh
```

### Logs

Visualizar logs de los servicios:

```bash
# Todos los servicios
docker-compose logs

# Servicio específico
docker-compose logs [servicio]
```

## Notas Importantes

- Asegúrese de tener suficiente espacio en disco para los volúmenes Docker
- Mantenga actualizadas las variables de entorno
- Revise regularmente los logs del sistema
- Realice copias de seguridad periódicas

## Solución de Problemas Comunes

- Si aparece un error 404 al recargar la página en el navegador del servidor nginx, verifique la configuración de las rutas en el archivo de configuración de nginx.

## Soporte

Para reportar problemas o solicitar ayuda:

1. Abrir un issue en el repositorio
2. Contactar al equipo de desarrollo
3. Consultar la documentación técnica detallada

## Licencia

[Especificar la licencia del proyecto]
