#!/bin/bash
# Day 90 — Ansible ACL: Per-Server File + ACL Configuration
# stapp01: /opt/security/blog.txt  → group tony = r
# stapp02: /opt/security/story.txt → user steve = rw
# stapp03: /opt/security/media.txt → group banner = rw

# STEP 1: Create playbook (inventory already exists)
# cat > /home/thor/ansible/playbook.yml << 'EOF'
# [see playbook.yml]
# EOF

# STEP 2: Run playbook
# cd /home/thor/ansible
# ansible-playbook -i inventory playbook.yml

# STEP 3: Verify ACLs
# ansible stapp01 -i inventory -m shell -a "getfacl /opt/security/blog.txt" --become
# ansible stapp02 -i inventory -m shell -a "getfacl /opt/security/story.txt" --become
# ansible stapp03 -i inventory -m shell -a "getfacl /opt/security/media.txt" --become

# Expected stapp01: group:tony:r--
# Expected stapp02: user:steve:rw-
# Expected stapp03: group:banner:rw-

# ACL SUMMARY TABLE
# Server  | File       | Entity | etype | Permissions
# stapp01 | blog.txt   | tony   | group | r
# stapp02 | story.txt  | steve  | user  | rw
# stapp03 | media.txt  | banner | group | rw
