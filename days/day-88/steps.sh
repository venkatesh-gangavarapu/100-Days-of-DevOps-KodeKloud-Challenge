#!/bin/bash
# Day 88 — Ansible: Install httpd + blockinfile index.html
# Note: inventory already exists at /home/thor/ansible/inventory
# Just create the playbook

# STEP 1: Create playbook
# cat > /home/thor/ansible/playbook.yml << 'EOF'
# ---
# - name: Install and configure httpd on all app servers
#   hosts: all
#   become: yes
#   tasks:
#     - name: Install httpd
#       yum:
#         name: httpd
#         state: present
#
#     - name: Start and enable httpd service
#       service:
#         name: httpd
#         state: started
#         enabled: yes
#
#     - name: Add content to index.html using blockinfile
#       blockinfile:
#         path: /var/www/html/index.html
#         create: yes
#         block: |
#           Welcome to XfusionCorp!
#           This is Nautilus sample file, created using Ansible!
#           Please do not modify this file manually!
#         owner: apache
#         group: apache
#         mode: '0755'
# EOF

# STEP 2: Check inventory
# cat /home/thor/ansible/inventory

# STEP 3: Run playbook
# cd /home/thor/ansible
# ansible-playbook -i inventory playbook.yml

# STEP 4: Verify
# ansible all -i /home/thor/ansible/inventory -m shell -a "curl -s http://localhost/"
# ansible all -i /home/thor/ansible/inventory -m shell -a "ls -la /var/www/html/index.html"
# ansible all -i /home/thor/ansible/inventory -m shell -a "systemctl status httpd | grep Active"
