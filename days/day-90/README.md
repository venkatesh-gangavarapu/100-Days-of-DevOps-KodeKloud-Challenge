# Day 90 — Ansible ACL Module: Per-Server File Permissions

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Ansible / ACL / Multi-Play Playbook  
**Difficulty:** Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

| Server | File | Entity | Type | Permissions |
|--------|------|--------|------|------------|
| stapp01 | `/opt/security/blog.txt` | `tony` | group | `r` |
| stapp02 | `/opt/security/story.txt` | `steve` | user | `rw` |
| stapp03 | `/opt/security/media.txt` | `banner` | group | `rw` |

All files owned by `root`. ACL grants extra permissions to specific users/groups without changing standard ownership.

---

## 🧠 Concept — Access Control Lists (ACL)

Standard Linux file permissions support exactly three permission sets: owner, group, others. ACL extends this to allow granular per-user or per-group permissions on top of standard permissions.

```bash
# Standard permissions — only three entities
-rw-r--r-- root root blog.txt

# With ACL — additional per-entity grants
-rw-r--r--+ root root blog.txt
            ↑ "+" means ACL is set

getfacl /opt/security/blog.txt
# user::rw-
# group::r--
# group:tony:r--   ← ACL grant for group tony
# mask::r--
# other::r--
```

### Ansible `acl` Module Parameters

| Parameter | Purpose |
|-----------|---------|
| `path` | File to apply ACL to |
| `entity` | Username or group name |
| `etype` | Type: `user`, `group`, `other`, `mask` |
| `permissions` | Permission string: `r`, `rw`, `rwx`, `-`, etc. |
| `state` | `present` (add/update) or `absent` (remove) |

### Multi-Play Playbook Pattern

Each server gets a completely different set of tasks. Rather than using `when: inventory_hostname == 'stapp01'` conditions, separate plays with targeted `hosts:` is cleaner and more readable:

```yaml
- name: Play for stapp01
  hosts: stapp01
  ...

- name: Play for stapp02
  hosts: stapp02
  ...
```

---

## 🔧 Verification

```bash
# After running the playbook, verify ACLs
ansible stapp01 -i inventory -m shell \
  -a "getfacl /opt/security/blog.txt" --become

ansible stapp02 -i inventory -m shell \
  -a "getfacl /opt/security/story.txt" --become

ansible stapp03 -i inventory -m shell \
  -a "getfacl /opt/security/media.txt" --become
```

**Expected on stapp01:**
```
# file: opt/security/blog.txt
# owner: root
# group: root
group:tony:r--
```

**Expected on stapp02:**
```
user:steve:rw-
```

**Expected on stapp03:**
```
group:banner:rw-
```

---

## ⚠️ Common Mistakes

1. **Confusing `etype: group` with the group name** — `etype` is the TYPE (`user` or `group`), `entity` is the NAME (`tony`, `steve`). These are separate parameters.
2. **`acl` package not installed** — The `acl` module requires `setfacl`/`getfacl` utilities on the remote host. If the task fails with "command not found," install with `yum: name: acl state: present` first.
3. **Using one play with `when` instead of separate plays** — Works but is harder to read. Separate plays per host is the clean pattern for server-specific tasks.
4. **Forgetting `become: yes`** — Creating files in `/opt/` and modifying ACLs requires root.
5. **`state: touch` changes timestamp on re-run** — The `file: state: touch` task always reports `changed` on subsequent runs because it updates the timestamp. This is acceptable — the file content and ACLs remain correct.

---

## 💼 Real-World DevOps Q&A

**Q1: What is ACL and when is it used instead of standard Linux permissions?**

Standard Linux permissions support only three permission sets — owner, owning group, and others — which is inflexible for complex access scenarios. ACL (Access Control List) adds per-user and per-group permission grants on top. Use ACL when: multiple users need different access to the same file, a file owned by `root` needs to be readable/writable by a specific non-root user without making it world-readable, or when you need to grant a user access to a file without changing its group ownership. Common in enterprise environments where files are owned by service accounts but need to be readable by developers or ops users.

**Q2: How does the `+` in `ls -la` output relate to ACL?**

When a file has ACL entries beyond standard permissions, `ls -la` shows a `+` at the end of the permission string: `-rw-r--r--+`. This is a visual indicator that ACL is set — you need `getfacl filename` to see the actual ACL entries. Without the `+`, only standard permissions apply. The `+` doesn't tell you what the ACL grants — just that additional entries exist.

**Q3: What is the `mask` in ACL output and why does it matter?**

The ACL mask defines the maximum permissions that named users and named groups (ACL entries) can have. When you set `permissions: rw` for a group, the effective permission is `rw AND mask`. If the mask is `r--`, even `rw` ACL entries are limited to `r` effective permission. The mask is automatically set to the most permissive ACL entry when you add entries with Ansible's `acl` module. Understanding the mask prevents confusion when ACL entries appear correct but actual access is restricted.

**Q4: How do you remove an ACL entry with Ansible?**

Change `state: present` to `state: absent`:
```yaml
- name: Remove ACL entry
  acl:
    path: /opt/security/blog.txt
    entity: tony
    etype: group
    state: absent
```

To remove all ACL entries from a file: `acl: path: /path/file state: absent` without specifying entity/etype. Or use `setfacl -b /path/file` via shell module.

**Q5: How would you write this playbook more concisely using variables?**

```yaml
---
- name: Configure security files with ACL
  hosts: all
  become: yes
  vars:
    acl_config:
      stapp01: {file: blog.txt, entity: tony, etype: group, perms: r}
      stapp02: {file: story.txt, entity: steve, etype: user, perms: rw}
      stapp03: {file: media.txt, entity: banner, etype: group, perms: rw}
  tasks:
    - name: Create directory
      file:
        path: /opt/security
        state: directory

    - name: Create file
      file:
        path: "/opt/security/{{ acl_config[inventory_hostname].file }}"
        state: touch
        owner: root

    - name: Set ACL
      acl:
        path: "/opt/security/{{ acl_config[inventory_hostname].file }}"
        entity: "{{ acl_config[inventory_hostname].entity }}"
        etype: "{{ acl_config[inventory_hostname].etype }}"
        permissions: "{{ acl_config[inventory_hostname].perms }}"
        state: present
```

This uses a dictionary keyed by `inventory_hostname` — one play, all servers, per-host configuration driven by variables. More advanced but significantly more maintainable at scale.

---

## 🔗 References

- [Ansible `acl` Module](https://docs.ansible.com/ansible/latest/collections/ansible/posix/acl_module.html)
- [Linux ACL Guide](https://www.redhat.com/sysadmin/linux-access-control-lists)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
