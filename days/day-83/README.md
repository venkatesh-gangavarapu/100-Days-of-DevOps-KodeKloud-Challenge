# Day 83 — Ansible Playbook: Create Empty File on App Server 2

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Ansible / Inventory / Playbook  
**Difficulty:** Beginner  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

1. Update `/home/thor/ansible/inventory` to target **App Server 2** (`stapp02`)
2. Create `/home/thor/ansible/playbook.yml` with a task to create `/tmp/file.txt`
3. Run with `ansible-playbook -i inventory playbook.yml` — no extra arguments

---

## 🧠 Concept — Ansible `file` Module

The `file` module manages file and directory properties. `state: touch` creates an empty file if it doesn't exist, or updates its timestamp if it does — identical to the Linux `touch` command but idempotent.

```yaml
- name: Create /tmp/file.txt
  file:
    path: /tmp/file.txt
    state: touch
```

| `state` value | Effect |
|--------------|--------|
| `touch` | Create empty file (or update timestamp) |
| `absent` | Delete file/directory |
| `directory` | Create directory |
| `file` | Assert file exists (fail if not) |
| `link` | Create symlink |

---

## 🔧 The Files

### inventory

```ini
[all]
stapp02 ansible_host=172.16.238.11 ansible_user=steve ansible_password=Am3ric@ ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

**Note:** Original inventory had `stapp03` with `ansible_ssh_pass` (old variable name). Updated to `stapp02` and used the current `ansible_password` variable.

### playbook.yml

```yaml
---
- name: Create empty file on App Server 2
  hosts: all
  become: yes
  tasks:
    - name: Create /tmp/file.txt
      file:
        path: /tmp/file.txt
        state: touch
```

---

## 🔧 Commands on Jump Host

```bash
# Update inventory
cat > /home/thor/ansible/inventory << 'EOF'
[all]
stapp02 ansible_host=172.16.238.11 ansible_user=steve ansible_password=Am3ric@ ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

# Create playbook
cat > /home/thor/ansible/playbook.yml << 'EOF'
---
- name: Create empty file on App Server 2
  hosts: all
  become: yes
  tasks:
    - name: Create /tmp/file.txt
      file:
        path: /tmp/file.txt
        state: touch
EOF

# Test connectivity
ansible all -i /home/thor/ansible/inventory -m ping

# Run playbook
cd /home/thor/ansible
ansible-playbook -i inventory playbook.yml
```

**Expected output:**
```
PLAY RECAP
stapp02 : ok=2  changed=1  unreachable=0  failed=0  ✅
```

**Verify file was created:**
```bash
ansible all -i /home/thor/ansible/inventory -m shell -a "ls -la /tmp/file.txt"
```

---

## 📌 Stratos DC Reference

| Server | Hostname | User | Password | IP |
|--------|----------|------|----------|----|
| App Server 1 | `stapp01` | tony | Ir0nM@n | 172.16.238.10 |
| App Server 2 | `stapp02` | steve | Am3ric@ | 172.16.238.11 |
| App Server 3 | `stapp03` | banner | BigGr33n | 172.16.238.12 |

---

## ⚠️ Common Mistakes to Avoid

1. **`ansible_ssh_pass` vs `ansible_password`** — `ansible_ssh_pass` is the old name, still works but deprecated. Use `ansible_password` in new inventories.
2. **`hosts: all` vs specific group** — With one host in `[all]`, both `hosts: all` and `hosts: stapp02` work. Always check the playbook's `hosts:` value matches your inventory.
3. **Missing `become: yes`** — While `/tmp` is writable by all users, tasks in other directories need privilege escalation. `become: yes` is good practice.
4. **`state: touch` vs `state: file`** — `touch` creates if missing. `file` asserts existence and fails if the file isn't there. For creation tasks, always use `touch`.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer.

---

**Q1: What is the Ansible `file` module and when do you use it?**

The `file` module manages filesystem objects — files, directories, symlinks, and their attributes (owner, group, permissions). Use `state: touch` to create empty files or update timestamps, `state: directory` to create directories, `state: absent` to delete, `state: link` for symlinks. It's idempotent: running `state: touch` on an existing file just updates the timestamp without error, and running `state: directory` on an existing directory does nothing. For creating files with content, use the `copy` or `template` modules instead.

---

**Q2: What is the difference between `ansible_password` and `ansible_ssh_pass`?**

Both are inventory variables for SSH password authentication. `ansible_ssh_pass` is the legacy name from older Ansible versions (pre-2.0). `ansible_password` is the current official name introduced to normalize variable naming across connection types. In modern Ansible, `ansible_password` is preferred — it works for SSH, WinRM, and other connection types with the same variable. `ansible_ssh_pass` still works as an alias for backward compatibility but may be removed in future versions. Always use `ansible_password` in new inventory files.

---

**Q3: Why use the `file` module instead of a `shell: touch /tmp/file.txt` task?**

The `file` module is idempotent — it reports `changed` only when the state actually changed (file created for the first time). `shell: touch /tmp/file.txt` always reports `changed` even when the file already exists, because Ansible can't know whether the shell command had any effect. Idempotency matters in Ansible because: (1) playbooks are run repeatedly, and unnecessary `changed` status is misleading. (2) Handlers (services to restart, notifications to send) only trigger on `changed` — false positives cause unnecessary restarts. (3) Dry-run mode (`--check`) works correctly with modules but not with shell commands.

---

**Q4: What does `become: yes` do in an Ansible playbook?**

`become: yes` enables privilege escalation — by default it uses `sudo` to run tasks as root. Without it, tasks run as the connecting user (`steve` in this case). `become` is needed for: installing packages (`yum`, `apt`), managing system services (`systemctl`), writing to system directories (`/etc/`, `/var/`), and changing file ownership. For `/tmp/file.txt` specifically, `become` isn't strictly required since `/tmp` is world-writable, but it's good practice and ensures the playbook works for tasks that do need elevated privileges.

---

**Q5: How would you extend this playbook to set specific permissions on the created file?**

```yaml
- name: Create /tmp/file.txt with permissions
  file:
    path: /tmp/file.txt
    state: touch
    owner: steve
    group: steve
    mode: '0644'
```

The `file` module handles all file attributes in one task. `mode: '0644'` sets read-write for owner, read-only for group and others. Always quote the mode value to prevent YAML from interpreting it as an octal number. `owner` and `group` set file ownership — requires `become: yes` if the current user doesn't own the file.

---

## 🔗 References

- [Ansible `file` Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/file_module.html)
- [Ansible Inventory Variables](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html#connecting-to-hosts-behavioral-inventory-parameters)
- [Ansible Privilege Escalation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_privilege_escalation.html)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
