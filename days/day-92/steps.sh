#!/bin/bash
# Day 92 — Ansible Roles + Jinja2 Templates
# App Server 2: stapp02, steve, Am3ric@
# Permissions: 0755

# Context from actual lab:
# playbook.yml has hosts: empty — just fill in stapp02
# templates/ directory already exists in role/httpd/
# inventory uses ansible_ssh_pass (not ansible_password)

# STEP 1: Check existing tasks/main.yml
# cat ~/ansible/role/httpd/tasks/main.yml

# STEP 2: Update playbook.yml (fill in hosts: stapp02)
# cat > ~/ansible/playbook.yml << 'EOF'
# ---
# - hosts: stapp02
#   become: yes
#   become_user: root
#   roles:
#     - role/httpd
# EOF

# STEP 3: Create Jinja2 template
# cat > ~/ansible/role/httpd/templates/index.html.j2 << 'EOF'
# This file was created using Ansible on {{ inventory_hostname }}
# EOF

# STEP 4: APPEND template task to tasks/main.yml
# cat >> ~/ansible/role/httpd/tasks/main.yml << 'EOF'
#
# - name: Deploy index.html from Jinja2 template
#   template:
#     src: index.html.j2
#     dest: /var/www/html/index.html
#     owner: "{{ ansible_user }}"
#     group: "{{ ansible_user }}"
#     mode: '0755'
# EOF

# STEP 5: Verify files
# cat ~/ansible/playbook.yml
# cat ~/ansible/role/httpd/templates/index.html.j2
# cat ~/ansible/role/httpd/tasks/main.yml

# STEP 6: Run
# cd ~/ansible
# ansible-playbook -i inventory playbook.yml

# STEP 7: Verify
# ansible stapp02 -i inventory -m shell \
#   -a "cat /var/www/html/index.html && ls -la /var/www/html/index.html"
# Expected:
#   This file was created using Ansible on stapp02
#   -rwxr-xr-x 1 steve steve ... /var/www/html/index.html ✅
