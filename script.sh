#!/bin/bash

# Step 1: Pull the Docker image with Travis migrations and credentials as environment variables
docker pull enterprise-3.0-image

# Step 1.1: Set environment variables for database credentials
DB_USER="your_db_user"
DB_PASSWORD="your_db_password"
DB_HOST="your_db_host"

# Step 1.2: Drop the database
docker run -e DB_USER="$DB_USER" -e DB_PASSWORD="$DB_PASSWORD" -e DB_HOST="$DB_HOST" enterprise-3.0-image sh -c 'echo "DROP DATABASE your_db_name;" | mysql -u$DB_USER -p$DB_PASSWORD -h$DB_HOST'

# Step 1.3: Apply SQL dump from the local filesystem
LOCAL_DUMP_PATH="/path/to/local/sql/dump.sql"
docker run -e DB_USER="$DB_USER" -e DB_PASSWORD="$DB_PASSWORD" -e DB_HOST="$DB_HOST" -v "$LOCAL_DUMP_PATH:/mnt/dump.sql" enterprise-3.0-image sh -c 'mysql -u$DB_USER -p$DB_PASSWORD -h$DB_HOST your_db_name < /mnt/dump.sql'

# Step 1.4: Apply the migrations
docker run -e DB_USER="$DB_USER" -e DB_PASSWORD="$DB_PASSWORD" -e DB_HOST="$DB_HOST" enterprise-3.0-image sh -c 'travis-migrations && travis-logs-migrations'

# Step 2: Port-forward to both databases in the cluster
kubectl port-forward service/db1-service 3306:3306 &
kubectl port-forward service/db2-service 3307:3306 &

# Step 3: Pass ports, credentials, and the folder with dumps and run the Docker image
docker run -e DB_USER="$DB_USER" -e DB_PASSWORD="$DB_PASSWORD" -e DB_HOST="$DB_HOST" -e DB_PORT1=3306 -e DB_PORT2=3307 -v "$LOCAL_DUMP_PATH:/mnt/dump.sql" enterprise-3.0-image
