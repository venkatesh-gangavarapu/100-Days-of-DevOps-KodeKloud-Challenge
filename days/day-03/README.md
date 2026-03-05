# Day 03 — Disabling Direct SSH Root Login (Security Hardening)

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Linux Security Hardening / SSH Configuration  
**Difficulty:** Beginner–Intermediate  
**Status:** ✅ Completed

---

## 📋 Task Summary

Following a security audit at `xFusionCorp Industries`, the security team mandated disabling direct root SSH login across **all 3 App Servers** in the Stratos Datacenter (`stapp01`, `stapp02`, `stapp03`). This is a standard hardening measure to reduce the attack surface on externally accessible servers.

---

## 🧠 Concept — Why Block Direct Root SSH?

Root is the superuser on every Linux system. Allowing direct root SSH access creates multiple risks:

| Risk | Explanation |
|------|-------------|
| **Known username** | Every attacker already knows to try `root` — that's half the credential guessed |
| **Brute force target** | Root accounts are hammered constantly in automated attacks |
| **No accountability** | Shared root access means no audit trail of who did what |
| **Blast radius** | A compromised root session = total system compromise with no recovery path |

### The Secure Alternative
Users SSH in as a **named account** → escalate via `sudo` when needed.
This gives you:
- ✅ Full audit trail (`/var/log/secure` or `journalctl`)
- ✅ Principle of least privilege
- ✅ Ability to revoke individual access without changing root credentials

> **Real-world context:** Disabling root SSH is **CIS Benchmark 5.2.10**, appears in **AWS Security Hub** hardening findings, and is a mandatory control in **SOC 2**, **PCI-DSS**, and **ISO 27001** environments. This is the first thing a security engineer checks on any new server.

---

## 🖥️ Environment

| Server | Hostname | User |
|--------|----------|------|
| App Server 1 | `stapp01` | tony |
| App Server 2 | `stapp02` | steve |
| App Server 3 | `stapp03` | banner |

---

## 🔧 Solution — Step by Step

> Same steps applied on all 3 servers. Shown once for `stapp01`.

### Step 1: SSH into the server

```bash
ssh tony@stapp01
```

### Step 2: Open the SSH daemon configuration file

```bash
sudo vi /etc/ssh/sshd_config
```

### Step 3: Locate and update `PermitRootLogin`

Find this line (it may be commented out with `#`):
```
#PermitRootLogin yes
```

Update it to:
```
PermitRootLogin no
```

**Or use `sed` for a faster, non-interactive edit:**
```bash
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
```

### Step 4: Verify the change took effect

```bash
grep "PermitRootLogin" /etc/ssh/sshd_config
```

**Expected output:**
```
PermitRootLogin no
```

### Step 5: Restart the SSH daemon to apply changes

```bash
sudo systemctl restart sshd
```

> ⚠️ **Important:** Always make sure you have an active session open before restarting `sshd`. If your config has a typo and SSH breaks, you need that existing session to fix it.

### Step 6: Verify SSH service is healthy

```bash
sudo systemctl status sshd
```

**Expected output:**
```
● sshd.service - OpenSSH server daemon
   Loaded: loaded (/usr/lib/systemd/system/sshd.service; enabled)
   Active: active (running) since ...
```

### Step 7: Confirm root login is actually blocked

```bash
ssh root@stapp01
```

**Expected output:**
```
Permission denied, please try again.
```

✅ Direct root SSH is disabled.

**Repeat Steps 1–7 for `stapp02` (steve) and `stapp03` (banner).**

---

## 📌 Commands Reference

```bash
# Quick sed-based fix (all in one line)
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Verify the config line
grep "PermitRootLogin" /etc/ssh/sshd_config

# Restart SSH daemon
sudo systemctl restart sshd

# Check service health
sudo systemctl status sshd

# Test root login is blocked (from external)
ssh root@<server-ip>

# Check SSH config for syntax errors before restarting (SAFE PRACTICE)
sudo sshd -t

# View SSH auth logs to confirm denied root attempts
sudo tail -f /var/log/secure
```

---

## ⚠️ Common Mistakes to Avoid

1. **Restarting SSH without verifying config syntax first** — Run `sudo sshd -t` before restarting. A broken `sshd_config` can lock you out completely.
2. **Closing your session before testing** — Always keep your current SSH session open when testing. Open a second terminal to verify.
3. **Commenting out the line instead of changing the value** — `#PermitRootLogin no` is still commented out and won't apply. Make sure there's no `#` at the start.
4. **Only changing one server** — The task requires all 3 app servers. Verify each one individually.
5. **Forgetting to restart sshd** — The config file change does nothing until the daemon is reloaded.

---

## 🔍 Key `sshd_config` Directives Reference

```bash
PermitRootLogin no          # Disables direct root SSH login
PasswordAuthentication no   # Forces key-based auth only (next level hardening)
MaxAuthTries 3              # Limits brute force attempts
AllowUsers tony steve banner # Whitelist only specific users
Protocol 2                  # Use SSHv2 only (v1 is broken)
```

> These are the most impactful SSH hardening options. Together, they form the baseline for any production server.

---

## 🔗 References

- [CIS Benchmark for Linux — SSH Hardening](https://www.cisecurity.org/cis-benchmarks/)
- [`sshd_config` man page](https://man.openbsd.org/sshd_config)
- [NIST Guidelines for SSH](https://nvlpubs.nist.gov/nistpubs/ir/2015/nist.ir.7966.pdf)
- [Red Hat SSH Security Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/securing_networks/making-openssh-more-secure_securing-networks)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
