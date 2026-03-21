#!/bin/bash
# Day 15 — nginx Installation, SSL Certificate Deployment & HTTPS Config
# Challenge: KodeKloud 100 Days of DevOps — Phase 1 Capstone
# Task: Install nginx, deploy SSL cert, serve "Welcome!" over HTTPS on stapp02

# ─────────────────────────────────────────
# SSH into App Server 2
# ssh steve@stapp02    (Password: Am3ric@)
# ─────────────────────────────────────────

# STEP 1: Install nginx
sudo yum install -y nginx

# STEP 2: Create SSL directory and move certs from /tmp
sudo mkdir -p /etc/nginx/ssl
sudo mv /tmp/nautilus.crt /etc/nginx/ssl/
sudo mv /tmp/nautilus.key /etc/nginx/ssl/

# Set correct permissions
sudo chmod 600 /etc/nginx/ssl/nautilus.key   # Private key — owner only
sudo chmod 644 /etc/nginx/ssl/nautilus.crt   # Certificate — readable

# Fix SELinux context (moved from /tmp — labels need correcting)
sudo restorecon -Rv /etc/nginx/ssl/

# STEP 3: Create index.html
echo "Welcome!" | sudo tee /usr/share/nginx/html/index.html
cat /usr/share/nginx/html/index.html    # Verify

# STEP 4: Add SSL server block to nginx.conf
# Add inside the http {} block in /etc/nginx/nginx.conf:
#
# server {
#     listen       443 ssl;
#     server_name  stapp02;
#
#     ssl_certificate     /etc/nginx/ssl/nautilus.crt;
#     ssl_certificate_key /etc/nginx/ssl/nautilus.key;
#
#     root   /usr/share/nginx/html;
#     index  index.html;
#
#     location / {
#         try_files $uri $uri/ =404;
#     }
# }

sudo vi /etc/nginx/nginx.conf

# STEP 5: Validate config syntax — always before restart
sudo nginx -t
# Expected: syntax is ok / test is successful

# STEP 6: Start and enable nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# STEP 7: Verify service and port
sudo systemctl status nginx
sudo ss -tlnp | grep nginx
# Expected: LISTEN on *:443

# ─────────────────────────────────────────
# VERIFICATION FROM JUMP HOST
# ─────────────────────────────────────────
curl -Ik https://stapp02/
# -I = headers only
# -k = ignore self-signed cert verification
# Expected: HTTP/1.1 200 OK

# ─────────────────────────────────────────
# DEBUGGING (if needed)
# ─────────────────────────────────────────
sudo tail -30 /var/log/nginx/error.log
sudo journalctl -u nginx -n 30 --no-pager
sudo nginx -T   # Dump full parsed config
