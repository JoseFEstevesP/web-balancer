#!/bin/sh

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="/backups/backup_${TIMESTAMP}.sql.gz"

PGPASSWORD="$POSTGRES_PASSWORD" pg_dump -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" | gzip > "$BACKUP_FILE"

# Eliminar backups antiguos
find /backups -name "backup_*.sql.gz" -type f -mtime +$RETENTION_DAYS -exec rm -f {} \;

echo "Backup creado: $BACKUP_FILE"