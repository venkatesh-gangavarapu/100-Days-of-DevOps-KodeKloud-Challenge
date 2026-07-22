#!/bin/bash
# Day 82 — Ansible Inventory File Creation
# Challenge: KodeKloud 100 Days of DevOps — Phase 6
# Task: Create /home/thor/playbook/inventory for App Server 1 (stapp03)

# ─────────────────────────────────────────
# STEP 1: Verify stapp03 IP on jump host
# ─────────────────────────────────────────
# cat /etc/hosts | grep stapp03
# OR
# getent hosts stapp03
# Expected: 172.16.238.12  stapp03

# ─────────────────────────────────────────
# STEP 2: Check what playbook.yml expects
# ─────────────────────────────────────────
# cat /home/thor/playbook/playbook.yml
# Note the hosts: value — use matching group or 'all'

# ─────────────────────────────────────────
# STEP 3: Create inventory file
# ─────────────────────────────────────────
# cat > /home/thor/playbook/inventory << 'EOF'
# [all]
# stapp03 ansible_host=172.16.238.12 ansible_user=banner ansible_password=BigGr33n ansible_ssh_common_args='-o StrictHostKeyChecking=no'
# EOF

# ─────────────────────────────────────────
# STEP 4: Verify inventory syntax
# ─────────────────────────────────────────
# ansible-inventory -i /home/thor/playbook/inventory --list
# ansible all -i /home/thor/playbook/inventory -m ping

# ─────────────────────────────────────────
# STEP 5: Test the playbook
# ─────────────────────────────────────────
# cd /home/thor/playbook
# ansible-playbook -i inventory playbook.yml

# ─────────────────────────────────────────
# STRATOS DC REFERENCE
# ─────────────────────────────────────────
# stapp03: banner    / BigGr33n    / 172.16.238.12
# stapp02: steve   / Am3ric@    / 172.16.238.11
# stapp03: banner  / BigGr33n   / 172.16.238.12
# stdb01:  peter   / Sp!dy      / 172.16.239.10
# ststor01: natasha / Bl@kW     / 172.16.238.15
# stlb01:  loki    / Loki@123   / 172.16.238.14
