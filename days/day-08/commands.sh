#!/bin/bash
# Day 08 — Install Ansible 4.10.0 Globally via pip3
# Challenge: KodeKloud 100 Days of DevOps
# Task: Install ansible==4.10.0 on jump host, globally accessible to all users

# ─────────────────────────────────────────
# STEP 1: Verify pip3 is available
# ─────────────────────────────────────────
pip3 --version
# Expected: pip 21.x.x from /usr/lib/... (python 3.x)

# ─────────────────────────────────────────
# STEP 2: Install Ansible 4.10.0 globally
# sudo = installs to /usr/local/bin (global)
# Without sudo = installs to ~/.local/bin (user-only)
# ─────────────────────────────────────────
sudo pip3 install ansible==4.10.0

# ─────────────────────────────────────────
# STEP 3: Verify binary is in global path
# ─────────────────────────────────────────
which ansible
# Expected: /usr/local/bin/ansible

# ─────────────────────────────────────────
# STEP 4: Check installed version
# ─────────────────────────────────────────
ansible --version
# Note: shows ansible-core version (2.11.x) — this is correct
# ansible 4.10.0 bundles ansible-core 2.11.x internally

# ─────────────────────────────────────────
# STEP 5: Confirm global accessibility
# ─────────────────────────────────────────
ls -l /usr/local/bin/ansible
su - tony -c "ansible --version"

# ─────────────────────────────────────────
# BONUS: pip3 reference commands
# ─────────────────────────────────────────
pip3 list | grep ansible        # List ansible packages installed
pip3 show ansible               # Show package metadata and location
ansible localhost -m ping       # Quick connectivity test
ansible-config dump --only-changed  # View active config overrides
