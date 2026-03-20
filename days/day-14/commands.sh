#!/bin/bash
# Day 14 — Fleet Apache Troubleshooting & Port 3002 Configuration
# Challenge: KodeKloud 100 Days of DevOps
# Task: Find faulty Apache server, fix it, ensure port 3002 on all 3 app servers

# ─────────────────────────────────────────
# PHASE 1: FLEET TRIAGE FROM JUMP HOST
# Find which server has Apache down
# ─────────────────────────────────────────
for host in stapp01 stapp02 stapp03; do
  echo "=== $host ==="
  ssh $host "sudo systemctl status httpd --no-pager | grep -E 'Active|running|failed'"
done

# ─────────────────────────────────────────
# PHASE 2: FIX EACH SERVER
# Run on stapp01 (tony), stapp02 (steve), stapp03 (banner)
# ─────────────────────────────────────────

# STEP 1: SSH into server
# ssh tony@stapp01

# STEP 2: Check current Listen port
grep -i "^Listen" /etc/httpd/conf/httpd.conf

# STEP 3: Set Listen to 3002
sudo sed -i 's/^Listen.*/Listen 3002/' /etc/httpd/conf/httpd.conf

# Verify
grep -i "^Listen" /etc/httpd/conf/httpd.conf
# Expected: Listen 3002

# STEP 4: Allow port 3002 in SELinux (if enforcing)
getenforce
sudo semanage port -l | grep http_port_t
# If 3002 not listed:
sudo semanage port -a -t http_port_t -p tcp 3002
# Install semanage if needed:
# sudo yum install -y policycoreutils-python-utils

# STEP 5: Validate config syntax — always before restart
sudo httpd -t
# Expected: Syntax OK

# STEP 6: Start and enable Apache
sudo systemctl start httpd
sudo systemctl enable httpd

# STEP 7: Verify service and port
sudo systemctl status httpd
sudo ss -tlnp | grep 3002
# Expected: httpd listening on 3002

# ─────────────────────────────────────────
# PHASE 3: FLEET VERIFICATION FROM JUMP HOST
# ─────────────────────────────────────────

# Check service active + port bound on all servers
for host in stapp01 stapp02 stapp03; do
  echo "=== $host ==="
  ssh $host "sudo systemctl is-active httpd && sudo ss -tlnp | grep 3002"
done

# Test HTTP response from jump host
for host in stapp01 stapp02 stapp03; do
  echo -n "$host: "
  curl -s -o /dev/null -w "HTTP %{http_code}\n" http://$host:3002
done
# Expected: HTTP 200 or HTTP 403 (both confirm Apache is responding)
