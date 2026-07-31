#!/bin/bash
# Day 91 — Ansible: httpd + copy + lineinfile (insertbefore: BOF)
# Note: inventory already exists at /home/thor/ansible/inventory

# STEP 1: Create playbook
# cat > /home/thor/ansible/playbook.yml << 'EOF'
# [see playbook.yml]
# EOF

# STEP 2: Run
# cd /home/thor/ansible
# ansible-playbook -i inventory playbook.yml

# STEP 3: Verify
# ansible all -i inventory -m shell -a "cat /var/www/html/index.html"
# Expected:
#   Welcome to Nautilus Group!          ← lineinfile at top
#   This is a Nautilus sample file, created using Ansible!  ← initial content

# ansible all -i inventory -m shell -a "ls -la /var/www/html/index.html"
# Expected: -rw-r--r-- 1 apache apache ... /var/www/html/index.html

# KEY POINTS:
# - insertbefore: BOF = Beginning Of File (adds line to top)
# - insertafter: EOF  = End Of File (adds line to bottom)
# - copy: content: "..." creates file with exact string content
# - lineinfile is idempotent — won't add duplicate lines
