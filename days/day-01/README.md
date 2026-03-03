# Day 01 — Creating a Non-Interactive Shell User on Linux

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Linux User Management  
**Difficulty:** Beginner  
**Status:** ✅ Completed

---

## 📋 Task Summary

The backup agent tool used by `xFusionCorp Industries` requires a dedicated system user that the tool can operate under — but this user should **never be accessible as an interactive login account.** The task was to create a user named `rose` with a non-interactive shell on **App Server 1**.

---

## 🧠 Concept — What is a Non-Interactive Shell?

In Linux, every user account has an assigned shell. For human users, this is typically `/bin/bash` or `/bin/zsh` — shells you can interact with. But for **service accounts, backup agents, or daemon users**, you don't want anyone (or anything) logging in interactively.

Two common non-interactive shell options:

| Shell | Behavior |
|-------|----------|
| `/sbin/nologin` | Returns the message: *"This account is currently not available."* — clean and informative |
| `/bin/false` | Simply exits with a failure code — no message |

**`/sbin/nologin` is preferred** in most enterprise environments because it communicates intent clearly, especially when someone accidentally tries to switch to that user.

> **Real-world context:** You'll see this pattern constantly — Jenkins service users, backup agents, monitoring daemons, database service accounts. Creating them with `/sbin/nologin` is a baseline security hygiene practice.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 1 (`stapp01`) |
| OS | CentOS / RHEL-based |
| Access | SSH via jump host |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 1

```bash
ssh tony@stapp01
```

### Step 2: Create the user with a non-interactive shell

```bash
sudo useradd -s /sbin/nologin rose
```

**Flag breakdown:**

| Flag | Purpose |
|------|---------|
| `useradd` | Command to create a new user |
| `-s /sbin/nologin` | Assigns `/sbin/nologin` as the login shell |
| `rose` | The username being created |

### Step 3: Verify the user entry in `/etc/passwd`

```bash
grep "rose" /etc/passwd
```

**Output:**
```
rose:x:1002:1002::/home/rose:/sbin/nologin
```

Reading this colon-separated output:

```
username : password : UID : GID : comment : home_dir : shell
rose     : x        : 1002: 1002:          : /home/rose: /sbin/nologin
```

The last field confirms `/sbin/nologin` is set. ✅

### Step 4: Confirm non-interactive behaviour

```bash
sudo su - rose
```

**Output:**
```
This account is currently not available.
```

Exactly what we want — the account exists and is functional for services, but cannot be logged into.

---

## 📌 Commands Reference

```bash
# Create user with non-interactive shell
sudo useradd -s /sbin/nologin rose

# Verify
grep "rose" /etc/passwd

# Test login is blocked
sudo su - rose

# Alternative: check the shell assignment only
getent passwd rose | cut -d: -f7
```

---

## ⚠️ Common Mistakes to Avoid

1. **Using `/bin/false` without understanding the difference** — Both work, but `/sbin/nologin` is the standard for service accounts in RHEL/CentOS environments.
2. **Forgetting to verify** — Always confirm with `grep` after creation. In a production system, unverified changes can cause downstream failures for the services depending on that account.
3. **Not using `sudo`** — `useradd` requires root privileges. Always escalate properly rather than logging in directly as root.

---

## 🔗 References

- [`useradd` man page](https://man7.org/linux/man-pages/man8/useradd.8.html)
- [Understanding `/etc/passwd` file format](https://www.cyberciti.biz/faq/understanding-etcpasswd-file-format/)
- [nologin vs /bin/false — Red Hat KB](https://access.redhat.com/solutions/111673)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
