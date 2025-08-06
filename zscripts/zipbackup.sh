#!/bin/bash

# Check for exactly 2 arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <project> <db_name>"
    exit 1
fi

PROJECT=$1
DB_NAME=$2

# Define paths
BACKUP_DIR=~/Documents/backups/"$PROJECT"
WORK_DIR=$(mktemp -d /tmp/backup_workdir.XXXXXX)
FILESTORE_ARCHIVE=/tmp/filestore.tar.gz
DB_BACKUP_FILE=/tmp/db_backup.sql

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check existence of required files
if [ ! -f "$FILESTORE_ARCHIVE" ]; then
    echo "Missing filestore archive: $FILESTORE_ARCHIVE"
    exit 1
fi

if [ ! -f "$DB_BACKUP_FILE" ]; then
    echo "Missing database dump: $DB_BACKUP_FILE"
    exit 1
fi

# Copy files into working directory
cp "$DB_BACKUP_FILE" "$WORK_DIR/db_backup.sql"
cp "$FILESTORE_ARCHIVE" "$WORK_DIR/filestore.tar.gz"

# Change to working directory
cd "$WORK_DIR" || { echo "Failed to enter working directory"; exit 1; }

# Extract filestore archive
if ! tar -xzvf filestore.tar.gz; then
    echo "Failed to extract filestore archive"
    exit 1
fi

# Define path to extracted filestore
EXTRACTED_PATH="$WORK_DIR/odoo/data/filestore/$DB_NAME"

# Check if the expected structure exists
if [ ! -d "$EXTRACTED_PATH" ]; then
    echo "Expected filestore directory not found: $EXTRACTED_PATH"
    exit 1
fi

# Create clean filestore directory
mkdir -p "$WORK_DIR/filestore"

# Move contents from DB_NAME folder into flat filestore/ folder
mv "$EXTRACTED_PATH"/* "$WORK_DIR/filestore/"

# Rename the SQL file
mv "$WORK_DIR/db_backup.sql" "$WORK_DIR/dump.sql"

# Create final zip archive
FINAL_ZIP="$DB_NAME.zip"
zip -r "$FINAL_ZIP" filestore dump.sql

# Move final zip to backup directory
mv "$FINAL_ZIP" "$BACKUP_DIR/"

# Cleanup working directory — only final zip remains in backup folder
rm -rf "$WORK_DIR"

echo "Backup complete: $BACKUP_DIR/$FINAL_ZIP"
