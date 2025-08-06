#!/bin/bash

# Usage: ./reset_odoo_admin_pass.sh <PROJECT> <NAMESPACE> <DB_NAME> <NEW_PASSWORD>

set -euo pipefail

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <PROJECT> <NAMESPACE> <DB_NAME> <NEW_PASSWORD>"
    exit 1
fi

PROJECT=$1
NAMESPACE=$2
DB_NAME=$3
NEW_PASSWORD=$4

# Set AWS environment
export AWS_PROFILE="$PROJECT"
export KUBECONFIG="$HOME/.kube/$PROJECT"

echo "[INFO] Environment variables set:"
echo "  AWS_PROFILE=$AWS_PROFILE"
echo "  KUBECONFIG=$KUBECONFIG"

# Generate hashed password using inline Python
HASHED_PASS=$(python3 -c "
import sys
from passlib.hash import pbkdf2_sha512
print(pbkdf2_sha512.using(rounds=350000).hash('$NEW_PASSWORD'))
")

echo "[INFO] Password hashed."

# Set namespace in kubectl
kubectl config set-context --current --namespace="$NAMESPACE" > /dev/null
echo "[INFO] Namespace set to $NAMESPACE"

# Get the first pod name (assuming it's the main Odoo pod)
POD=$(kubectl get pods --no-headers | awk 'NR==1 {print $1}')
echo "[INFO] Target pod: $POD"

# Execute SQL inside the pod using a safe heredoc block
echo "[INFO] Updating password for user ID 2..."

kubectl exec -i "$POD" -- env HASHED_PASS="$HASHED_PASS" DB_NAME="$DB_NAME" bash <<'EOF'
psql -d "$DB_NAME" <<SQL
UPDATE res_users SET password='${HASHED_PASS}' WHERE id=2;
SELECT id, login, password FROM res_users WHERE id=2;
SQL
EOF

echo "[SUCCESS] Password for user ID 2 has been updated and verified."
