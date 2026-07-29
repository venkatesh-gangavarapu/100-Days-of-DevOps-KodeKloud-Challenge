#!/bin/bash
# Day 89 — Ansible: Install + Enable vsftpd on All App Servers
# Note: inventory already exists at /home/thor/ansible/inventory

# STEP 1: Create playbook
# cat > /home/thor/ansible/playbook.yml << 'EOF'
# ---
# - name: Install and enable vsftpd on all app servers
#   hosts: all
#   become: yes
#   tasks:
#     - name: Install vsftpd
#       yum:
#         name: vsftpd
#         state: present
#
#     - name: Start and enable vsftpd service
#       service:
#         name: vsftpd
#         state: started
#         enabled: yes
# EOF

# STEP 2: Check inventory
# cat /home/thor/ansible/inventory

# STEP 3: Run playbook
# cd /home/thor/ansible
# ansible-playbook -i inventory playbook.yml
# Expected: all 3 servers ok=3 changed=2 failed=0

# STEP 4: Verify
# ansible all -i /home/thor/ansible/inventory -m shell -a "systemctl status vsftpd | grep Active"
# ansible all -i /home/thor/ansible/inventory -m shell -a "rpm -q vsftpd"
