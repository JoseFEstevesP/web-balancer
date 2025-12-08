# Arquitectura del Sistema

## Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                Cliente                                  │
│                          (Navegador Web)                                │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                                Nginx                                    │
│                         (Proxy Inverso + SSL)                           │
│                     Puertos: 80 (HTTP), 443 (HTTPS)                     │
└───────────────────────────────────┬─────────────────────────────────────┘
                  ┌─────────────────┴────────────────┐
                  │                                  │
                  ▼                                  ▼
┌────────────────────────────────┐    ┌────────────────────────────────┐
│          Frontend              │    │           Backend              │
│      (Aplicación Web)          │    │         (API REST)             │
└────────────────────────────────┘    └─────────────────┬──────────────┘
                                                        │
                                      ┌─────────────────┴──────────────┐
                                      │                                │
                                      ▼                                ▼
                      ┌────────────────────────┐        ┌────────────────────────┐
                      │      PostgreSQL        │        │         Redis          │
                      │   (Base de Datos)      │        │  (Caché y Sesiones)    │
                      └──────────┬─────────────┘        └────────────────────────┘
                                 │
                                 ▼
                      ┌────────────────────────┐
                      │      DB-Backup         │
                      │  (Servicio de Backup)  │
                      └────────────────────────┘
```

## Descripción de Componentes

### Cliente (Navegador Web)
- **Función**: Interfaz de usuario para interactuar con el sistema
- **Tecnologías**: HTML5, CSS3, JavaScript
- **Requisitos**: Navegador moderno (Chrome, Firefox, Edge, Safari)

### Nginx (Proxy Inverso)
- **Función**: Gestión de solicitudes HTTP/HTTPS, balanceo de carga, terminación SSL
- **Imagen Docker**: nginx:1.23-alpine
- **Configuración**: Archivo nginx.conf
- **Puertos**: 80 (HTTP), 443 (HTTPS)
- **Volúmenes**:
  - Configuración: ./nginx/nginx.conf:/etc/nginx/nginx.conf
  - Certificados SSL: ./nginx/ssl:/etc/nginx/ssl
  - Archivos compartidos: shared-images:/usr/share/nginx/html/uploads

### Frontend (Aplicación Web)
- **Función**: Interfaz de usuario del sistema
- **Tecnologías**: Framework JavaScript moderno (React, Vue o Angular)
- **Construcción**: Dockerfile personalizado en ./frontend
- **Volúmenes**: shared-images:/app/public/uploads (para archivos subidos)

### Backend (API REST)
- **Función**: Lógica de negocio y procesamiento de datos
- **Tecnologías**: Framework de backend (Node.js, Django, Laravel, etc.)
- **Construcción**: Dockerfile personalizado en ./backend
- **Dependencias**: PostgreSQL, Redis
- **Volúmenes**: shared-images:/home/app/uploads (para archivos subidos)

### PostgreSQL (Base de Datos)
- **Función**: Almacenamiento persistente de datos
- **Imagen Docker**: postgres:16-alpine
- **Configuración**: Variables de entorno en .env
- **Volúmenes**: postgres-data:/var/lib/postgresql/data (datos persistentes)
- **Puertos**: Definido por DATABASE_PORT en .env

### Redis (Caché y Sesiones)
- **Función**: Almacenamiento en caché y gestión de sesiones
- **Imagen Docker**: redis:latest
- **Configuración**: Variables de entorno en .env
- **Volúmenes**: redis-data:/data (datos persistentes)
- **Puertos**: Definido por REDIS_PORT en .env

### DB-Backup (Servicio de Backup)
- **Función**: Respaldo automático de la base de datos
- **Construcción**: Dockerfile.backup en el directorio raíz
- **Script**: backup-script.sh
- **Configuración**: Variables de entorno en .env
- **Volúmenes**: ./backups:/backups (almacenamiento de respaldos)

## Flujo de Datos

1. **Solicitud del Cliente**:
   - El usuario accede al sistema a través de un navegador web
   - La solicitud se envía al servidor Nginx en el puerto 80 o 443

2. **Procesamiento en Nginx**:
   - Nginx recibe la solicitud y verifica el certificado SSL (puerto 443)
   - Según la ruta solicitada, Nginx dirige el tráfico al frontend o backend

3. **Interacción con el Frontend**:
   - El frontend procesa la solicitud y renderiza la interfaz de usuario
   - Si se necesitan datos, el frontend realiza solicitudes API al backend

4. **Procesamiento en el Backend**:
   - El backend recibe solicitudes API del frontend
   - Procesa la lógica de negocio y realiza operaciones en la base de datos
   - Utiliza Redis para caché y gestión de sesiones

5. **Operaciones de Base de Datos**:
   - PostgreSQL almacena y recupera datos según las solicitudes del backend
   - El servicio DB-Backup realiza copias de seguridad periódicas

6. **Respuesta al Cliente**:
   - El backend envía respuestas JSON al frontend
   - El frontend renderiza los datos recibidos
   - Nginx entrega la respuesta final al navegador del cliente

## Redes y Comunicación

### Red Principal (app-network)
- **Tipo**: Bridge
- **Función**: Conecta todos los servicios del sistema
- **Seguridad**: Aislada del host y otras redes Docker

### Comunicación entre Servicios
- **Frontend → Backend**: Solicitudes HTTP/HTTPS a la API REST
- **Backend → PostgreSQL**: Conexiones TCP en el puerto de PostgreSQL
- **Backend → Redis**: Conexiones TCP en el puerto de Redis
- **DB-Backup → PostgreSQL**: Conexiones para realizar respaldos

## Almacenamiento Persistente

### Volúmenes Docker
- **postgres-data**: Datos de la base de datos PostgreSQL
- **redis-data**: Datos de Redis
- **shared-images**: Archivos compartidos entre servicios

### Sistema de Archivos del Host
- **./backups**: Directorio para almacenar respaldos de la base de datos
- **./nginx/ssl**: Certificados SSL
- **./nginx/nginx.conf**: Configuración de Nginx

## Seguridad

### Certificados SSL
- Generados mediante el script generate_ssl.sh
- Almacenados en ./nginx/ssl
- Utilizados por Nginx para cifrar el tráfico HTTPS

### Aislamiento de Red
- Servicios conectados a través de una red Docker dedicada
- Exposición mínima de puertos al host

### Gestión de Credenciales
- Todas las credenciales y secretos se manejan a través de variables de entorno
- No se almacenan contraseñas en el código fuente

## Escalabilidad y Alta Disponibilidad

### Escalabilidad Horizontal
- Los servicios pueden escalarse horizontalmente añadiendo más contenedores
- Nginx puede configurarse para balanceo de carga

### Persistencia de Datos
- Volúmenes Docker para garantizar la persistencia de datos
- Sistema de respaldo automático para recuperación ante desastres

## Monitoreo y Mantenimiento

### Logs
- Logs de contenedores accesibles mediante Docker Compose
- Posibilidad de integración con sistemas de monitoreo externos

### Backups
- Respaldos automáticos de la base de datos
- Rotación de respaldos según configuración de retención

### Actualizaciones
- Actualización de imágenes Docker sin tiempo de inactividad
- Posibilidad de implementar estrategias de despliegue blue-green