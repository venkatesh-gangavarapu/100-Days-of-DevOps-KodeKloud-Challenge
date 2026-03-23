#!/bin/bash
# Day 16 — nginx Load Balancer Configuration
# Challenge: KodeKloud 100 Days of DevOps — Phase 2
# Task: Configure stlb01 as nginx LBR across all 3 app servers

# ═════════════════════════════════════════
# PHASE 1: RECON — CHECK APP SERVERS FIRST
# Run from jump host
# ═════════════════════════════════════════

# Check Apache port on all app servers (DO NOT CHANGE IT)
for host in stapp01 stapp02 stapp03; do
  echo "=== $host ==="
  ssh $host "grep -i '^Listen' /etc/httpd/conf/httpd.conf"
done

# Verify Apache is running on all servers
for host in stapp01 stapp02 stapp03; do
  echo "=== $host ==="
  ssh $host "sudo systemctl is-active httpd"
done

# Start Apache if down on any server
# ssh tony@stapp01   "sudo systemctl start httpd && sudo systemctl enable httpd"
# ssh steve@stapp02  "sudo systemctl start httpd && sudo systemctl enable httpd"
# ssh banner@stapp03 "sudo systemctl start httpd && sudo systemctl enable httpd"

# ═════════════════════════════════════════
# PHASE 2: CONFIGURE nginx LBR ON stlb01
# ssh loki@stlb01    (Password: Loki@123)
# ═════════════════════════════════════════

# STEP 1: Install nginx if not present
sudo yum install -y nginx

# STEP 2: Edit /etc/nginx/nginx.conf
# Add upstream block + server block inside existing http {} section
# Replace PORT with actual Apache port found in Phase 1
sudo vi /etc/nginx/nginx.conf

# The config to add inside http {} block:
#
# upstream nautilus_app {
#     server stapp01:PORT;
#     server stapp02:PORT;
#     server stapp03:PORT;
# }
#
# server {
#     listen       80;
#     server_name  stlb01;
#
#     location / {
#         proxy_pass         http://nautilus_app;
#         proxy_set_header   Host            $host;
#         proxy_set_header   X-Real-IP       $remote_addr;
#         proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
#     }
# }

# STEP 3: Validate config — always before start
sudo nginx -t
# Expected: syntax is ok / test is successful

# STEP 4: Start and enable nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# STEP 5: Verify listening on port 80
sudo ss -tlnp | grep :80

# ═════════════════════════════════════════
# PHASE 3: VERIFICATION FROM JUMP HOST
# ═════════════════════════════════════════
curl http://stlb01:80
# Expected: HTML response from one of the app servers

# Confirm round-robin distribution
for i in {1..6}; do
  echo -n "Request $i: "
  curl -s -o /dev/null -w "HTTP %{http_code}\n" http://stlb01:80
done

# ─────────────────────────────────────────
# DEBUGGING
# ─────────────────────────────────────────
# sudo nginx -T                          # Dump full parsed config
# sudo tail -f /var/log/nginx/error.log
# sudo tail -f /var/log/nginx/access.log
# sudo journalctl -u nginx -n 30 --no-pager
