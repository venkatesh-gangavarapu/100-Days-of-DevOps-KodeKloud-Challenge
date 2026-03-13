#!/bin/bash
# Day 09 — Production Incident: MariaDB Service Down
# Challenge: KodeKloud 100 Days of DevOps
# Task: Diagnose and fix MariaDB service failure on database server stdb01

# ─────────────────────────────────────────
# STEP 1: SSH into Database Server
# ─────────────────────────────────────────
# ssh peter@stdb01   (Password: Sp!dy)

# ─────────────────────────────────────────
# STEP 2: Check service status — always first
# ─────────────────────────────────────────
sudo systemctl status mariadb
# Look for: Active state + enabled/disabled + error messages

# ─────────────────────────────────────────
# STEP 3: Read logs to identify ROOT CAUSE
# Never skip this step in production
# ─────────────────────────────────────────
sudo journalctl -u mariadb -n 50 --no-pager
sudo tail -100 /var/log/mariadb/mariadb.log

# ─────────────────────────────────────────
# STEP 4: Environmental checks
# ─────────────────────────────────────────
df -h                          # Disk space — full disk is a common cause
ls -la /var/lib/mysql/         # Data directory permissions
sudo ss -tlnp | grep 3306      # Port 3306 conflict check
sudo cat /etc/my.cnf           # Config syntax review

# ─────────────────────────────────────────
# STEP 5: Fix permissions if needed
# ─────────────────────────────────────────
# sudo chown -R mysql:mysql /var/lib/mysql
# sudo chmod 755 /var/lib/mysql

# ─────────────────────────────────────────
# STEP 6: Start the MariaDB service
# ─────────────────────────────────────────
sudo systemctl start mariadb

# ─────────────────────────────────────────
# STEP 7: Enable on boot — critical in prod
# ─────────────────────────────────────────
sudo systemctl enable mariadb

# ─────────────────────────────────────────
# STEP 8: Verify service is active + enabled
# ─────────────────────────────────────────
sudo systemctl status mariadb
sudo systemctl is-active mariadb    # Expected: active
sudo systemctl is-enabled mariadb   # Expected: enabled

# ─────────────────────────────────────────
# STEP 9: Verify DB is accepting connections
# ─────────────────────────────────────────
mysql -u root -e "SHOW DATABASES;"
mysqladmin -u root status

# ─────────────────────────────────────────
# BONUS: Live log monitoring during restart
# ─────────────────────────────────────────
sudo journalctl -u mariadb -f    # Follow logs in real time
