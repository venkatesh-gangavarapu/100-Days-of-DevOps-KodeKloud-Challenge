# Day 07 — Setting Up Passwordless SSH Authentication Across All App Servers

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Linux SSH / Infrastructure Access Management  
**Difficulty:** Intermediate  
**Status:** ✅ Completed

---

## 📋 Task Summary

Automated scripts on the **jump host** run on scheduled intervals and need to SSH into all 3 App Servers in Stratos Datacenter without manual password entry. The task was to configure **passwordless SSH authentication** from user `thor` on the jump host to the sudo users on each app server.

| From | To | Via User |
|------|----|----------|
| Jump Host (`thor`) | App Server 1 (`stapp01`) | `tony` |
| Jump Host (`thor`) | App Server 2 (`stapp02`) | `steve` |
| Jump Host (`thor`) | App Server 3 (`stapp03`) | `banner` |

---

## 🧠 Concept — SSH Key-Based Authentication

SSH supports two authentication methods:

| Method | How it works | Use case |
|--------|-------------|----------|
| **Password auth** | User types a password each login | Manual, interactive logins |
| **Key-based auth** | Cryptographic key pair proves identity | Automation, scripts, CI/CD |

### How Key-Based Authentication Works

```
┌──────────────┐                        ┌──────────────────┐
│  Jump Host   │                        │   App Server     │
│              │                        │                  │
│  Private Key │──── SSH connection ───►│  Checks against  │
│  (~/.ssh/    │                        │  authorized_keys │
│   id_rsa)    │◄─── Access granted ────│  (~/.ssh/        │
│              │     (no password)      │   authorized_keys│
└──────────────┘                        └──────────────────┘
```

1. `thor` initiates SSH connection
2. App server sends a cryptographic challenge
3. Jump host signs it with the **private key**
4. App server verifies the signature against the stored **public key**
5. Match = access granted, no password needed

### Key Pair Anatomy

```
~/.ssh/id_rsa       → Private key — NEVER leaves the jump host. Never shared.
~/.ssh/id_rsa.pub   → Public key  — Copied to remote servers. Safe to distribute.
```

> **Real-world context:** Every Ansible control node, Jenkins agent, GitHub Actions self-hosted runner, and deployment script relies on this exact setup. Passwordless SSH isn't a shortcut — it's the correct, secure way to handle machine-to-machine authentication. Password auth for automation is the anti-pattern.

---

## 🖥️ Environment

| Role | Host | User | Password |
|------|------|------|----------|
| Jump Host | `jump_host` | `thor` | — |
| App Server 1 | `stapp01` | `tony` | `Ir0nM@n` |
| App Server 2 | `stapp02` | `steve` | `Am3ric@` |
| App Server 3 | `stapp03` | `banner` | `BigGr33n` |

---

## 🔧 Solution — Step by Step

### Step 1: Verify you're on the jump host as thor

```bash
whoami
# Expected: thor

hostname
# Expected: jump_host or similar
```

### Step 2: Generate SSH key pair for thor

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

**Flag breakdown:**

| Flag | Purpose |
|------|---------|
| `-t rsa` | Use RSA algorithm |
| `-b 4096` | 4096-bit key length (stronger than default 2048) |
| `-f ~/.ssh/id_rsa` | Save key to this location |
| `-N ""` | No passphrase — required for non-interactive automation |

**Output:**
```
Generating public/private rsa key pair.
Your identification has been saved in /home/thor/.ssh/id_rsa
Your public key has been saved in /home/thor/.ssh/id_rsa.pub
```

> **Note:** If `~/.ssh/id_rsa` already exists, you can skip this step or use `-f` with a different filename to avoid overwriting.

### Step 3: Copy public key to all 3 app servers

```bash
ssh-copy-id tony@stapp01
# Enter password: Ir0nM@n (last time you'll need it)

ssh-copy-id steve@stapp02
# Enter password: Am3ric@

ssh-copy-id banner@stapp03
# Enter password: BigGr33n
```

`ssh-copy-id` automatically:
- Creates `~/.ssh/` on the remote server if it doesn't exist
- Sets correct permissions (`700` for dir, `600` for file)
- Appends the public key to `~/.ssh/authorized_keys`

### Step 4: Test passwordless SSH to each server

```bash
ssh tony@stapp01 "whoami && hostname"
ssh steve@stapp02 "whoami && hostname"
ssh banner@stapp03 "whoami && hostname"
```

**Expected output (no password prompt):**
```
tony
stapp01.stratos.xfusioncorp.com
```

✅ Passwordless SSH is working.

### Step 5: Verify public key was registered on each server

```bash
ssh tony@stapp01 "cat ~/.ssh/authorized_keys"
```

You should see `thor`'s public key listed — the same content as `~/.ssh/id_rsa.pub` on the jump host.

---

## 📌 Commands Reference

```bash
# Generate key pair (no passphrase for automation)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# View the generated public key
cat ~/.ssh/id_rsa.pub

# Copy public key to remote servers
ssh-copy-id tony@stapp01
ssh-copy-id steve@stapp02
ssh-copy-id banner@stapp03

# Test passwordless login
ssh tony@stapp01 "whoami && hostname"
ssh steve@stapp02 "whoami && hostname"
ssh banner@stapp03 "whoami && hostname"

# Verify authorized_keys on remote server
ssh tony@stapp01 "cat ~/.ssh/authorized_keys"

# ─── Manual method (if ssh-copy-id is unavailable) ───
# Copy public key content manually
cat ~/.ssh/id_rsa.pub

# On the remote server, append it:
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo "PUBLIC_KEY_CONTENT" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# ─── Useful SSH debug flags ───
ssh -v tony@stapp01          # Verbose — shows auth method being attempted
ssh -i ~/.ssh/id_rsa tony@stapp01  # Specify key explicitly
```

---

## ⚠️ Common Mistakes to Avoid

1. **Setting a passphrase on the key** — If you add a passphrase, automated scripts will hang waiting for input. For machine-to-machine auth, `-N ""` (empty passphrase) is correct.
2. **Wrong file permissions** — SSH is strict about this. If permissions are too open, key auth silently fails:
   ```
   ~/.ssh/           → must be 700 (drwx------)
   ~/.ssh/id_rsa     → must be 600 (-rw-------)
   ~/.ssh/authorized_keys → must be 600 (-rw-------)
   ```
3. **Copying the private key instead of the public key** — The `.pub` file goes to the server. The private key (`id_rsa`) never leaves your machine. Ever.
4. **Not testing after setup** — Always run `ssh user@host "whoami"` immediately after to confirm it works before any automation depends on it.
5. **Forgetting to check `~/.ssh` exists on the remote** — `ssh-copy-id` handles this, but manual methods don't. Always `mkdir -p ~/.ssh` before writing `authorized_keys`.

---

## 🔍 SSH Key Auth Troubleshooting

```bash
# Enable verbose logging to see why auth fails
ssh -vvv tony@stapp01

# Check permissions on jump host
ls -la ~/.ssh/

# Check permissions on remote server
ssh tony@stapp01 "ls -la ~/.ssh/"

# Check SSH daemon allows key auth (on remote server)
sudo grep -i "PubkeyAuthentication" /etc/ssh/sshd_config
# Should show: PubkeyAuthentication yes (or be absent — default is yes)

# Check auth logs on remote server for failures
sudo tail -f /var/log/secure
```

---

## 🔗 References

- [SSH Key Authentication — Red Hat Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/securing_networks/using-secure-communications-between-two-systems-with-openssh_securing-networks)
- [`ssh-keygen` man page](https://man7.org/linux/man-pages/man1/ssh-keygen.1.html)
- [`ssh-copy-id` man page](https://linux.die.net/man/1/ssh-copy-id)
- [Ansible — Passwordless SSH Setup](https://docs.ansible.com/ansible/latest/inventory_guide/connection_details.html)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: Passwordless SSH is set up but still prompting for a password. What are the most common causes?**

```bash
# Step 1: Check permissions on jump host
ls -la ~/.ssh/
# ~/.ssh/ must be 700, id_rsa must be 600

# Step 2: Check permissions on remote server
ssh -v user@host    # verbose — shows which auth methods are tried

# Step 3: Check authorized_keys on remote server
ssh user@host "ls -la ~/.ssh/authorized_keys"
# Must be 600 (-rw-------)

# Step 4: Check SSH daemon config on remote
sudo grep -E "PubkeyAuthentication|AuthorizedKeysFile" /etc/ssh/sshd_config
# PubkeyAuthentication yes (must not be 'no')
```

> SSH is extremely strict about permissions. If `~/.ssh/` is `755` or `authorized_keys` is `644`, the SSH daemon silently ignores the key and falls back to password auth. This is the #1 cause of "passwordless SSH not working."

---

**Q2: What's the security risk of using a 2048-bit RSA key vs 4096-bit? When does it matter?**

> For most purposes today, 2048-bit RSA is still considered secure. 4096-bit provides a stronger margin against future advances in computing. The practical guidance: use **4096-bit for long-lived keys** (infrastructure, automation) and Ed25519 for modern systems:
>
> ```bash
> ssh-keygen -t ed25519 -C "automation-key" -N ""
> ```
>
> Ed25519 is smaller, faster, and considered more secure than RSA-4096. Use RSA only for compatibility with legacy systems.

---

**Q3: In an automated Ansible or CI/CD setup, the SSH key has no passphrase. Is that a security problem?**

> For machine-to-machine automation, no passphrase is correct and expected — there's no human to enter it at runtime. The security controls shift to:
> - Restrict the key's permissions to specific commands (`command=` in `authorized_keys`)
> - Store the private key in a secrets manager (HashiCorp Vault, AWS Secrets Manager) rather than on disk
> - Rotate keys regularly
> - Limit what the key's user account can do (scoped sudo, restricted shell)
>
> A passphrase on an automation key just breaks the automation.

---

**Q4: How do you add a passphrase to an existing key, or change/remove it?**

```bash
# Add or change passphrase on existing key
ssh-keygen -p -f ~/.ssh/id_rsa

# Check if a key already has a passphrase (it will prompt)
ssh-keygen -y -f ~/.ssh/id_rsa
```

---

**Q5: You need to set up passwordless SSH from a CI/CD runner to 50 production servers. What's the production-grade approach?**

> 1. Generate a **dedicated deployment key pair** (not your personal key)
> 2. Store the **private key** in your CI/CD secret store (GitHub Secrets, GitLab CI variables, Jenkins credentials)
> 3. Distribute the **public key** to all 50 servers via Ansible:
> ```yaml
> - name: Add deploy key
>   ansible.posix.authorized_key:
>     user: deploy
>     key: "{{ lookup('file', 'deploy_key.pub') }}"
>     state: present
> ```
> 4. Scope the key to only the commands the CI needs (using `command=` in `authorized_keys`)
> 5. Rotate the key on a schedule or after any team member departure

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
