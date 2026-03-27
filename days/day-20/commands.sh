#!/bin/bash
# Day 20 — nginx + PHP-FPM 8.2 Integration via Unix Socket
# Challenge: KodeKloud 100 Days of DevOps — Phase 2
# Task: Install nginx (port 8098) + php-fpm 8.2 (unix socket) on stapp01
# Test: curl http://stapp01:8098/index.php from jump host

# ─────────────────────────────────────────
# SSH into App Server 1
# ssh tony@stapp01    (Password: Ir0nM@n)
# ─────────────────────────────────────────

# ═════════════════════════════════════════
# STEP 1: Install nginx
# ═════════════════════════════════════════
sudo yum install -y nginx

# ═════════════════════════════════════════
# STEP 2: Install PHP 8.2 via Remi repo
# ═════════════════════════════════════════
sudo yum install -y epel-release
sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
sudo yum module reset php -y
sudo yum module enable php:remi-8.2 -y
sudo yum install -y php-fpm php-cli

# Verify version
php -v
# Expected: PHP 8.2.x

# ═════════════════════════════════════════
# STEP 3: Create socket parent directory
# ═════════════════════════════════════════
sudo mkdir -p /var/run/php-fpm

# ═════════════════════════════════════════
# STEP 4: Configure PHP-FPM pool
# File: /etc/php-fpm.d/www.conf
# ═════════════════════════════════════════

# Change pool name from [www] to [default]
sudo sed -i 's/^\[www\]/[default]/' /etc/php-fpm.d/www.conf

# Set socket path
sudo sed -i 's|^listen = .*|listen = /var/run/php-fpm/default.sock|' /etc/php-fpm.d/www.conf

# Set socket ownership — nginx must own the socket file
sudo sed -i 's/^;*listen.owner = .*/listen.owner = nginx/' /etc/php-fpm.d/www.conf
sudo sed -i 's/^;*listen.group = .*/listen.group = nginx/' /etc/php-fpm.d/www.conf
sudo sed -i 's/^;*listen.mode = .*/listen.mode = 0660/' /etc/php-fpm.d/www.conf

# Set process user to nginx
sudo sed -i 's/^user = .*/user = nginx/' /etc/php-fpm.d/www.conf
sudo sed -i 's/^group = .*/group = nginx/' /etc/php-fpm.d/www.conf

# Verify key settings
grep -E "^\[|^listen|^user|^group" /etc/php-fpm.d/www.conf

# ═════════════════════════════════════════
# STEP 5: Start PHP-FPM (before nginx)
# ═════════════════════════════════════════
sudo systemctl start php-fpm
sudo systemctl enable php-fpm

# Verify socket was created at correct path
ls -la /var/run/php-fpm/default.sock
# Expected: srw-rw---- nginx nginx ... /var/run/php-fpm/default.sock

# ═════════════════════════════════════════
# STEP 6: Configure nginx
# Add inside http {} block in /etc/nginx/nginx.conf
# ═════════════════════════════════════════
sudo vi /etc/nginx/nginx.conf

# Server block to add:
#
# server {
#     listen       8098;
#     server_name  stapp01;
#     root         /var/www/html;
#     index        index.php index.html;
#
#     location / {
#         try_files $uri $uri/ =404;
#     }
#
#     location ~ \.php$ {
#         fastcgi_pass   unix:/var/run/php-fpm/default.sock;
#         fastcgi_index  index.php;
#         fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
#         include        fastcgi_params;
#     }
# }

# ═════════════════════════════════════════
# STEP 7: SELinux — allow port + socket access
# ═════════════════════════════════════════
sudo semanage port -a -t http_port_t -p tcp 8098
sudo setsebool -P httpd_can_network_connect 1

# ═════════════════════════════════════════
# STEP 8: Validate and start nginx
# ═════════════════════════════════════════
sudo nginx -t
# Expected: syntax is ok / test is successful

sudo systemctl start nginx
sudo systemctl enable nginx

# ═════════════════════════════════════════
# STEP 9: Verify everything is running
# ═════════════════════════════════════════
sudo systemctl status nginx
sudo systemctl status php-fpm
sudo ss -tlnp | grep 8098

# ═════════════════════════════════════════
# STEP 10: Test from jump host
# ═════════════════════════════════════════
# curl http://stapp01:8098/index.php
# Expected: PHP application response

# ─────────────────────────────────────────
# DEBUGGING
# ─────────────────────────────────────────
# sudo tail -f /var/log/nginx/error.log
# sudo tail -f /var/log/php-fpm/error.log
# sudo journalctl -u php-fpm -n 30 --no-pager
# Check socket: ls -la /var/run/php-fpm/default.sock
