#!/bin/bash
# Day 12 — Apache Unreachable on Port 6300: Diagnose & Fix
# Challenge: KodeKloud 100 Days of DevOps
# Task: Find and fix why Apache is unreachable on port 6300 on stapp01

# ─────────────────────────────────────────
# SSH into App Server 1
# ssh tony@stapp01
# ─────────────────────────────────────────

# ═════════════════════════════════════════
# LAYER 1 — Is Apache running?
# ═════════════════════════════════════════
sudo systemctl status httpd

# ═════════════════════════════════════════
# LAYER 2 — Is Apache on the right port?
# ═════════════════════════════════════════
# Check what port httpd is actually bound to
sudo ss -tlnp | grep httpd
sudo netstat -tlnp | grep httpd

# Check the Listen directive in config
grep -i "^Listen" /etc/httpd/conf/httpd.conf

# Fix if not set to 6300
sudo sed -i 's/^Listen.*/Listen 6300/' /etc/httpd/conf/httpd.conf

# Verify config syntax before restart
sudo httpd -t
# Expected: Syntax OK

# ═════════════════════════════════════════
# LAYER 3 — Is firewall allowing port 6300?
# ═════════════════════════════════════════
sudo firewall-cmd --list-all

# Open port 6300 if not present
sudo firewall-cmd --permanent --add-port=6300/tcp
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-ports
# Expected: 6300/tcp

# ═════════════════════════════════════════
# LAYER 4 — Is SELinux allowing port 6300?
# ═════════════════════════════════════════
sudo semanage port -l | grep http_port_t
# 6300 will NOT be listed by default

# Install semanage if missing
# sudo yum install -y policycoreutils-python-utils

# Add 6300 to allowed HTTP ports
sudo semanage port -a -t http_port_t -p tcp 6300

# Verify
sudo semanage port -l | grep http_port_t
# Expected: http_port_t tcp 6300, 80, 81, 443, ...

# ═════════════════════════════════════════
# START & ENABLE APACHE
# ═════════════════════════════════════════
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl status httpd

# ═════════════════════════════════════════
# VERIFY — Port bound + service reachable
# ═════════════════════════════════════════
sudo ss -tlnp | grep 6300
# Expected: httpd listening on 6300

# From jump host:
curl http://stapp01:6300
# Expected: HTML response ✅
