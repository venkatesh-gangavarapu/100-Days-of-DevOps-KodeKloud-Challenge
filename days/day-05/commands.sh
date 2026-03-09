#!/bin/bash
# Day 05 — SELinux Installation & Permanent Disable
# Challenge: KodeKloud 100 Days of DevOps
# Task: Install SELinux packages and permanently disable on App Server 3

# ─────────────────────────────────────────
# STEP 1: SSH into App Server 3
# ─────────────────────────────────────────
# ssh banner@stapp03

# ─────────────────────────────────────────
# STEP 2: Install SELinux packages
# ─────────────────────────────────────────
sudo yum install -y selinux-policy selinux-policy-targeted \
  libselinux libselinux-utils policycoreutils

# ─────────────────────────────────────────
# STEP 3: Check current SELinux status (awareness only)
# ─────────────────────────────────────────
sestatus
getenforce
# Note: Runtime state doesn't matter for this task

# ─────────────────────────────────────────
# STEP 4: Permanently disable in config file
# ─────────────────────────────────────────
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

# ─────────────────────────────────────────
# STEP 5: Verify the change
# ─────────────────────────────────────────
grep "^SELINUX=" /etc/selinux/config
# Expected: SELINUX=disabled

# ─────────────────────────────────────────
# STEP 6: View full config to confirm
# ─────────────────────────────────────────
cat /etc/selinux/config
# Expected: SELINUX=disabled | SELINUXTYPE=targeted

# ─────────────────────────────────────────
# IMPORTANT: Do NOT use these for permanent changes
# ─────────────────────────────────────────
# sudo setenforce 0  ← runtime only, resets on reboot
# sudo setenforce 1  ← runtime only, resets on reboot

# ─────────────────────────────────────────
# BONUS: After tonight's reboot, verify with:
# ─────────────────────────────────────────
# sestatus
# getenforce
# Expected: Disabled
