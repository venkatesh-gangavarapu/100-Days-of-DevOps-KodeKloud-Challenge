# Day 88 — Ansible: httpd Setup + blockinfile Web Page Deployment

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Ansible / Service Management / blockinfile  
**Difficulty:** Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

1. Install `httpd` on all app servers
2. Start and enable the httpd service
3. Add content to `/var/www/html/index.html` using `blockinfile` (default markers)
4. Set owner/group to `apache`, permissions to `0755`

**Content to add:**
```
Welcome to XfusionCorp!
This is Nautilus sample file, created using Ansible!
Please do not modify this file manually!
```

---

## 🧠 Concept — `blockinfile` Module

`blockinfile` inserts a block of text into a file, surrounded by marker comments that identify the managed block. On subsequent runs it updates the block rather than appending again — making it idempotent.

### Default Markers (REQUIRED — do NOT customize)

The task explicitly says "do not use any custom or empty marker." The default markers are:
```
# BEGIN ANSIBLE MANAGED BLOCK
Welcome to XfusionCorp!
This is Nautilus sample file, created using Ansible!
Please do not modify this file manually!
# END ANSIBLE MANAGED BLOCK
```

These are added automatically — no `marker:` parameter needed in the task.

### Key `blockinfile` Parameters Used

| Parameter | Purpose |
|-----------|---------|
| `path` | File to modify |
| `create: yes` | Create file if it doesn't exist |
| `block` | The content to insert (use `\|` for multiline) |
| `owner` | Set file owner (combines create + chown) |
| `group` | Set file group |
| `mode` | Set file permissions |

### `service` Module — Start + Enable

```yaml
service:
  name: httpd
  state: started    # ensure running right now
  enabled: yes      # ensure starts on boot
```

`state: started` starts the service if not running (idempotent — does nothing if already running). `enabled: yes` sets it to auto-start on reboot via systemctl enable.

---

## 🔧 The Playbook

```yaml
---
- name: Install and configure httpd on all app servers
  hosts: all
  become: yes
  tasks:
    - name: Install httpd
      yum:
        name: httpd
        state: present

    - name: Start and enable httpd service
      service:
        name: httpd
        state: started
        enabled: yes

    - name: Add content to index.html using blockinfile
      blockinfile:
        path: /var/www/html/index.html
        create: yes
        block: |
          Welcome to XfusionCorp!
          This is Nautilus sample file, created using Ansible!
          Please do not modify this file manually!
        owner: apache
        group: apache
        mode: '0755'
```

---

## 🔧 Commands on Jump Host

```bash
# Inventory already exists — just create the playbook
cat > /home/thor/ansible/playbook.yml << 'YAML'
[paste playbook content]
YAML

# Check inventory
cat /home/thor/ansible/inventory

# Run
cd /home/thor/ansible
ansible-playbook -i inventory playbook.yml

# Verify
ansible all -i inventory -m shell -a "curl -s http://localhost/"
ansible all -i inventory -m shell -a "ls -la /var/www/html/index.html"
ansible all -i inventory -m shell -a "systemctl status httpd | grep Active"
```

**Expected result from curl:**
```
# BEGIN ANSIBLE MANAGED BLOCK
Welcome to XfusionCorp!
This is Nautilus sample file, created using Ansible!
Please do not modify this file manually!
# END ANSIBLE MANAGED BLOCK
```

---

## ⚠️ Common Mistakes

1. **Setting `marker:` to empty or custom** — Task says "do not use any custom or empty marker." Omit `marker:` entirely to use the default `# BEGIN/END ANSIBLE MANAGED BLOCK`.
2. **Not using `create: yes`** — Without it, `blockinfile` fails if `/var/www/html/index.html` doesn't exist. `create: yes` creates the file if missing.
3. **Block content indentation** — The `|` YAML block scalar preserves newlines. Each line of the block must be consistently indented under `block:`. Extra indentation becomes part of the content.
4. **Missing `enabled: yes`** — `state: started` starts the service now but doesn't configure it to start on reboot. Always add `enabled: yes` for web servers.
5. **Wrong owner** — Must be `apache` (the httpd process user), not `root` or `thor`. The `apache` user/group is created when httpd is installed.

---

## 💼 Real-World DevOps Q&A

**Q1: What is the `blockinfile` module and how does it differ from `lineinfile`?**

`blockinfile` manages a multi-line block of text in a file, identified by configurable begin/end marker comments. It's idempotent: if the block already exists (identified by markers), it updates it; if missing, it inserts it. `lineinfile` manages a single line — inserting, replacing, or removing one line at a time. Use `blockinfile` for adding multi-line config blocks, HTML sections, or any chunk of content that should be managed as a unit. Use `lineinfile` for single-line changes like adding a parameter or updating a setting. Neither overwrites the entire file — they make targeted modifications.

**Q2: What does the YAML `|` (pipe) block scalar do in the `block:` parameter?**

The `|` (literal block scalar) tells YAML to preserve newlines in the following indented block. Each indented line becomes a separate line in the string, with a trailing newline. This is how multi-line content is written in YAML without escape sequences. Alternative: `>` (folded block scalar) converts newlines to spaces — wrong for file content that needs preserved line breaks. For `blockinfile`, always use `|` for multi-line content so each line is correctly preserved when written to the target file.

**Q3: How does `blockinfile` achieve idempotency with markers?**

On first run: `blockinfile` inserts the block content between `# BEGIN ANSIBLE MANAGED BLOCK` and `# END ANSIBLE MANAGED BLOCK` markers at the specified position. On subsequent runs: it finds the existing markers, compares the content between them to the desired block, and updates if different — or does nothing if identical. The markers are the "fingerprint" that lets Ansible know this block is managed. Custom markers (`marker: "# {mark} MY BLOCK"`) allow multiple independent `blockinfile` tasks on the same file without conflict. Default markers should only be used when one `blockinfile` manages the entire file's block.

**Q4: How would you verify httpd is correctly serving the content after the playbook runs?**

```bash
# Check from jump host via ansible ad-hoc
ansible all -i inventory -m shell -a "curl -s http://localhost/"

# Check service status
ansible all -i inventory -m shell -a "systemctl is-active httpd"

# Verify file content and permissions
ansible all -i inventory -m shell -a "ls -la /var/www/html/index.html && cat /var/www/html/index.html"

# Check from LBR if configured
curl http://stlb01:8091/
```

**Q5: Why set `owner: apache` instead of the SSH user (tony/steve/banner)?**

The `apache` user (created when httpd is installed) is the process user — it's what httpd runs as in production. When Apache serves files, it reads them as the `apache` user. Setting ownership to `apache:apache` means the web server process can read the file without needing world-readable permissions. Setting ownership to `tony` would require `o+r` permissions for Apache to read it, or the file would need to be world-readable. Using the service user as the owner follows least-privilege: the web server owns its content, nobody else does.

---

## 🔗 References

- [Ansible `blockinfile` Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/blockinfile_module.html)
- [Ansible `service` Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/service_module.html)
- [Ansible `yum` Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/yum_module.html)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
