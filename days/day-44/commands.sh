#!/bin/bash
# Day 44 — Docker Compose: httpd with Port & Volume Mapping
# Challenge: KodeKloud 100 Days of DevOps — Phase 3
# Task: Create docker-compose.yml, deploy httpd container on App Server 3

# ─────────────────────────────────────────
# SSH into App Server 3
# ssh banner@stapp03    (Password: BigGr33n)
# ─────────────────────────────────────────

# STEP 1: Verify host volume exists (do not modify content)
ls -la /opt/sysops

# STEP 2: Ensure docker directory exists
sudo mkdir -p /opt/docker

# STEP 3: Create docker-compose.yml
sudo tee /opt/docker/docker-compose.yml << 'EOF'
version: '3'
services:
  web:
    image: httpd:latest
    container_name: httpd
    ports:
      - "8084:80"
    volumes:
      - /opt/sysops:/usr/local/apache2/htdocs
EOF

# STEP 4: Verify the file
cat /opt/docker/docker-compose.yml

# STEP 5: Start with Docker Compose
cd /opt/docker
sudo docker compose up -d
# Expected: Container httpd Started

# STEP 6: Verify container is running
sudo docker ps | grep httpd
# Expected: 0.0.0.0:8084->80/tcp   httpd

# STEP 7: Verify volume mount
sudo docker inspect httpd --format '{{json .Mounts}}'

# STEP 8: Test web server
curl http://localhost:8084
# Expected: Content from /opt/sysops ✅
