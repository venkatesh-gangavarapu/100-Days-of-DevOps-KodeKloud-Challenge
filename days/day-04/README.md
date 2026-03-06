# Day 04 — Granting Executable Permissions to a Bash Script

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Linux File Permissions  
**Difficulty:** Beginner  
**Status:** ✅ Completed

---

## 📋 Task Summary

A backup automation script `xfusioncorp.sh` was deployed to `/tmp/` on **App Server 2** (`stapp02`) but was missing executable permissions. The task was to grant execute permissions for **all users** so the script can be run by anyone on the system.

---

## 🧠 Concept — Linux File Permissions

Every file and directory in Linux has a permission set made up of **three triads** — for the **owner**, the **group**, and **others (everyone else)**. Each triad contains three bits: **read (r)**, **write (w)**, and **execute (x)**.

### Reading `ls -l` output

```
-rwxr-xr-x  1  root  root  35  Jan 28  /tmp/xfusioncorp.sh
│├─┤├─┤├─┤
│ │  │  └── Others  : r-x
│ │  └───── Group   : r-x
│ └──────── Owner   : rwx
└────────── File type: - (regular file), d (directory), l (symlink)
```

### Octal Permission Reference

| Octal | Binary | Permission |
|-------|--------|------------|
| 7 | 111 | rwx — read, write, execute |
| 6 | 110 | rw- — read, write |
| 5 | 101 | r-x — read, execute |
| 4 | 100 | r-- — read only |
| 0 | 000 | --- — no permissions |

So `chmod 755` breaks down as:
- Owner → `7` → `rwx`
- Group → `5` → `r-x`
- Others → `5` → `r-x`

### Two Ways to Set Permissions

| Method | Example | Best For |
|--------|---------|---------|
| **Symbolic** | `chmod +x file` | Quick additions/removals |
| **Octal** | `chmod 755 file` | Explicit, precise control |

> **Real-world context:** Scripts deployed by automation tools — Ansible, Jenkins pipelines, deployment agents — frequently arrive on servers without execute permissions. This is actually intentional in many pipelines: files are pushed first, then permissions are set explicitly as a separate controlled step. You'll run `chmod` more times in your career than you can count.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 2 (`stapp02`) |
| Datacenter | Stratos Datacenter |
| User | steve |
| Target File | `/tmp/xfusioncorp.sh` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 2

```bash
ssh steve@stapp02
```

### Step 2: Check current permissions

```bash
ls -l /tmp/xfusioncorp.sh
```

**Output (before fix):**
```
-rw-r--r-- 1 root root 35 Jan 28 /tmp/xfusioncorp.sh
```

No `x` bit anywhere — the file exists but cannot be executed by anyone.

### Step 3: Grant execute permission to all users

```bash
sudo chmod +x /tmp/xfusioncorp.sh
```

`+x` adds the execute bit for **owner, group, and others** simultaneously.

**Alternatively, using octal notation (explicit and preferred in production):**
```bash
sudo chmod 755 /tmp/xfusioncorp.sh
```

### Step 4: Verify the permissions changed

```bash
ls -l /tmp/xfusioncorp.sh
```

**Output (after fix):**
```
-rwxr-xr-x 1 root root 35 Jan 28 /tmp/xfusioncorp.sh
```

Execute bit is now set for owner (`rwx`), group (`r-x`), and others (`r-x`). ✅

### Step 5: Confirm the script executes

```bash
bash /tmp/xfusioncorp.sh
```

No `Permission denied` error = task complete. ✅

---

## 📌 Commands Reference

```bash
# Check current permissions
ls -l /tmp/xfusioncorp.sh

# Grant execute to all (symbolic)
sudo chmod +x /tmp/xfusioncorp.sh

# Grant execute to all (octal - explicit)
sudo chmod 755 /tmp/xfusioncorp.sh

# Verify
ls -l /tmp/xfusioncorp.sh

# Run the script to confirm
bash /tmp/xfusioncorp.sh

# ─── Useful chmod variations ───

# Execute for owner only
sudo chmod u+x file.sh

# Execute for group only
sudo chmod g+x file.sh

# Execute for others only
sudo chmod o+x file.sh

# Remove execute from everyone
sudo chmod -x file.sh

# Full permissions to owner, read-execute to group and others
sudo chmod 755 file.sh

# Full permissions to everyone (use with caution)
sudo chmod 777 file.sh

# Check permissions in octal format
stat -c "%a %n" /tmp/xfusioncorp.sh
```

---

## ⚠️ Common Mistakes to Avoid

1. **Using `chmod 777` blindly** — giving write permission to everyone is almost never the right answer. `755` gives execute to all without letting everyone modify the file.
2. **Forgetting `sudo`** — if the file is owned by root, you need elevated privileges to change its permissions.
3. **Not verifying after the change** — always run `ls -l` after `chmod` to confirm what actually changed.
4. **Confusing file permissions with directory permissions** — execute on a directory means the ability to `cd` into it, not run it. Different concept, same bit.

---

## 🔍 `chmod` Symbolic Notation Quick Reference

```
chmod [who][operator][permission] file

who:        u = owner (user), g = group, o = others, a = all
operator:   + = add, - = remove, = = set exactly
permission: r = read, w = write, x = execute
```

Examples:
```bash
chmod a+x file      # Add execute for everyone
chmod u+x,g-w file  # Add execute for owner, remove write from group
chmod o= file       # Remove all permissions from others
chmod a=rx file     # Set read+execute for all, remove write from all
```

---

## 🔗 References

- [`chmod` man page](https://man7.org/linux/man-pages/man1/chmod.1.html)
- [Linux File Permissions Explained — Red Hat](https://www.redhat.com/en/blog/linux-file-permissions-explained)
- [Understanding `ls -l` output](https://www.cyberciti.biz/faq/understanding-unix-linux-bsd-file-permissions/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
