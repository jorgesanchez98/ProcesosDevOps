#!/bin/bash

# Check that three arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <project> <namespace> <db_name>"
    exit 1
fi

PROJECT=$1
NAMESPACE=$2
DB_NAME=$3

export AWS_PROFILE=$PROJECT
export KUBECONFIG=$HOME/.kube/$PROJECT

echo "[INFO] Environment variables set:"
echo "  AWS_PROFILE=$AWS_PROFILE"
echo "  KUBECONFIG=$KUBECONFIG"

# Set the namespace
kubectl config set-context --current --namespace="$NAMESPACE" > /dev/null

# Get the first pod in the namespace
POD_ID=$(kubectl get pods --no-headers | awk 'NR==1 {print $1}')

if [ -z "$POD_ID" ]; then
    echo "[ERROR] No pods found in namespace $NAMESPACE"
    exit 1
fi

echo "[INFO] Using pod: $POD_ID"

# Check if the database exists
echo "[INFO] Verifying that database '$DB_NAME' exists..."
kubectl exec "$POD_ID" -- psql -U odoo -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"
if [ $? -ne 0 ]; then
    echo "[ERROR] Database '$DB_NAME' does not exist."
    exit 1
fi

echo "[INFO] Backing up files from pod: $POD_ID for database: $DB_NAME"

# Run tar to compress filestore
kubectl exec "$POD_ID" -- tar -czvf "/tmp/filestore.tar.gz" "/odoo/data/filestore/$DB_NAME"

# Run pg_dump for the database
kubectl exec "$POD_ID" -- pg_dump -U odoo -f "/tmp/db_backup.sql" -d "$DB_NAME"

# Copy files back to local machine
kubectl cp "$POD_ID":/tmp/filestore.tar.gz /tmp/filestore.tar.gz
kubectl cp "$POD_ID":/tmp/db_backup.sql /tmp/db_backup.sql

echo "[INFO] Backup complete. Files stored in /tmp:"
echo "  - /tmp/filestore.tar.gz"
echo "  - /tmp/db_backup.sql"
