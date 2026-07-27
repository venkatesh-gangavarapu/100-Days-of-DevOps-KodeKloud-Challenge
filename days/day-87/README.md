# Day 87 — Ansible yum Module: Installing Packages on All App Servers

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Ansible / yum Module / Package Management  
**Difficulty:** Beginner  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

Install `samba` package on all three app servers using Ansible's `yum` module.

---

## 🧠 Concept — Ansible `yum` Module

The `yum` module manages packages on RPM-based Linux systems (RHEL, CentOS, Fedora). Equivalent to running `yum install` or `yum remove` manually, but idempotent and declarative.

```yaml
- name: Install samba package
  yum:
    name: samba
    state: present
```

### `state` Values

| State | Effect |
|-------|--------|
| `present` | Install if not installed (idempotent) |
| `latest` | Install or upgrade to latest version |
| `absent` | Remove if installed |

`state: present` is correct for "ensure it's installed" — it won't reinstall if already present, keeping the playbook idempotent.

### Why `become: yes`?

`yum install` requires root. Without `become: yes`, the task fails with "You need to be root to perform this command." The Ansible `become` directive uses `sudo` to escalate privileges.

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
- name: Install samba on all app servers
  hosts: all
  become: yes
  tasks:
    - name: Install samba package
      yum:
        name: samba
        state: present
```

---

## 🔧 Commands on Jump Host

```bash
mkdir -p /home/thor/playbook

# Write inventory and playbook (see above)

# Test connectivity first
ansible all -i /home/thor/playbook/inventory -m ping

# Run playbook
cd /home/thor/playbook
ansible-playbook -i inventory playbook.yml

# Verify installation on all servers
ansible all -i inventory -m shell -a "rpm -q samba"
```

**Expected output:**
```
PLAY RECAP
stapp01 : ok=2  changed=1  unreachable=0  failed=0
stapp02 : ok=2  changed=1  unreachable=0  failed=0
stapp03 : ok=2  changed=1  unreachable=0  failed=0
```

---

## ⚠️ Common Mistakes

1. **Using `apt` instead of `yum`** — Stratos DC app servers are RHEL/CentOS. `apt` is for Debian/Ubuntu. Always use `yum` (or `dnf`) for RPM-based systems.
2. **Missing `become: yes`** — Package installation requires root. Without it, yum fails with a permissions error.
3. **`state: latest` vs `state: present`** — `latest` upgrades if a newer version exists (changes system state). `state: present` only installs if missing — safer and truly idempotent.
4. **Wrong working directory** — Validation runs `ansible-playbook -i inventory playbook.yml` from `/home/thor/playbook/`. Run `cd /home/thor/playbook` before the ansible-playbook command.

---

## 💼 Real-World DevOps Q&A

**Q1: What is the Ansible `yum` module and how does it differ from running `yum install` directly?**

The `yum` module is an Ansible wrapper around the yum package manager. Key differences from `shell: yum install samba`: (1) Idempotent — `yum: state: present` checks if the package is already installed before attempting install, reporting `ok` if nothing changed. `shell: yum install` always reports `changed`. (2) Consistent return data — the module returns structured data about what changed. (3) Check mode support — `--check` runs show what would change without making changes. (4) Cross-distribution — `package` module (generic) handles both `yum` and `apt` with the same syntax.

**Q2: When should you use `state: present` vs `state: latest`?**

`state: present` installs the package if missing, does nothing if already installed. Use for: ensuring a package exists without forcing upgrades, predictable behavior in production (don't unexpectedly upgrade). `state: latest` installs if missing AND upgrades if a newer version is available. Use for: security patches that must always be current, development environments where latest is desired. In production, `state: present` with specific version pinning (`name: samba-4.x.x`) is most reliable — prevents unexpected behavior from auto-upgrades during routine playbook runs.

**Q3: How would you install multiple packages in a single task?**

Pass a list to `name`:
```yaml
- name: Install multiple packages
  yum:
    name:
      - samba
      - samba-client
      - wget
      - vim
    state: present
```
This is more efficient than separate tasks — yum resolves all dependencies in one transaction. Alternatively, use a variable: `name: "{{ packages }}"` with `packages: [samba, wget]` defined in `vars`.

**Q4: How would you verify the package was installed after the playbook runs?**

```bash
# Ad-hoc command to check on all servers
ansible all -i inventory -m shell -a "rpm -q samba"

# Or use the package_facts module in the playbook
- name: Gather package facts
  package_facts:
    manager: rpm

- name: Assert samba is installed
  assert:
    that: "'samba' in ansible_facts.packages"
    msg: "samba is not installed!"
```

**Q5: What is the difference between `yum`, `dnf`, and `package` modules in Ansible?**

`yum` module targets older RHEL/CentOS (< 8) using the yum package manager. `dnf` module targets newer RHEL/CentOS (8+) and Fedora using the dnf package manager. `package` module is generic — it detects the OS package manager and uses the appropriate one automatically. For modern environments, `dnf` or `package` is preferred. For maximum compatibility across RHEL versions, `yum` works on both (yum on older systems, dnf in yum-compatibility mode on newer). The KodeKloud Stratos DC servers use CentOS/RHEL where `yum` works reliably.

---

## 🔗 References

- [Ansible `yum` Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/yum_module.html)
- [Ansible `package` Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/package_module.html)
- [Ansible Privilege Escalation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_privilege_escalation.html)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
