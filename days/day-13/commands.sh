#!/bin/bash
# Day 13 — iptables Installation & Port 6000 LBR Whitelist
# Challenge: KodeKloud 100 Days of DevOps
# Task: Install iptables, block port 6000 for all except LBR (172.16.238.14)
#       on all 3 app servers. Rules must persist across reboots.

# ─────────────────────────────────────────
# INFRASTRUCTURE
# LBR:    stlb01  → 172.16.238.14
# stapp01 → ssh tony@stapp01    (Ir0nM@n)
# stapp02 → ssh steve@stapp02   (Am3ric@)
# stapp03 → ssh banner@stapp03  (BigGr33n)
# ─────────────────────────────────────────

# ─────────────────────────────────────────
# STEP 1: Install iptables and services
# ─────────────────────────────────────────
sudo yum install -y iptables iptables-services

# ─────────────────────────────────────────
# STEP 2: Start and enable iptables service
# ─────────────────────────────────────────
sudo systemctl start iptables
sudo systemctl enable iptables

# ─────────────────────────────────────────
# STEP 3: Check existing rules (baseline)
# ─────────────────────────────────────────
sudo iptables -L INPUT -n --line-numbers

# ─────────────────────────────────────────
# STEP 4: Add rules — ORDER CRITICAL
# ACCEPT for LBR must come before DROP for all
# ─────────────────────────────────────────

# Rule 1: INSERT ACCEPT for LBR at top (line 1)
sudo iptables -I INPUT -p tcp --dport 6000 -s 172.16.238.14 -j ACCEPT

# Rule 2: APPEND DROP for everyone else at bottom
sudo iptables -A INPUT -p tcp --dport 6000 -j DROP

# ─────────────────────────────────────────
# STEP 5: Verify rule order
# ACCEPT must be above DROP
# ─────────────────────────────────────────
sudo iptables -L INPUT -n --line-numbers
# Expected:
# 1  ACCEPT  tcp  --  172.16.238.14  0.0.0.0/0  tcp dpt:6000
# 2  DROP    tcp  --  0.0.0.0/0      0.0.0.0/0  tcp dpt:6000

# ─────────────────────────────────────────
# STEP 6: Persist rules across reboots
# ─────────────────────────────────────────
sudo iptables-save | sudo tee /etc/sysconfig/iptables
# Saved to: /etc/sysconfig/iptables

# Verify persistence file
sudo grep 6000 /etc/sysconfig/iptables

# ─────────────────────────────────────────
# STEP 7: Confirm rules survive service restart
# ─────────────────────────────────────────
sudo systemctl restart iptables
sudo iptables -L INPUT -n --line-numbers

# ─────────────────────────────────────────
# REPEAT ABOVE ON stapp02 AND stapp03
# ─────────────────────────────────────────

# ─────────────────────────────────────────
# VERIFICATION TESTS
# ─────────────────────────────────────────
# From LBR host (stlb01) — should SUCCEED
# curl http://stapp01:6000

# From jump host — should be BLOCKED (timeout)
# curl --connect-timeout 5 http://stapp01:6000
