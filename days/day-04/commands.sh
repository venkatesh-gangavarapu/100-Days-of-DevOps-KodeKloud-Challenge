#!/bin/bash
# Day 04 — Grant Executable Permissions to Bash Script
# Challenge: KodeKloud 100 Days of DevOps
# Task: Grant execute permissions to /tmp/xfusioncorp.sh for all users on App Server 2

# ─────────────────────────────────────────
# STEP 1: SSH into App Server 2
# ─────────────────────────────────────────
# ssh steve@stapp02

# ─────────────────────────────────────────
# STEP 2: Check current permissions
# ─────────────────────────────────────────
ls -l /tmp/xfusioncorp.sh
# Output: -rw-r--r-- 1 root root 35 /tmp/xfusioncorp.sh
# No execute bit — not runnable by anyone

# ─────────────────────────────────────────
# STEP 3a: Grant execute to all (symbolic)
# ─────────────────────────────────────────
sudo chmod +x /tmp/xfusioncorp.sh

# STEP 3b: OR use octal (explicit, preferred in prod)
# sudo chmod 755 /tmp/xfusioncorp.sh

# ─────────────────────────────────────────
# STEP 4: Verify permissions changed
# ─────────────────────────────────────────
ls -l /tmp/xfusioncorp.sh
# Output: -rwxr-xr-x 1 root root 35 /tmp/xfusioncorp.sh

# ─────────────────────────────────────────
# STEP 5: Confirm script executes
# ─────────────────────────────────────────
bash /tmp/xfusioncorp.sh

# ─────────────────────────────────────────
# BONUS: Check permissions in octal format
# ─────────────────────────────────────────
stat -c "%a %n" /tmp/xfusioncorp.sh
# Output: 755 /tmp/xfusioncorp.sh

# ─────────────────────────────────────────
# PERMISSION REFERENCE
# ─────────────────────────────────────────
# chmod 755 = rwxr-xr-x (owner full, group/others read+execute)
# chmod 644 = rw-r--r--  (owner read/write, group/others read only)
# chmod 600 = rw-------  (owner read/write only — private files)
# chmod 777 = rwxrwxrwx  (everyone full — avoid in production)
