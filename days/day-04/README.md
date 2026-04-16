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

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: A deployment pipeline copies a script to a server but it fails with "Permission denied" when executed. What's the diagnostic and fix?**

```bash
# Diagnose
ls -l /path/to/script.sh
# -rw-r--r-- 1 root root 1234 Jan 28 script.sh  ← no x bit

# Fix
chmod 755 /path/to/script.sh

# Verify
ls -l /path/to/script.sh
# -rwxr-xr-x 1 root root 1234 Jan 28 script.sh  ✅
```

> In CI/CD pipelines, files are typically pushed without execute permission as a security practice — the permission is then explicitly set as a controlled step. This is intentional, not a bug.

---

**Q2: What's the difference between `chmod +x` and `chmod 755`? Which should you use in production?**

> `chmod +x` adds execute bit relative to the current permissions — if a file was `640`, it becomes `750`. `chmod 755` sets permissions absolutely — always results in `rwxr-xr-x` regardless of current state.
>
> For production scripts: **use `chmod 755` (octal) for precision**. It's explicit, predictable, and idempotent. You always know exactly what you're setting.

---

**Q3: Why is `chmod 777` considered dangerous and when is it ever acceptable?**

> `777` grants write permission to everyone — any user on the system can modify or overwrite the file. This creates risks:
> - Malicious user overwrites a script that runs as root
> - Accidental modification during concurrent access
> - SELinux and some security tools flag `777` files
>
> It's almost never acceptable in production. The only legitimate use case is a temporary shared scratch directory — and even then, a sticky bit (`chmod 1777`) is the correct approach, not `777`.

---

**Q4: In an Ansible playbook, how do you set correct permissions on a deployed script?**

```yaml
- name: Deploy backup script
  ansible.builtin.copy:
    src: backup.sh
    dest: /scripts/backup.sh
    owner: tony
    group: tony
    mode: '0755'
```

> The `mode` parameter accepts octal strings (`'0755'`) or symbolic (`'u+x'`). Octal is preferred for clarity. Setting `owner` and `mode` in the same task ensures the file is correct in one shot — no separate `chmod` step needed.

---

**Q5: How does the execute bit on a directory work differently than on a file?**

> On a **file**, execute means you can run it as a program.
> On a **directory**, execute means you can `cd` into it and access its contents. Without the execute bit on a directory, even if you have read permission, you can list the directory (`ls`) but cannot access any files inside.
>
> This is why directory permissions are typically `755` (not `644`) — the `x` bit is needed for traversal, not just listing.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
