#!/bin/bash

# Step 1: Pull the Docker image with Travis migrations and credentials as environment variables
docker pull enterprise-3.0-image

# Step 1.1: Set environment variables for database credentials
DB_USER="your_db_user"
DB_PASSWORD="your_db_password"
DB_HOST="your_db_host"

# Step 1.2: Drop the database (PostgreSQL)
docker run -e DB_USER="$DB_USER" -e DB_PASSWORD="$DB_PASSWORD" -e DB_HOST="$DB_HOST" enterprise-3.0-image sh -c 'psql -U $DB_USER -h $DB_HOST -d postgres -c "DROP DATABASE IF EXISTS your_db_name"'

# Step 1.3: Apply SQL dump from the local filesystem (PostgreSQL)
LOCAL_DUMP_PATH="/path/to/local/sql/dump.sql"
docker run -e DB_USER="$DB_USER" -e DB_PASSWORD="$DB_PASSWORD" -e DB_HOST="$DB_HOST" -v "$LOCAL_DUMP_PATH:/mnt/dump.sql" enterprise-3.0-image sh -c 'pg_restore -U $DB_USER -h $DB_HOST -d your_db_name /mnt/dump.sql'

# Step 1.4: Apply the migrations (assuming you have PostgreSQL migrations)
docker run -e DB_USER="$DB_USER" -e DB_PASSWORD="$DB_PASSWORD" -e DB_HOST="$DB_HOST" enterprise-3.0-image sh -c 'travis-migrations && travis-logs-migrations'

# Step 2: Port-forward to both databases in the cluster
kubectl port-forward service/db1-service 5432:5432 &
kubectl port-forward service/db2-service 5433:5432 &

# Step 3: Pass ports, credentials, and the folder with dumps and run the Docker image
docker run -e DB_USER="$DB_USER" -e DB_PASSWORD="$DB_PASSWORD" -e DB_HOST="$DB_HOST" -e DB_PORT1=5432 -e DB_PORT2=5433 -v "$LOCAL_DUMP_PATH:/mnt/dump.sql" enterprise-3.0-image
