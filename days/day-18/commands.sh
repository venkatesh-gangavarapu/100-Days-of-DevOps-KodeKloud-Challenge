#!/bin/bash
# Day 18 — MariaDB Installation & Database Setup
# Challenge: KodeKloud 100 Days of DevOps — Phase 2
# Task: Install MariaDB, create kodekloud_db8, user kodekloud_tim, grant full access

# ─────────────────────────────────────────
# STEP 1: SSH into DB server
# ssh peter@stdb01    (Password: Sp!dy)
# ─────────────────────────────────────────

# STEP 2: Install MariaDB
sudo yum install -y mariadb-server mariadb

# STEP 3: Start and enable service
sudo systemctl start mariadb
sudo systemctl enable mariadb

# STEP 4: Verify running
sudo systemctl status mariadb

# ─────────────────────────────────────────
# STEP 5: Run all SQL setup — one-shot method
# (Preferred for automation/documentation)
# ─────────────────────────────────────────
sudo mysql -u root <<EOF
CREATE DATABASE kodekloud_db8;
CREATE USER 'kodekloud_tim'@'%' IDENTIFIED BY 'YchZHRcLkL';
GRANT ALL PRIVILEGES ON kodekloud_db8.* TO 'kodekloud_tim'@'%';
FLUSH PRIVILEGES;
EOF

# ─────────────────────────────────────────
# STEP 6: Verify everything created correctly
# ─────────────────────────────────────────

# Check database exists
sudo mysql -u root -e "SHOW DATABASES;" | grep kodekloud_db8

# Check user exists
sudo mysql -u root -e "SELECT User, Host FROM mysql.user WHERE User='kodekloud_tim';"

# Check grants
sudo mysql -u root -e "SHOW GRANTS FOR 'kodekloud_tim'@'%';"

# ─────────────────────────────────────────
# STEP 7: Test connection as new user
# ─────────────────────────────────────────
mysql -u kodekloud_tim -pYchZHRcLkL -e "SHOW DATABASES;"
# Expected: kodekloud_db8 in the list

# ─────────────────────────────────────────
# INTERACTIVE METHOD (inside mysql prompt)
# sudo mysql -u root
# ─────────────────────────────────────────
# CREATE DATABASE kodekloud_db8;
# CREATE USER 'kodekloud_tim'@'%' IDENTIFIED BY 'YchZHRcLkL';
# GRANT ALL PRIVILEGES ON kodekloud_db8.* TO 'kodekloud_tim'@'%';
# FLUSH PRIVILEGES;
# SHOW DATABASES;
# SHOW GRANTS FOR 'kodekloud_tim'@'%';
# EXIT;
