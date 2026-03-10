#!/bin/bash
# Day 06 — Install Cronie & Schedule Cron Job
# Challenge: KodeKloud 100 Days of DevOps
# Task: Install cronie, start crond, add cron job for root on all 3 App Servers

# ─────────────────────────────────────────
# SERVERS
# stapp01 → ssh tony@stapp01    (Ir0nM@n)
# stapp02 → ssh steve@stapp02   (Am3ric@)
# stapp03 → ssh banner@stapp03  (BigGr33n)
# ─────────────────────────────────────────

# ─────────────────────────────────────────
# STEP 1: SSH into each server
# ─────────────────────────────────────────
# ssh tony@stapp01

# ─────────────────────────────────────────
# STEP 2: Install cronie package
# ─────────────────────────────────────────
sudo yum install -y cronie

# ─────────────────────────────────────────
# STEP 3: Start and enable crond service
# ─────────────────────────────────────────
sudo systemctl start crond
sudo systemctl enable crond

# ─────────────────────────────────────────
# STEP 4: Verify crond is active
# ─────────────────────────────────────────
sudo systemctl status crond

# ─────────────────────────────────────────
# STEP 5: Add cron job for root (non-interactive)
# ─────────────────────────────────────────
echo "*/5 * * * * echo hello > /tmp/cron_text" | sudo crontab -u root -

# ─────────────────────────────────────────
# STEP 6: Verify cron job is registered
# ─────────────────────────────────────────
sudo crontab -u root -l
# Expected: */5 * * * * echo hello > /tmp/cron_text

# ─────────────────────────────────────────
# STEP 7: After ~5 minutes, verify execution
# ─────────────────────────────────────────
# cat /tmp/cron_text
# Expected: hello

# ─────────────────────────────────────────
# BONUS: Debug cron if job doesn't run
# ─────────────────────────────────────────
sudo tail -f /var/log/cron

# ─────────────────────────────────────────
# REPEAT ABOVE FOR stapp02 AND stapp03
# ─────────────────────────────────────────
