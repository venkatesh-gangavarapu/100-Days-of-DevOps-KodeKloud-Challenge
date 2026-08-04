#!/bin/bash
# Day 93 — Ansible when Conditionals: Copy Files Per Server
# Uses ansible_nodename fact to target specific files to specific servers

# STEP 1: Verify source files exist on jump host
# ls /usr/src/finance/
# Expected: blog.txt  story.txt  media.txt

# STEP 2: Create playbook
# cat > /home/thor/ansible/playbook.yml << 'EOF'
# [see playbook.yml]
# EOF

# STEP 3: Run
# cd /home/thor/ansible
# ansible-playbook -i inventory playbook.yml

# STEP 4: Verify
# ansible stapp01 -i inventory -m shell -a "ls -la /opt/finance/blog.txt" --become
# ansible stapp02 -i inventory -m shell -a "ls -la /opt/finance/story.txt" --become
# ansible stapp03 -i inventory -m shell -a "ls -la /opt/finance/media.txt" --become

# Expected:
# stapp01: -rwxrwxrwx 1 tony   tony   ... /opt/finance/blog.txt
# stapp02: -rwxrwxrwx 1 steve  steve  ... /opt/finance/story.txt
# stapp03: -rwxrwxrwx 1 banner banner ... /opt/finance/media.txt

# WHEN CONDITIONAL TABLE:
# ansible_nodename == 'stapp01' → copy blog.txt,  owner: tony
# ansible_nodename == 'stapp02' → copy story.txt, owner: steve
# ansible_nodename == 'stapp03' → copy media.txt, owner: banner
