#!/bin/bash
set -e

DATE=$1
RC_NAME=$2
OG_BRANCH=$3
REPO_A_DIR=~/Documents/repos/odoo-gaqsa
REPO_B_DIR=~/Documents/repos/exinnotch-odoo

BRANCH_B="sync-exinnotch-$DATE"
BRANCH_A="$RC_NAME-update-exinnotech-submodule"

# Sync from GitLab (Exinnotch)
cd "$REPO_B_DIR"
git checkout production
git pull origin production
git checkout -b "$BRANCH_B"
git push exinnotech "$BRANCH_B"

echo ""
echo "Waiting for you to create and approve the PR on GitHub for Repo B..."
echo "Press any key once the PR has been created and approved to continue updating the submodule in Repo A."
read -n 1 -s -r

# Sync submodule pointer in Repo A
cd "$REPO_A_DIR"
git checkout "$OG_BRANCH"
git pull origin "$OG_BRANCH"
git checkout -b "$BRANCH_A"
git submodule sync odoo/src/exinnotech
git submodule update --init --recursive odoo/src/exinnotech
git submodule update --remote odoo/src/exinnotech
git add .gitmodules odoo/src/exinnotech
git commit -m "[ADD] $RC_NAME update exinnotech submodule to latest"
git push origin "$BRANCH_A"
