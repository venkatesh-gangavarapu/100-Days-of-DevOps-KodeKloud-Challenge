#!/bin/bash
# news_backup.sh
# Purpose    : Create zip archive of /var/www/html/news and copy to local + remote backup
# Author     : Venkatesh Gangavarapu
# Location   : /scripts/news_backup.sh
# Usage      : bash /scripts/news_backup.sh
# Note       : No sudo used. Passwordless SSH to ststor01 must be configured beforehand.

# ─── Variables ────────────────────────────────────────────
SOURCE_DIR="/var/www/html/news"
ARCHIVE_NAME="xfusioncorp_news.zip"
LOCAL_BACKUP="/backup"
REMOTE_USER="natasha"
REMOTE_HOST="ststor01"
REMOTE_BACKUP="/backup"

# ─── Step 1: Create zip archive of the source directory ───
zip -r "${LOCAL_BACKUP}/${ARCHIVE_NAME}" "${SOURCE_DIR}"

# ─── Step 2: Copy archive to Nautilus Storage Server ──────
scp "${LOCAL_BACKUP}/${ARCHIVE_NAME}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BACKUP}/"
