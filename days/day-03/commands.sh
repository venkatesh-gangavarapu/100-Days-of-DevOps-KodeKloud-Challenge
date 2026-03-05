#!/bin/bash
# Day 03 — Disable Direct SSH Root Login (Security Hardening)
# Challenge: KodeKloud 100 Days of DevOps
# Task: Disable root SSH login on all 3 App Servers in Stratos Datacenter

# ─────────────────────────────────────────
# SERVERS TO HARDEN
# stapp01 → ssh tony@stapp01    (Ir0nM@n)
# stapp02 → ssh steve@stapp02   (Am3ric@)
# stapp03 → ssh banner@stapp03  (BigGr33n)
# ─────────────────────────────────────────

# ─────────────────────────────────────────
# STEP 1: SSH into each server
# ─────────────────────────────────────────
# ssh tony@stapp01

# ─────────────────────────────────────────
# STEP 2: Disable PermitRootLogin via sed
# ─────────────────────────────────────────
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# ─────────────────────────────────────────
# STEP 3: Verify the change
# ─────────────────────────────────────────
grep "PermitRootLogin" /etc/ssh/sshd_config
# Expected: PermitRootLogin no

# ─────────────────────────────────────────
# STEP 4: Check config syntax before restart (SAFE PRACTICE)
# ─────────────────────────────────────────
sudo sshd -t
# No output = no errors = safe to restart

# ─────────────────────────────────────────
# STEP 5: Restart SSH daemon
# ─────────────────────────────────────────
sudo systemctl restart sshd

# ─────────────────────────────────────────
# STEP 6: Verify SSH service is healthy
# ─────────────────────────────────────────
sudo systemctl status sshd

# ─────────────────────────────────────────
# STEP 7: Confirm root login is blocked
# ─────────────────────────────────────────
# ssh root@stapp01
# Expected: Permission denied, please try again.

# ─────────────────────────────────────────
# BONUS: Watch SSH auth logs in real-time
# ─────────────────────────────────────────
sudo tail -f /var/log/secure

# ─────────────────────────────────────────
# REPEAT ABOVE FOR stapp02 AND stapp03
# ─────────────────────────────────────────
