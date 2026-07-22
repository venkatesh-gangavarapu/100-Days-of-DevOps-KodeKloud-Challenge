# Day 82 — Ansible Inventory File: Connecting to App Server 1

**Challenge Platform:** KodeKloud — 100 Days of DevOps
**Category:** Ansible / Inventory
**Phase:** Phase 6
**Status:** Completed

## Task Summary

Create INI-format Ansible inventory at /home/thor/playbook/inventory for stapp01.

## The Inventory File

[all]
stapp01 ansible_host=172.16.238.10 ansible_user=tony ansible_password=Ir0nM@n ansible_ssh_common_args='-o StrictHostKeyChecking=no'

## How to Create

cat > /home/thor/playbook/inventory << 'EOF'
[all]
stapp01 ansible_host=172.16.238.10 ansible_user=tony ansible_password=Ir0nM@n ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

## Verify

ansible all -i /home/thor/playbook/inventory -m ping
cd /home/thor/playbook
ansible-playbook -i inventory playbook.yml

## Stratos DC Reference

stapp01: tony / Ir0nM@n / 172.16.238.10
stapp02: steve / Am3ric@ / 172.16.238.11
stapp03: banner / BigGr33n / 172.16.238.12

*Part of my 100 Days of DevOps Challenge*
