# Day 85 — Ansible file Module: Per-Host Ownership with ansible_user Variable

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Ansible / file Module / Variables / Multi-Host  
**Difficulty:** Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create `/tmp/webapp.txt` on all three app servers with:
- Permissions: `0744`
- Owner: `tony` on stapp01, `steve` on stapp02, `banner` on stapp03

---

## 🧠 Key Concept — Per-Host Variables with `ansible_user`

Each server needs a different file owner. Rather than writing three separate plays or using `when` conditions, leverage `ansible_user` — already defined per-host in the inventory — as the owner value:

```yaml
owner: "{{ ansible_user }}"
group: "{{ ansible_user }}"
```

On stapp01: `ansible_user=tony` → owner becomes `tony`
On stapp02: `ansible_user=steve` → owner becomes `steve`
On stapp03: `ansible_user=banner` → owner becomes `banner`

One task, three different outcomes, driven by inventory variables.

### `0744` Permissions Explained

```
0744:
  Owner:  rwx (7) — read, write, execute
  Group:  r-- (4) — read only
  Others: r-- (4) — read only
```

The owner can execute the file (useful if it were a script). Group and others can only read it.

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
- name: Create webapp.txt on all app servers
  hosts: all
  become: yes
  tasks:
    - name: Create /tmp/webapp.txt with correct permissions and ownership
      file:
        path: /tmp/webapp.txt
        state: touch
        mode: '0744'
        owner: "{{ ansible_user }}"
        group: "{{ ansible_user }}"
```

---

## 🔧 Commands

```bash
mkdir -p ~/playbook

# Write inventory and playbook (commands above)

# Test connectivity
ansible all -i ~/playbook/inventory -m ping

# Run playbook
cd ~/playbook
ansible-playbook -i inventory playbook.yml

# Verify ownership and permissions on all servers
ansible all -i inventory -m shell -a "ls -la /tmp/webapp.txt"
```

**Expected output from verify:**
```
stapp01 | SUCCESS | rc=0 >>
-rwxr--r-- 1 tony   tony   0 ... /tmp/webapp.txt

stapp02 | SUCCESS | rc=0 >>
-rwxr--r-- 1 steve  steve  0 ... /tmp/webapp.txt

stapp03 | SUCCESS | rc=0 >>
-rwxr--r-- 1 banner banner 0 ... /tmp/webapp.txt
```

---

## ⚠️ Common Mistakes

1. **Quoting `mode`** — Always write `mode: '0744'` with quotes. Without quotes, YAML may interpret `0744` as an integer (484 decimal), setting wrong permissions.
2. **`become: yes` required** — Setting file ownership with `chown` requires root. Without `become: yes`, the task fails with "Operation not permitted."
3. **Using `state: file` instead of `state: touch`** — `state: file` asserts the file exists and fails if it doesn't. `state: touch` creates it if missing.
4. **Hardcoding owners** — Using `owner: tony` in the task would set `tony` as owner on ALL servers. Using `{{ ansible_user }}` correctly sets the per-host SSH user as the owner.

---

## 💼 Real-World DevOps Q&A

**Q1: How does `{{ ansible_user }}` work differently on each host?**

`ansible_user` is a connection variable set per-host in the inventory. When Ansible processes each host, it uses that host's specific variable values. `{{ ansible_user }}` in a task resolves to whatever `ansible_user` is for the current host being processed. This is the same mechanism that powers all Ansible templating — `{{ inventory_hostname }}`, `{{ ansible_host }}`, custom vars — all resolve per-host during playbook execution.

**Q2: What is the difference between `mode: '0744'` and `mode: 0744`?**

In YAML, unquoted `0744` is parsed as an octal integer literal, which becomes decimal 484. Ansible then interprets 484 in decimal, not octal, resulting in wrong permissions. Quoted `'0744'` is a string — Ansible's `file` module correctly interprets it as an octal permission value. Always quote file mode values in Ansible playbooks. Alternatively, use symbolic notation: `mode: 'u=rwx,g=r,o=r'` — unambiguous and readable.

**Q3: When would you use `host_vars` instead of `ansible_user` for per-host ownership?**

`ansible_user` works when the owner matches the SSH connection user. When the required owner is different from the SSH user, use `host_vars`. Create `/home/thor/playbook/host_vars/stapp01.yml` with `file_owner: tony`, `/host_vars/stapp02.yml` with `file_owner: steve`, etc. Then reference `owner: "{{ file_owner }}"` in the task. This separates connection credentials from application-level variables — better for production where SSH users and application owners may differ.

**Q4: How would you verify the task is idempotent?**

Run the playbook twice. On the second run, all tasks should report `ok` (not `changed`). If `changed` appears again, the task is not idempotent. For `file: state: touch`, subsequent runs update the timestamp (always `changed`). For truly idempotent behavior (only `changed` on creation), use `state: file` with a separate creation step, or use `creates` parameter in a `command` task. Idempotency is critical for playbooks run repeatedly by automation.

**Q5: How does `become: yes` interact with file ownership?**

`become: yes` runs tasks as root (via sudo). When root creates a file, by default it's owned by root. The `owner` and `group` parameters in the `file` module run `chown` on the file after creation — changing ownership from root to the specified user. Without `become: yes`, the file is created as `tony/steve/banner` (the SSH user) and `chown` to a different user would fail. With `become: yes`, root creates the file then `chown`s it to the specified owner — both operations succeed.

---

## 🔗 References

- [Ansible `file` Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/file_module.html)
- [Ansible Special Variables](https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html)
- [Ansible host_vars](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html#organizing-host-and-group-variables)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
