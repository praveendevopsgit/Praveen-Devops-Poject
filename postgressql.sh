#!/bin/bash


PG_USER="praveen_shgardi"
PG_PASSWORD="shgardi_password"
PG_HOST="localhost"
PG_PORT="5432"
BACKUP_DIR="/path/to/backup"
S3_BUCKET="s3://my-bucket-praveen"


mkdir -p "$BACKUP_DIR"

export PGPASSWORD="$PG_PASSWORD"

databases=$(psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;")

for db in $databases; do
    echo "Backing up database: $db"

    BACKUP_FILE="$BACKUP_DIR/$db-$(date +%Y%m%d%H%M%S).sql"
    pg_dump -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -F c "$db" > "$BACKUP_FILE"

    COMPRESSED_FILE="$BACKUP_FILE.gz"
    gzip -c "$BACKUP_FILE" > "$COMPRESSED_FILE"

    echo "Uploading $COMPRESSED_FILE to S3..."
    aws s3 cp "$COMPRESSED_FILE" "$S3_BUCKET/$db/$(basename "$COMPRESSED_FILE")"

    rm "$BACKUP_FILE" "$COMPRESSED_FILE"

    echo "Backup and upload of $db completed."
done

echo "All backups completed."
