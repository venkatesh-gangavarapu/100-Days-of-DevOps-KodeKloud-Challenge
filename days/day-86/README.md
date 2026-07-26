# Day 86 — Passwordless SSH: Ansible Controller to App Server 2

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Ansible / SSH / Key-Based Authentication  
**Difficulty:** Beginner–Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

1. Set up passwordless SSH from jump host (thor) to App Server 2 (stapp02/steve)
2. Verify with `ansible -i /home/thor/ansible/inventory all -m ping`

---

## 🧠 Concept — SSH Key-Based Authentication for Ansible

### Why Passwordless SSH?

Ansible connects to managed nodes via SSH. When using password authentication, Ansible needs `ansible_password` in inventory (plaintext — insecure) or the `--ask-pass` flag (interactive — can't be automated). SSH key-based authentication eliminates both issues: the private key on the controller authenticates silently, no password needed, no interactive prompt, safe for automation.

### How SSH Key Authentication Works

```
Jump Host (controller):
  ~/.ssh/id_rsa       ← private key (never leaves this machine)
  ~/.ssh/id_rsa.pub   ← public key (copied to managed nodes)

App Server 2 (managed node):
  ~/.ssh/authorized_keys  ← contains jump host's public key

Connection:
  Jump host presents private key → stapp02 checks against authorized_keys → match → authenticated
  No password needed ✅
```

### `ssh-copy-id` — The Standard Tool

```bash
ssh-copy-id steve@stapp02
```

This command: reads `~/.ssh/id_rsa.pub`, SSHes to stapp02 (using password this one last time), appends the public key to `/home/steve/.ssh/authorized_keys`, sets correct permissions. After this, all future SSH connections from jump host to stapp02 as steve are passwordless.

---

## 🔧 Complete Steps

### 1. Generate SSH key on jump host

```bash
# Check if already exists
ls ~/.ssh/id_rsa.pub

# Generate if missing
ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
# -N "" = no passphrase (needed for automation)
```

### 2. Copy public key to stapp02

```bash
ssh-copy-id steve@stapp02
# Enter password when prompted: Am3ric@
# This is the last time you need the password
```

### 3. Verify passwordless SSH

```bash
ssh steve@stapp02
# No password prompt = success ✅
exit
```

### 4. Check/update inventory

```bash
cat /home/thor/ansible/inventory
```

Remove `ansible_password` if present. Final inventory:
```
stapp02 ansible_host=172.16.238.11 ansible_user=steve ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### 5. Test ansible ping

```bash
ansible -i /home/thor/ansible/inventory all -m ping
```

**Expected:**
```json
stapp02 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

---

## ⚠️ Common Mistakes

1. **Passphrase on private key** — `ssh-keygen -N ""` sets no passphrase. With a passphrase, Ansible can't authenticate without interactive input.
2. **Wrong permissions on authorized_keys** — Must be `chmod 600 ~/.ssh/authorized_keys` and `chmod 700 ~/.ssh/`. SSH rejects looser permissions as a security measure.
3. **Leaving `ansible_password` in inventory** — After key setup, remove the password variable. Keeping both is unnecessary and exposes credentials.
4. **StrictHostKeyChecking blocking first connection** — Even with key auth, the first SSH connection prompts for host key verification. `ansible_ssh_common_args='-o StrictHostKeyChecking=no'` handles this.

---

## 💼 Real-World DevOps Q&A

**Q1: Why is passwordless SSH preferred for Ansible over password authentication?**

Security and automation. Passwords in `ansible_password` are plaintext in inventory files — a significant security risk if files are committed to version control or exposed. `--ask-pass` requires interactive input, blocking automated CI/CD runs. SSH keys are asymmetric — the private key never leaves the controller, the public key on managed nodes can't be used to log in anywhere else. Key rotation is centralized (replace the key on the controller, update `authorized_keys` on all managed nodes). Industry standard: SSH keys for automation, passwords for emergency human access only.

**Q2: What does `ssh-keygen -N ""` do?**

`-N ""` sets an empty passphrase on the generated key. Without a passphrase, the private key file directly authenticates — no additional input needed. With a passphrase, every SSH use requires entering it (defeating automation). For Ansible controllers and CI/CD systems, empty passphrases are standard. The security tradeoff: if the private key file is compromised, an attacker has immediate access without needing the passphrase. Mitigate this with tight file permissions (`chmod 600 ~/.ssh/id_rsa`) and keeping the controller secure.

**Q3: What is the Ansible `ping` module and what does it actually test?**

Despite the name, `ansible -m ping` doesn't send ICMP ping packets. It's an Ansible connectivity test module that: establishes an SSH connection to the managed node, transfers a small Python script, executes it, and returns `{"ping": "pong"}` if successful. It verifies: SSH connectivity, SSH key authentication, Python availability on the managed node (Ansible requires Python), and correct user/permissions. A successful ping guarantees Ansible can run modules on that host.

**Q4: How would you set up passwordless SSH to all app servers at once?**

```bash
# Generate key once
ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""

# Copy to all three servers
ssh-copy-id tony@stapp01    # Ir0nM@n
ssh-copy-id steve@stapp02   # Am3ric@
ssh-copy-id banner@stapp03  # BigGr33n

# Test all
ansible -i inventory all -m ping
```

Or with `sshpass` for scripted copying:
```bash
sshpass -p 'Ir0nM@n' ssh-copy-id -o StrictHostKeyChecking=no tony@stapp01
sshpass -p 'Am3ric@' ssh-copy-id -o StrictHostKeyChecking=no steve@stapp02
sshpass -p 'BigGr33n' ssh-copy-id -o StrictHostKeyChecking=no banner@stapp03
```

---

## 🔗 References

- [Ansible Connection Methods](https://docs.ansible.com/ansible/latest/inventory_guide/connection_details.html)
- [OpenSSH Key Management](https://www.ssh.com/academy/ssh/keygen)
- [Ansible ping Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ping_module.html)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
---

## 📱 Proof of Work — LinkedIn Post

[View on LinkedIn](https://www.linkedin.com/posts/venkatesh-gangavarapu_devops-ansible-ssh-share-7487085870932525056-vyfl/)