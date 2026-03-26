#!/bin/bash
# Day 19 — Apache Multi-Directory Hosting on Port 5002
# Challenge: KodeKloud 100 Days of DevOps — Phase 2
# Task: Install httpd on stapp03, serve /blog/ and /apps/ on port 5002

# ═════════════════════════════════════════
# PHASE 1: JUMP HOST — Transfer files to stapp03
# Run as thor on jump host
# ═════════════════════════════════════════
scp -r /home/thor/blog banner@stapp03:/tmp/
scp -r /home/thor/apps banner@stapp03:/tmp/

# ═════════════════════════════════════════
# PHASE 2: APP SERVER 3
# ssh banner@stapp03    (Password: BigGr33n)
# ═════════════════════════════════════════

# STEP 1: Install Apache
sudo yum install -y httpd

# STEP 2: Copy website files to document root
sudo cp -r /tmp/blog /var/www/html/
sudo cp -r /tmp/apps /var/www/html/

# STEP 3: Set correct ownership and permissions
sudo chown -R apache:apache /var/www/html/blog /var/www/html/apps
sudo chmod -R 755 /var/www/html/blog /var/www/html/apps

# STEP 4: Fix SELinux context on copied files
# Files from /tmp carry tmp_t label — Apache can't serve them
sudo restorecon -Rv /var/www/html/

# STEP 5: Change Apache port to 5002
sudo sed -i 's/^Listen.*/Listen 5002/' /etc/httpd/conf/httpd.conf

# Verify port change
grep "^Listen" /etc/httpd/conf/httpd.conf
# Expected: Listen 5002

# STEP 6: Allow port 5002 in SELinux
sudo semanage port -a -t http_port_t -p tcp 5002
# Install semanage if missing:
# sudo yum install -y policycoreutils-python-utils

# Verify SELinux port
sudo semanage port -l | grep http_port_t
# Expected: http_port_t tcp 5002, 80, 81, 443, ...

# STEP 7: Validate config syntax
sudo httpd -t
# Expected: Syntax OK

# STEP 8: Start and enable Apache
sudo systemctl start httpd
sudo systemctl enable httpd

# STEP 9: Verify service and port binding
sudo systemctl status httpd
sudo ss -tlnp | grep 5002
# Expected: httpd listening on 5002

# ═════════════════════════════════════════
# STEP 10: TEST BOTH PATHS
# ═════════════════════════════════════════
curl http://localhost:5002/blog/
# Expected: HTML content from blog site

curl http://localhost:5002/apps/
# Expected: HTML content from apps site

# ─────────────────────────────────────────
# DEBUGGING (if 403 Forbidden)
# ─────────────────────────────────────────
# Check SELinux labels
ls -laZ /var/www/html/blog/
ls -laZ /var/www/html/apps/
# Should show: httpd_sys_content_t

# Check error log
sudo tail -20 /var/log/httpd/error_log
