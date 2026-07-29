# Day 89 — Ansible: Install and Enable vsftpd on All App Servers

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Ansible / yum / service Module  
**Difficulty:** Beginner  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create `/home/thor/ansible/playbook.yml` to:
1. Install `vsftpd` on all app servers using `yum`
2. Start and enable the `vsftpd` service

Inventory already exists at `/home/thor/ansible/inventory`.

---

## 🧠 What is vsftpd?

vsftpd (Very Secure FTP Daemon) is a lightweight, secure FTP server for Linux. It's widely used for file transfers in internal networks. Installing and enabling it as a service means it starts automatically on boot and is immediately available for connections.

---

## 🔧 The Playbook

```yaml
---
- name: Install and enable vsftpd on all app servers
  hosts: all
  become: yes
  tasks:
    - name: Install vsftpd
      yum:
        name: vsftpd
        state: present

    - name: Start and enable vsftpd service
      service:
        name: vsftpd
        state: started
        enabled: yes
```

---

## 🔧 Commands on Jump Host

```bash
# Create playbook (inventory already exists)
cat > /home/thor/ansible/playbook.yml << 'EOF'
---
- name: Install and enable vsftpd on all app servers
  hosts: all
  become: yes
  tasks:
    - name: Install vsftpd
      yum:
        name: vsftpd
        state: present

    - name: Start and enable vsftpd service
      service:
        name: vsftpd
        state: started
        enabled: yes
EOF

# Run
cd /home/thor/ansible
ansible-playbook -i inventory playbook.yml

# Verify
ansible all -i inventory -m shell -a "systemctl status vsftpd | grep Active"
```

**Expected output:**
```
PLAY RECAP
stapp01 : ok=3  changed=2  unreachable=0  failed=0
stapp02 : ok=3  changed=2  unreachable=0  failed=0
stapp03 : ok=3  changed=2  unreachable=0  failed=0
```

---

## ⚠️ Common Mistakes

1. **Missing `enabled: yes`** — `state: started` starts the service now but won't restart it after reboot. Always pair with `enabled: yes` for daemon services.
2. **Missing `become: yes`** — `yum install` and `systemctl` require root. Without privilege escalation the tasks fail.
3. **Wrong service name** — The service name is `vsftpd` (same as the package). Some packages have different service and package names — always verify.

---

## 💼 Quick Q&A

**Q: What is the difference between `state: started` and `state: restarted`?**

`state: started` — starts the service if it's not running; does nothing if already running (idempotent). `state: restarted` — always restarts the service, even if already running. Use `started` for "ensure it's running" tasks. Use `restarted` in handlers triggered by config file changes, where a restart is needed to apply the new config.

**Q: How would you configure vsftpd after installation using Ansible?**

Use the `template` or `blockinfile` module to modify `/etc/vsftpd/vsftpd.conf`, then notify a handler to restart vsftpd:

```yaml
- name: Configure vsftpd
  template:
    src: vsftpd.conf.j2
    dest: /etc/vsftpd/vsftpd.conf
  notify: Restart vsftpd

handlers:
  - name: Restart vsftpd
    service:
      name: vsftpd
      state: restarted
```

The handler only triggers if the config file actually changed — preventing unnecessary restarts.

**Q: What is `enabled: yes` in the service module?**

`enabled: yes` runs `systemctl enable vsftpd` — creates a symlink in the systemd target directory so the service starts automatically when the system boots. Without it, the service runs in the current session but won't survive a reboot. Production services should always have `enabled: yes`.

---

## 🔗 References

- [Ansible `service` Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/service_module.html)
- [vsftpd Documentation](https://security.appspot.com/vsftpd.html)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
