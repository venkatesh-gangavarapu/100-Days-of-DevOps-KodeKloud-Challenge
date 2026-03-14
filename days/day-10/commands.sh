#!/bin/bash
# Day 10 — Bash Backup Script with Remote SCP Copy
# Challenge: KodeKloud 100 Days of DevOps
# Task: Create news_backup.sh on App Server 1 to zip and SCP website backup

# ─────────────────────────────────────────
# PRE-REQUISITES (run manually outside script)
# ─────────────────────────────────────────

# SSH into App Server 1
# ssh tony@stapp01

# Install zip package
sudo yum install -y zip

# Create directories and set ownership for tony
sudo mkdir -p /scripts /backup
sudo chown tony:tony /scripts /backup

# Set up passwordless SSH to storage server
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
ssh-copy-id natasha@ststor01     # Password: Bl@kW (last time)

# Verify passwordless SSH works
ssh natasha@ststor01 "hostname"
# Expected: ststor01 (no password prompt)

# Ensure remote backup directory exists
ssh natasha@ststor01 "mkdir -p /backup"

# ─────────────────────────────────────────
# WRITE THE SCRIPT TO SERVER
# ─────────────────────────────────────────
cat > /scripts/news_backup.sh << 'EOF'
#!/bin/bash
# news_backup.sh — Website backup script
# No sudo used. Passwordless SSH to ststor01 must be pre-configured.

SOURCE_DIR="/var/www/html/news"
ARCHIVE_NAME="xfusioncorp_news.zip"
LOCAL_BACKUP="/backup"
REMOTE_USER="natasha"
REMOTE_HOST="ststor01"
REMOTE_BACKUP="/backup"

zip -r "${LOCAL_BACKUP}/${ARCHIVE_NAME}" "${SOURCE_DIR}"
scp "${LOCAL_BACKUP}/${ARCHIVE_NAME}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BACKUP}/"
EOF

# ─────────────────────────────────────────
# SET PERMISSIONS — executable by tony
# ─────────────────────────────────────────
chmod 755 /scripts/news_backup.sh

# ─────────────────────────────────────────
# RUN THE SCRIPT
# ─────────────────────────────────────────
bash /scripts/news_backup.sh

# ─────────────────────────────────────────
# VERIFY BOTH DESTINATIONS
# ─────────────────────────────────────────
ls -lh /backup/xfusioncorp_news.zip
ssh natasha@ststor01 "ls -lh /backup/xfusioncorp_news.zip"
