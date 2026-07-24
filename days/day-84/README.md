# Day 84 — Ansible copy Module: Distributing Files Across All App Servers

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Ansible / copy Module / Multi-Host  
**Difficulty:** Beginner–Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create inventory with **all three app servers** and a playbook to copy `/usr/src/sysops/index.html` from the jump host to `/opt/sysops/` on each server.

---

## 🧠 Concept — Ansible `copy` Module

The `copy` module transfers files **from the control node** (jump host) **to managed nodes** (app servers). Unlike `synchronize` or `fetch`, `copy` is simple and one-directional: jump host → remote server.

```yaml
- name: Copy file
  copy:
    src: /usr/src/sysops/index.html    # path on jump host (control node)
    dest: /opt/sysops/index.html       # path on remote server
    mode: '0644'                        # file permissions on remote
```

### Why Create the Directory First?

The `copy` module fails if the destination directory doesn't exist. Adding a `file` task with `state: directory` before the copy ensures `/opt/sysops/` exists on all servers before the copy runs.

### Multi-Host Inventory

All three app servers in one inventory — Ansible runs tasks on all of them in parallel (up to `forks` setting, default 5):

```ini
[app_servers]
stapp01 ansible_host=172.16.238.10 ansible_user=tony ansible_password=Ir0nM@n ...
stapp02 ansible_host=172.16.238.11 ansible_user=steve ansible_password=Am3ric@ ...
stapp03 ansible_host=172.16.238.12 ansible_user=banner ansible_password=BigGr33n ...
```

`hosts: all` in the playbook targets every host in the inventory — all three servers get the file in a single playbook run.

---

## 🔧 The Files

### inventory

```ini
[app_servers]
stapp01 ansible_host=172.16.238.10 ansible_user=tony ansible_password=Ir0nM@n ansible_ssh_common_args='-o StrictHostKeyChecking=no'
stapp02 ansible_host=172.16.238.11 ansible_user=steve ansible_password=Am3ric@ ansible_ssh_common_args='-o StrictHostKeyChecking=no'
stapp03 ansible_host=172.16.238.12 ansible_user=banner ansible_password=BigGr33n ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### playbook.yml

```yaml
---
- name: Copy index.html to all app servers
  hosts: all
  become: yes
  tasks:
    - name: Create /opt/sysops directory if not present
      file:
        path: /opt/sysops
        state: directory
        mode: '0755'

    - name: Copy index.html to /opt/sysops
      copy:
        src: /usr/src/sysops/index.html
        dest: /opt/sysops/index.html
        mode: '0644'
```

---

## 🔧 Commands on Jump Host

```bash
# Verify source file
ls -la /usr/src/sysops/index.html

# Create files
cat > /home/thor/ansible/inventory << 'EOF'
[app_servers]
stapp01 ansible_host=172.16.238.10 ansible_user=tony ansible_password=Ir0nM@n ansible_ssh_common_args='-o StrictHostKeyChecking=no'
stapp02 ansible_host=172.16.238.11 ansible_user=steve ansible_password=Am3ric@ ansible_ssh_common_args='-o StrictHostKeyChecking=no'
stapp03 ansible_host=172.16.238.12 ansible_user=banner ansible_password=BigGr33n ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

cat > /home/thor/ansible/playbook.yml << 'EOF'
---
- name: Copy index.html to all app servers
  hosts: all
  become: yes
  tasks:
    - name: Create /opt/sysops directory if not present
      file:
        path: /opt/sysops
        state: directory
        mode: '0755'

    - name: Copy index.html to /opt/sysops
      copy:
        src: /usr/src/sysops/index.html
        dest: /opt/sysops/index.html
        mode: '0644'
EOF

# Run
cd /home/thor/ansible
ansible-playbook -i inventory playbook.yml
```

**Expected output:**
```
PLAY RECAP
stapp01 : ok=3  changed=2  unreachable=0  failed=0
stapp02 : ok=3  changed=2  unreachable=0  failed=0
stapp03 : ok=3  changed=2  unreachable=0  failed=0
```

**Verify on all servers:**
```bash
ansible all -i /home/thor/ansible/inventory -m shell \
  -a "ls -la /opt/sysops/index.html"
```

---

## ⚠️ Common Mistakes to Avoid

1. **Destination directory missing** — `copy` fails if `/opt/sysops` doesn't exist. Always create the directory first with `file: state: directory`.
2. **Wrong `src` path** — `src` is the path on the **jump host** (control node), not the remote server. Verify with `ls /usr/src/sysops/index.html` on the jump host before running.
3. **Using `hosts: app_servers`** — With `hosts: all` the playbook runs on every host in the inventory regardless of group. Using `hosts: app_servers` would also work since all hosts are in `[app_servers]`. Either is fine here.
4. **Missing `become: yes`** — `/opt/` is owned by root. Writing to `/opt/sysops` requires sudo. Without `become: yes`, the task fails with "Permission denied."

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer.

---

**Q1: What is the Ansible `copy` module and how does it differ from `synchronize`?**

The `copy` module transfers files from the control node (jump host) to managed nodes using Ansible's own file transfer mechanism over SSH. It's simple and reliable but transfers the full file every time the content changes. The `synchronize` module uses `rsync` under the hood — faster for large files or directories because it only transfers changed portions. Use `copy` for small files, configuration files, and scripts. Use `synchronize` for large directories, bulk data transfers, or when incremental sync is needed. `copy` has no external dependency; `synchronize` requires `rsync` on both control and managed nodes.

---

**Q2: How does Ansible handle running tasks on multiple hosts simultaneously?**

Ansible runs tasks across multiple hosts using a "forks" model — the default is 5 parallel connections. With 3 app servers, all three run each task simultaneously (within the fork limit). Ansible processes one task at a time across all hosts before moving to the next task: all three servers create `/opt/sysops/` before any of them run the `copy` task. This "task-by-task" across all hosts (rather than "all tasks on host1, then all tasks on host2") ensures consistent state across the fleet. The `serial` keyword can change this to process hosts in batches — useful for rolling deployments where you want to update a percentage of servers at a time.

---

**Q3: What variables does the Ansible `copy` module support?**

Key variables: `src` (source path on control node), `dest` (destination path on managed node), `mode` (file permissions, quoted octal), `owner` (file owner), `group` (file group), `backup` (create backup of dest before overwriting — `yes/no`), `force` (overwrite if dest exists — default `yes`), `content` (use string content instead of a file — alternative to `src`). Example with ownership: `owner: root, group: root, mode: '0644'`. The `content` parameter is useful for creating simple config files without a source file: `content: "server_name {{ inventory_hostname }};"`.

---

**Q4: How would you copy different files to different servers using a single playbook?**

Use `when` conditions with inventory variables, or use separate plays:

```yaml
---
- name: Copy to app servers only
  hosts: app_servers
  become: yes
  tasks:
    - name: Copy index.html
      copy:
        src: /usr/src/sysops/index.html
        dest: /opt/sysops/index.html

- name: Copy config to db server
  hosts: db_servers
  become: yes
  tasks:
    - name: Copy db config
      copy:
        src: /usr/src/db/db.conf
        dest: /etc/db/db.conf
```

Multiple plays in one playbook file target different host groups with different tasks.

---

**Q5: What is the difference between `copy` (src on control node) and `fetch` (src on managed node)?**

`copy` pushes files FROM the control node TO managed nodes — distributing files. `fetch` pulls files FROM managed nodes TO the control node — collecting files. For distributing a config file to 10 servers, use `copy`. For collecting log files from 10 servers to the jump host for analysis, use `fetch`. `fetch` creates a directory structure on the control node organized by hostname: `./fetched/stapp01/var/log/messages`, `./fetched/stapp02/var/log/messages`, etc. — keeping fetched files from different hosts separate.

---

**Q6: How would you verify the file was copied correctly on all servers after the playbook runs?**

Several approaches: (1) **Ad-hoc command** — `ansible all -i inventory -m shell -a "md5sum /opt/sysops/index.html"` — compare checksums across all servers and against the source. (2) **stat module** — `ansible all -i inventory -m stat -a "path=/opt/sysops/index.html"` — returns file metadata (size, permissions, checksum). (3) **Add a verification task to the playbook** using `stat` and `assert` modules to fail if the file doesn't match expected properties. (4) **Ansible check mode** — re-run with `--check` — the `copy` module in check mode reports `ok` if the file already matches source (nothing to change) and `changed` if it would need to be updated.

---

## 🔗 References

- [Ansible `copy` Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html)
- [Ansible `file` Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/file_module.html)
- [Ansible Inventory Groups](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
