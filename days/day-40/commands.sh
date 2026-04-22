#!/bin/bash
# Day 40 — Install & Configure Apache Inside Running Docker Container
# Challenge: KodeKloud 100 Days of DevOps — Phase 3
# Task: Install apache2, configure port 8088, start service in kkloud container

# ─────────────────────────────────────────
# SSH into App Server 1
# ssh tony@stapp01    (Password: Ir0nM@n)
# ─────────────────────────────────────────

# STEP 1: Verify kkloud container is running
sudo docker ps | grep kkloud

# STEP 2: Enter interactive shell inside container
sudo docker exec -it kkloud /bin/bash

# ═════════════════════════════════════════
# INSIDE THE CONTAINER:
# ═════════════════════════════════════════

# STEP 3: Update apt and install Apache
apt-get update
apt-get install -y apache2

# STEP 4: Change Listen port from 80 to 8088
sed -i 's/^Listen 80/Listen 8088/' /etc/apache2/ports.conf

# Verify
grep "^Listen" /etc/apache2/ports.conf
# Expected: Listen 8088

# STEP 5: Update VirtualHost port in default site config
sed -i 's/<VirtualHost \*:80>/<VirtualHost *:8088>/' \
  /etc/apache2/sites-enabled/000-default.conf

# Verify
grep "VirtualHost" /etc/apache2/sites-enabled/000-default.conf
# Expected: <VirtualHost *:8088>

# STEP 6: Validate Apache config (always before start)
apachectl configtest
# Expected: Syntax OK

# STEP 7: Start Apache
apache2ctl start
# or: service apache2 start

# STEP 8: Verify Apache is running on port 8088
curl http://localhost:8088
# Expected: Apache2 Ubuntu Default Page HTML

# Check port binding
ss -tlnp | grep 8088
# Expected: apache2 on 0.0.0.0:8088

# STEP 9: Exit container (keeps container running)
exit

# ═════════════════════════════════════════
# BACK ON HOST:
# ═════════════════════════════════════════

# STEP 10: Confirm container still running
sudo docker ps | grep kkloud
# Expected: STATUS "Up" ✅

# STEP 11: Test from host using container IP
CONTAINER_IP=$(sudo docker inspect kkloud \
  --format '{{.NetworkSettings.IPAddress}}')
curl http://$CONTAINER_IP:8088
