# Day 91 — Ansible lineinfile: Adding Content at the Top of a File

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Ansible / lineinfile / copy / httpd  
**Difficulty:** Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

1. Install `httpd` and start/enable the service on all app servers
2. Create `/var/www/html/index.html` with: `This is a Nautilus sample file, created using Ansible!`
3. Add `Welcome to Nautilus Group!` at the **top** of the file using `lineinfile`
4. Owner: `apache:apache`, Permissions: `0644`

**Final file content:**
```
Welcome to Nautilus Group!
This is a Nautilus sample file, created using Ansible!
```

---

## 🧠 Concept — `lineinfile` Module

`lineinfile` manages a single line in a file — inserting, replacing, or removing it. Key parameters for today's task:

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `path` | `/var/www/html/index.html` | File to modify |
| `line` | `Welcome to Nautilus Group!` | Line to insert |
| `insertbefore` | `BOF` | Beginning Of File — inserts at the top |
| `owner` | `apache` | Set file owner after modification |
| `group` | `apache` | Set file group after modification |
| `mode` | `'0644'` | Set permissions after modification |

### `insertbefore: BOF` vs `insertafter: EOF`

```
insertbefore: BOF  → inserts at the very beginning (top)
insertafter: EOF   → inserts at the very end (bottom)
insertbefore: '^regex'  → inserts before the first matching line
insertafter: '^regex'   → inserts after the first matching line
```

### Why `copy` first, then `lineinfile`?

The `copy` module creates the file with the initial content and sets ownership/permissions in one step. Then `lineinfile` adds the additional line at the top. This sequence matters — if we used `lineinfile` with `create: yes` first and added the second line second, the order would be reversed.

### `lineinfile` Idempotency

`lineinfile` checks if the exact `line` value already exists in the file before inserting. If it's already there, it does nothing (reports `ok`). This prevents duplicate lines on repeated playbook runs.

---

## 🔧 The Playbook

```yaml
---
- name: Install httpd and deploy web page on all app servers
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

    - name: Create index.html with initial content
      copy:
        content: "This is a Nautilus sample file, created using Ansible!"
        dest: /var/www/html/index.html
        owner: apache
        group: apache
        mode: '0644'

    - name: Add line at top of index.html using lineinfile
      lineinfile:
        path: /var/www/html/index.html
        line: "Welcome to Nautilus Group!"
        insertbefore: BOF
        owner: apache
        group: apache
        mode: '0644'
```

---

## 🔧 Commands on Jump Host

```bash
# Create playbook (inventory already exists)
cat > /home/thor/ansible/playbook.yml << 'YAML'
[paste playbook content]
YAML

# Run
cd /home/thor/ansible
ansible-playbook -i inventory playbook.yml

# Verify content
ansible all -i inventory -m shell -a "cat /var/www/html/index.html"
# Line 1: Welcome to Nautilus Group!
# Line 2: This is a Nautilus sample file, created using Ansible!

# Verify permissions
ansible all -i inventory -m shell -a "ls -la /var/www/html/index.html"
# -rw-r--r-- 1 apache apache ...
```

---

## 📊 Module Comparison: copy vs lineinfile vs blockinfile

| Module | Use case | Idempotent? |
|--------|----------|-------------|
| `copy` | Create/overwrite entire file | Yes (checks content hash) |
| `lineinfile` | Add/update/remove ONE line | Yes (checks if line exists) |
| `blockinfile` | Add/update/remove MULTI-LINE block | Yes (uses markers) |
| `template` | Create file from Jinja2 template | Yes |

---

## ⚠️ Common Mistakes

1. **Wrong insertion point** — `insertbefore: BOF` adds to top, `insertafter: EOF` adds to bottom. Getting these swapped puts the line in the wrong place.
2. **Task order** — `copy` must come BEFORE `lineinfile`. If reversed, `lineinfile` would be overwritten by `copy`.
3. **Duplicate lines on re-run** — `lineinfile` won't add duplicates if the exact `line` string already exists. Safe to re-run.
4. **`copy: content:` vs `copy: src:`** — `content:` uses an inline string as file content. `src:` copies from a file on the control node. For short strings, `content:` is cleaner.

---

## 💼 Real-World DevOps Q&A

**Q1: What is the difference between `lineinfile`, `blockinfile`, and `copy` modules?**

`copy` creates or replaces an entire file — use it to deploy a complete config or web page from scratch. `lineinfile` manages exactly one line in an existing file — use it to add a setting, update a parameter, or remove a specific line without touching the rest. `blockinfile` manages a named multi-line block — use it to add a section to a config file (nginx server block, Apache VirtualHost, cron entry) while leaving the rest untouched. For today's task: `copy` creates the file, `lineinfile` adds a line at the top — a common pattern for adding headers or prepending content to existing files.

**Q2: How does `insertbefore: BOF` work internally?**

`BOF` (Beginning Of File) is a special keyword in the `lineinfile` module. When specified, Ansible reads the file, prepends the `line` value to the beginning, and writes the result back. It first checks if the line already exists anywhere in the file — if found, the position may be adjusted but no duplicate is created. Under the hood it's equivalent to: `sed -i '1i Welcome to Nautilus Group!' /var/www/html/index.html` — but idempotent and with proper file locking.

**Q3: How would you add the line AFTER the first line instead of at the very top?**

```yaml
lineinfile:
  path: /var/www/html/index.html
  line: "Welcome to Nautilus Group!"
  insertafter: "^This is a Nautilus"
```

`insertafter: "^This is a Nautilus"` uses a regex to match the first line containing "This is a Nautilus" and inserts the new line after it. Regex-based insertion and `insertbefore` give full control over where in the file the line lands.

**Q4: What happens if you run `lineinfile` with `insertbefore: BOF` twice on a file that already has the line?**

Nothing — `lineinfile` is idempotent. Before inserting, it scans the file for the exact `line` string. If found anywhere in the file, it considers the state already satisfied and reports `ok` (not `changed`). The line won't be duplicated. This behavior is controlled by the `regexp` parameter — if `regexp` is provided, it matches existing lines to update. Without `regexp`, it uses the exact `line` string as the match. Always test with `--check` mode first to see what Ansible would do without making changes.

**Q5: When would you use `copy: content:` vs creating a template file?**

`copy: content: "string"` is perfect for short, static content — a few lines, no variables, no conditional logic. It keeps everything in the playbook without needing a separate file. `template` (Jinja2) is better for: files with variable substitution (`{{ inventory_hostname }}`), files with conditional blocks (`{% if %}...{% endif %}`), or files longer than a few lines where maintaining a separate `.j2` file is cleaner. Rule of thumb: if the content is more than 3-4 lines or contains any variables, use a template file.

---

## 🔗 References

- [Ansible `lineinfile` Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/lineinfile_module.html)
- [Ansible `copy` Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
