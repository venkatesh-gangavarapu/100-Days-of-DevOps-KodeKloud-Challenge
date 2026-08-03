# Day 92 — Ansible Roles + Jinja2 Templates: httpd Deployment on App Server 2

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Ansible / Roles / Jinja2 / template Module  
**Difficulty:** Intermediate–Advanced  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

1. Update `playbook.yml` — fill in empty `hosts:` field with `stapp02`
2. Create `index.html.j2` Jinja2 template using `{{ inventory_hostname }}`
3. Append `template` task to `role/httpd/tasks/main.yml` with `0755` permissions and `steve` as owner

**Expected output on stapp02:**

```
This file was created using Ansible on stapp02
-rwxr-xr-x 1 steve steve ... /var/www/html/index.html
```

---

## 🧠 What the Lab Provided

The lab already had:
- `ansible.cfg` with `host_key_checking = False`
- `inventory` with stapp01/02/03 and `ansible_ssh_pass`
- `playbook.yml` with `hosts:` **empty** — needed `stapp02`
- `role/httpd/` with `tasks/`, `templates/` directories already created

Three changes were needed:

**1. Fill in `playbook.yml`**
```yaml
---
- hosts: stapp02
  become: yes
  become_user: root
  roles:
    - role/httpd
```

**2. Create `role/httpd/templates/index.html.j2`**
```
This file was created using Ansible on {{ inventory_hostname }}
```

**3. Append to `role/httpd/tasks/main.yml`**
```yaml
- name: Deploy index.html from Jinja2 template
  template:
    src: index.html.j2
    dest: /var/www/html/index.html
    owner: "{{ ansible_user }}"
    group: "{{ ansible_user }}"
    mode: '0755'
```

---

## 🧠 Concept — Roles + Jinja2

### Why inventory_hostname not a hardcoded string

On stapp02 the variable resolves to `stapp02`. On stapp01 it would be `stapp01`. One template, correct output on any server. Hardcoding defeats the purpose of templates.

### Why ansible_user for owner

Defined per-host in inventory: tony for stapp01, steve for stapp02, banner for stapp03. Using the variable means the correct owner is set without any conditional logic.

### Append not overwrite

```
cat >> tasks/main.yml   # APPEND — preserves existing tasks
cat >  tasks/main.yml   # OVERWRITE — destroys existing tasks
```

The existing main.yml had httpd install and service tasks. Only the template task was appended.

### Role template path resolution

Inside a role, `src: index.html.j2` automatically resolves to `role/httpd/templates/index.html.j2`. No absolute paths needed in role tasks.

---

## 🔧 Exact Commands Run

```bash
# 1. Update playbook.yml (was: hosts: empty)
# Updated to: hosts: stapp02

# 2. Create Jinja2 template
# echo content into role/httpd/templates/index.html.j2

# 3. Append template task to role/httpd/tasks/main.yml using >>

# 4. Run
# cd ~/ansible
# ansible-playbook -i inventory playbook.yml
```

---

## 📊 Stratos DC Reference

| Server | Hostname | ansible_user | ansible_ssh_pass |
|--------|----------|-------------|-----------------|
| App Server 1 | stapp01 | tony | Ir0nM@n |
| App Server 2 | stapp02 | steve | Am3ric@ |
| App Server 3 | stapp03 | banner | BigGr33n |

---

## ⚠️ Common Mistakes to Avoid

1. **Leaving `hosts:` empty** — Playbook won't run against any host.
2. **Hardcoding server name in template** — Use `{{ inventory_hostname }}`.
3. **Wrong permissions** — This task is `0755`, not `0744`.
4. **Overwriting tasks/main.yml** — Use `>>` to append, not `>`.
5. **Wrong role path** — Match existing playbook format: `role/httpd`.

---

## 💼 Key Q&A

**Q: What are Ansible roles?**
Structured directories grouping tasks, templates, files, handlers, and variables into reusable units. A playbook applies roles to hosts — the role defines what to do, the playbook defines where.

**Q: `inventory_hostname` vs `ansible_hostname`?**
`inventory_hostname` is the name in the inventory file (`stapp02`). `ansible_hostname` is what the OS reports via the hostname command — may differ in cloud environments. Use `inventory_hostname` for consistent inventory-level naming.

**Q: `template` vs `copy`?**
`copy` transfers static files unchanged. `template` processes Jinja2, resolving variables before writing. Any file needing host-specific content should use `template`.

---

## 🔗 References

- [Ansible Roles](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html)
- [Ansible template Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html)
- [Jinja2 Templates](https://jinja.palletsprojects.com/en/3.1.x/templates/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
