#!/bin/bash
# Day 46 — Full Stack Docker Compose: PHP+Apache + MariaDB
# Challenge: KodeKloud 100 Days of DevOps — Phase 4
# Task: Deploy php_host (port 6200) + mysql_host (port 3306) on App Server 3

# ─────────────────────────────────────────
# SSH into App Server 3
# ssh banner@stapp03    (Password: BigGr33n)
# ─────────────────────────────────────────

# STEP 1: Create directory
sudo mkdir -p /opt/security

# STEP 2: Create docker-compose.yml
sudo tee /opt/security/docker-compose.yml << 'EOF'
version: '3'
services:
  web:
    image: php:8.2-apache
    container_name: php_host
    ports:
      - "6200:80"
    volumes:
      - /var/www/html:/var/www/html

  db:
    image: mariadb:latest
    container_name: mysql_host
    ports:
      - "3306:3306"
    volumes:
      - /var/lib/mysql:/var/lib/mysql
    environment:
      MYSQL_DATABASE: database_host
      MYSQL_USER: devuser
      MYSQL_PASSWORD: Dev@Secure#2024
      MYSQL_ROOT_PASSWORD: Root@Secure#2024
EOF

# STEP 3: Verify the file
cat /opt/security/docker-compose.yml

# STEP 4: Deploy the stack
cd /opt/security
sudo docker compose up -d
# Expected: php_host Started + mysql_host Started

# STEP 5: Verify both containers running
sudo docker ps
# Expected: php_host on 6200:80, mysql_host on 3306:3306

# STEP 6: Test web service
curl http://localhost:6200/

# STEP 7: Verify DB
sudo docker exec mysql_host mysql -u devuser -pDev@Secure#2024 \
  -e "SHOW DATABASES;"
# Expected: database_host listed ✅
