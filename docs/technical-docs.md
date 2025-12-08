# Documentación Técnica del Sistema

## Arquitectura del Sistema

El sistema está construido utilizando una arquitectura de microservicios basada en contenedores Docker, orquestados mediante Docker Compose. Esta arquitectura proporciona modularidad, escalabilidad y facilidad de despliegue.

### Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                           Nginx (Proxy)                          │
│                     Puertos: 80 (HTTP), 443 (HTTPS)              │
└───────────────────────────────┬─────────────────────────────────┘
                ┌───────────────┴───────────────┐
                ▼                               ▼
┌─────────────────────────┐         ┌─────────────────────────┐
│        Frontend         │         │         Backend         │
│     (Aplicación Web)    │         │      (API REST)         │
└───────────┬─────────────┘         └────────────┬────────────┘
            │                                    │
            │                                    ▼
            │                       ┌─────────────────────────┐
            │                       │      Base de Datos      │
            │                       │      (PostgreSQL)       │
            │                       └────────────┬────────────┘
            │                                    │
            │                                    ▼
            │                       ┌─────────────────────────┐
            └───────────────────────►        Redis           │
                                    │   (Caché y Sesiones)    │
                                    └─────────────────────────┘
```

### Servicios Principales

1. **Nginx**: Servidor web que actúa como proxy inverso, maneja SSL y sirve archivos estáticos.
2. **Frontend**: Aplicación web cliente.
3. **Backend**: API REST que proporciona la lógica de negocio.
4. **PostgreSQL**: Base de datos relacional para almacenamiento persistente.
5. **Redis**: Sistema de caché y gestión de sesiones.
6. **DB-Backup**: Servicio de respaldo automático de la base de datos.

## Configuración Detallada de Servicios

### Nginx

- **Imagen**: nginx:1.23-alpine
- **Puertos**: 80 (HTTP), 443 (HTTPS)
- **Volúmenes**:
  - `./nginx/nginx.conf:/etc/nginx/nginx.conf`: Configuración del servidor
  - `./nginx/ssl:/etc/nginx/ssl`: Certificados SSL
  - `shared-images:/usr/share/nginx/html/uploads`: Archivos compartidos

### Base de Datos (PostgreSQL)

- **Imagen**: postgres:16-alpine
- **Variables de Entorno**:
  - `POSTGRES_USER`: Usuario de la base de datos
  - `POSTGRES_PASSWORD`: Contraseña de la base de datos
  - `POSTGRES_DB`: Nombre de la base de datos
  - `DATABASE_PORT`: Puerto de la base de datos
- **Volúmenes**:
  - `postgres-data:/var/lib/postgresql/data`: Datos persistentes

### Redis

- **Imagen**: redis:latest
- **Variables de Entorno**:
  - `REDIS_PORT`: Puerto de Redis
- **Volúmenes**:
  - `redis-data:/data`: Datos persistentes de Redis

### Frontend

- **Build**: Construido desde el directorio `./frontend`
- **Volúmenes**:
  - `shared-images:/app/public/uploads`: Archivos compartidos

### Backend

- **Build**: Construido desde el directorio `./backend`
- **Volúmenes**:
  - `shared-images:/home/app/uploads`: Archivos compartidos
- **Dependencias**: Depende del servicio de base de datos

### DB-Backup

- **Build**: Construido desde `Dockerfile.backup`
- **Variables de Entorno**:
  - `TZ`: Zona horaria (America/Caracas)
  - `POSTGRES_USER`: Usuario de la base de datos
  - `POSTGRES_PASSWORD`: Contraseña de la base de datos
  - `POSTGRES_DB`: Nombre de la base de datos
  - `POSTGRES_HOST`: Host de la base de datos (db)
  - `RETENTION_DAYS`: Días de retención de backups
  - `BACKUP_INTERVAL_SECONDS`: Intervalo entre backups
- **Volúmenes**:
  - `./backups:/backups`: Directorio de backups

## Redes y Volúmenes

### Redes

- **app-network**: Red bridge que conecta todos los servicios

### Volúmenes

- **postgres-data**: Almacenamiento persistente para PostgreSQL
- **shared-images**: Volumen compartido para archivos subidos
- **redis-data**: Almacenamiento persistente para Redis

## Seguridad

### SSL/TLS

El sistema utiliza certificados SSL autofirmados generados mediante el script `generate_ssl.sh`. Este script:

1. Solicita una dirección IP para el certificado
2. Opcionalmente permite especificar un subjectAltName
3. Genera un certificado autofirmado válido por 365 días con una clave RSA de 2048 bits

### Buenas Prácticas de Seguridad

- Todas las contraseñas y credenciales se manejan a través de variables de entorno
- La comunicación entre servicios está aislada en una red Docker dedicada
- El acceso a la base de datos está restringido al backend
- Los certificados SSL se utilizan para cifrar el tráfico web

## Sistema de Respaldo

El sistema incluye un servicio dedicado para realizar copias de seguridad automáticas de la base de datos PostgreSQL.

### Funcionamiento

1. El script `backup-script.sh` se ejecuta periódicamente según la configuración
2. Genera un archivo de respaldo con timestamp en formato SQL comprimido con gzip
3. Elimina automáticamente los respaldos más antiguos según el valor de `RETENTION_DAYS`

### Configuración

- `POSTGRES_USER`: Usuario de PostgreSQL con permisos para realizar backups
- `POSTGRES_PASSWORD`: Contraseña del usuario
- `POSTGRES_DB`: Base de datos a respaldar
- `POSTGRES_HOST`: Host de la base de datos (db)
- `RETENTION_DAYS`: Número de días que se conservan los backups
- `BACKUP_INTERVAL_SECONDS`: Intervalo entre backups automáticos

## Guía de Desarrollo

### Requisitos Previos

- Docker Engine 20.10+
- Docker Compose 2.0+
- Make (opcional)
- Git
- OpenSSL

### Configuración del Entorno de Desarrollo

1. Clonar el repositorio:

   ```bash
   git clone https://github.com/JoseFEstevesP/web-balancer.git
   cd web-balancer
   ```

2. Crear archivo de variables de entorno:

   ```bash
   cp .env.example .env
   # Editar .env con los valores apropiados
   ```

3. Generar certificados SSL para desarrollo:

   ```bash
   cd nginx/ssl
   ./generate_ssl.sh
   # Seguir las instrucciones en pantalla
   ```

4. Iniciar los servicios en modo desarrollo:
   ```bash
   docker-compose up
   ```

### Estructura de Directorios

```
.
├── backend/             # Código fuente del backend
├── frontend/            # Código fuente del frontend
├── nginx/               # Configuración de Nginx
│   ├── ssl/             # Certificados SSL y script de generación
│   └── nginx.conf       # Configuración principal de Nginx
├── docs/                # Documentación del sistema
├── backups/             # Directorio para almacenar backups
├── backup-script.sh     # Script de respaldo
├── docker-compose.yml   # Configuración de Docker Compose
├── Dockerfile.backup    # Dockerfile para el servicio de backup
└── README.md            # Documentación general
```

## Despliegue en Producción

### Preparación

1. Asegurarse de que el servidor cumple con los requisitos mínimos:

   - 2 CPU cores
   - 4GB RAM
   - 20GB espacio en disco
   - Docker y Docker Compose instalados

2. Configurar variables de entorno para producción:

   ```bash
   cp .env.example .env.prod
   # Editar .env.prod con valores seguros para producción
   ```

3. Obtener certificados SSL válidos (recomendado para producción):
   - Opción 1: Utilizar Let's Encrypt
   - Opción 2: Utilizar certificados comerciales
   - Opción 3: Usar el script incluido para certificados autofirmados

### Proceso de Despliegue

1. Clonar el repositorio en el servidor de producción:

   ```bash
   git clone https://github.com/JoseFEstevesP/web-balancer.git
   cd web-balancer
   ```

2. Configurar el entorno:

   ```bash
   cp .env.prod .env
   ```

3. Configurar certificados SSL:

   ```bash
   # Si se usan certificados propios, colocarlos en nginx/ssl/
   # Si se generan con el script:
   cd nginx/ssl
   ./generate_ssl.sh
   ```

4. Iniciar los servicios en modo producción:

   ```bash
   docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
   ```

5. Verificar que todos los servicios estén funcionando:
   ```bash
   docker-compose ps
   ```

### Monitoreo y Mantenimiento

- **Logs**: Revisar logs regularmente con `docker-compose logs`
- **Backups**: Verificar que los backups se estén generando correctamente
- **Actualizaciones**: Actualizar imágenes periódicamente con `docker-compose pull`

## Solución de Problemas

### Problemas Comunes y Soluciones

#### Error 404 en Nginx

- **Problema**: Las páginas no se encuentran al recargar
- **Solución**: Verificar la configuración de rutas en nginx.conf y asegurarse de que la directiva `try_files` esté correctamente configurada

#### Problemas de Conexión a la Base de Datos

- **Problema**: El backend no puede conectarse a PostgreSQL
- **Solución**: Verificar las variables de entorno y asegurarse de que los servicios estén en la misma red Docker

#### Errores de Certificado SSL

- **Problema**: Advertencias de certificado no confiable
- **Solución**: Generar nuevos certificados o importar el certificado autofirmado en los navegadores cliente

#### Backups Fallidos

- **Problema**: No se generan los archivos de backup
- **Solución**: Verificar permisos en el directorio /backups y las credenciales de PostgreSQL

## Referencias Técnicas

- [Documentación oficial de Docker](https://docs.docker.com/)
- [Documentación de PostgreSQL](https://www.postgresql.org/docs/)
- [Documentación de Nginx](https://nginx.org/en/docs/)
- [Documentación de Redis](https://redis.io/documentation)
