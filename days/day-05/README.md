# Day 05 — SELinux Installation & Permanent Disable (Pre-Configuration Phase)

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Linux Security / SELinux  
**Difficulty:** Intermediate  
**Status:** ✅ Completed

---

## 📋 Task Summary

As part of a security enhancement initiative at `xFusionCorp Industries`, SELinux is being introduced on **App Server 3** (`stapp03`) in the Stratos Datacenter. Before full enforcement can be configured, the team needs to:

1. Install the required SELinux packages
2. **Permanently** disable SELinux (will be re-enabled post-configuration)
3. No reboot required now — maintenance reboot is scheduled for tonight
4. Runtime state doesn't matter — only the **post-reboot state** must be `disabled`

---

## 🧠 Concept — SELinux & How It Works

**SELinux (Security-Enhanced Linux)** is a **Mandatory Access Control (MAC)** system built into the Linux kernel. Developed originally by the NSA, it enforces security policies that go beyond standard Unix file permissions.

### SELinux vs Standard Linux Permissions

| Feature | Standard DAC (chmod/chown) | SELinux MAC |
|---------|---------------------------|-------------|
| Control | File owner controls access | Kernel enforces policy |
| Root bypass | Root can override | Root is also subject to policy |
| Scope | Files & directories | Processes, ports, files, sockets |
| Granularity | User/Group/Others | Process-level labeling |

### The 3 SELinux Operating States

| State | Behaviour | Use Case |
|-------|-----------|---------|
| `enforcing` | Policies active, violations **blocked** | Production — fully hardened |
| `permissive` | Policies active, violations **logged only** | Testing — audit without breaking things |
| `disabled` | SELinux not loaded by kernel | Pre-configuration, compatibility testing |

### Runtime vs Permanent State — Critical Distinction

```
setenforce 0          → Sets permissive at RUNTIME only (resets on reboot)
setenforce 1          → Sets enforcing at RUNTIME only (resets on reboot)

/etc/selinux/config   → Sets the PERMANENT state (survives reboots)
```

> This is the most common SELinux mistake in production: engineers run `setenforce 0` to quickly fix an issue, think they've resolved it, and then the reboot brings it back. **Always update `/etc/selinux/config` for permanent changes.**

> **Real-world context:** In enterprise environments, SELinux is almost always enabled in `enforcing` mode — it's mandatory for RHEL systems in US government, DoD, and financial environments. But when teams first deploy new application stacks, they temporarily set it to `permissive` or `disabled`, configure policies using audit logs, then flip back to `enforcing`. This is exactly the workflow being set up here.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 3 (`stapp03`) |
| Datacenter | Stratos Datacenter |
| User | banner |
| OS | CentOS / RHEL-based |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 3

```bash
ssh banner@stapp03
```

### Step 2: Install required SELinux packages

```bash
sudo yum install -y selinux-policy selinux-policy-targeted libselinux libselinux-utils policycoreutils
```

**Package breakdown:**

| Package | Purpose |
|---------|---------|
| `selinux-policy` | Base SELinux policy framework |
| `selinux-policy-targeted` | Targeted policy (protects specific processes, not entire system) |
| `libselinux` | SELinux library for applications |
| `libselinux-utils` | Utilities: `getenforce`, `setenforce`, `sestatus` |
| `policycoreutils` | Core tools: `restorecon`, `semanage`, `setsebool` |

### Step 3: Check current SELinux status (awareness)

```bash
sestatus
```

**Output:**
```
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinuxfs root:                 /sys/fs/selinux
SELinux mount check:            enabled
Mount point labeled:            enabled
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Memory protection checking:     actual (secure)
Max kernel policy version:      33
```

Note: We're checking this for awareness only — the task says the runtime state doesn't matter.

### Step 4: Permanently disable SELinux in the config file

```bash
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
```

**Or manually edit:**
```bash
sudo vi /etc/selinux/config
# Change: SELINUX=enforcing
# To:     SELINUX=disabled
```

### Step 5: Verify the config file change

```bash
grep "^SELINUX=" /etc/selinux/config
```

**Expected output:**
```
SELINUX=disabled
```

### Step 6: Confirm full config file looks correct

```bash
cat /etc/selinux/config
```

**Expected output:**
```bash
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
SELINUXTYPE=targeted
```

✅ After tonight's scheduled reboot, SELinux will come up as `disabled`.

---

## 📌 Commands Reference

```bash
# Install SELinux packages
sudo yum install -y selinux-policy selinux-policy-targeted \
  libselinux libselinux-utils policycoreutils

# Check current SELinux status
sestatus
getenforce        # Quick: returns Enforcing / Permissive / Disabled

# Permanently disable via sed (clean, scriptable)
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

# Verify config change
grep "^SELINUX=" /etc/selinux/config

# View full config file
cat /etc/selinux/config

# ─── Runtime-only changes (do NOT use for permanent changes) ───
sudo setenforce 0    # Set permissive (runtime only — resets on reboot)
sudo setenforce 1    # Set enforcing  (runtime only — resets on reboot)

# ─── Bonus: Post-reboot verification command ───
# After reboot, run this to confirm disabled state:
sestatus
# Should show: SELinux status: disabled
```

---

## ⚠️ Common Mistakes to Avoid

1. **Using `setenforce 0` for a "permanent" fix** — This is runtime only. It resets on every reboot. The permanent fix is always in `/etc/selinux/config`.
2. **Confusing `SELINUX=disabled` with `SELINUX=permissive`** — Permissive still loads the policy (just doesn't enforce it). Disabled means the kernel doesn't load SELinux at all. They are fundamentally different states.
3. **Editing `SELINUXTYPE` instead of `SELINUX`** — `SELINUXTYPE` defines the policy type (`targeted`, `mls`). `SELINUX` defines the operational state. Make sure you're editing the right line.
4. **Not verifying with `grep` after the edit** — Always confirm the line was changed correctly before assuming the job is done.
5. **Expecting the change to apply immediately** — `disabled` only takes full effect after a reboot because the kernel has already loaded SELinux modules at boot time.

---

## 🔍 `/etc/selinux/config` Field Reference

```bash
SELINUX=disabled        # Operational state: enforcing | permissive | disabled
SELINUXTYPE=targeted    # Policy type:
                        #   targeted = protects specific network-facing daemons
                        #   mls      = Multi-Level Security (government/military grade)
                        #   minimum  = lightweight subset of targeted
```

---

## 🔗 References

- [SELinux User and Administrator's Guide — Red Hat](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux/)
- [`sestatus` man page](https://man7.org/linux/man-pages/man8/sestatus.8.html)
- [SELinux Project Wiki](https://selinuxproject.org/page/Main_Page)
- [CIS RHEL Benchmark — SELinux Controls](https://www.cisecurity.org/cis-benchmarks/)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: A junior engineer runs `setenforce 0` to fix an SELinux-blocked service in production. What's wrong with this, and what should they have done instead?**

> `setenforce 0` only changes the runtime state — it reverts to `enforcing` on the next reboot. The real problem is unresolved: the service is still misconfigured or missing the right SELinux context.
>
> The correct approach: use `audit2allow` to understand *why* SELinux blocked the operation, then either fix the file context with `restorecon` or create a proper policy module. Disabling enforcement hides the problem without fixing it — and the next reboot brings it back.

---

**Q2: What is the difference between `SELINUX=disabled`, `SELINUX=permissive`, and `SELINUX=enforcing`? When would you use each?**

| State | Behaviour | Use Case |
|-------|-----------|---------|
| `enforcing` | Blocks and logs violations | Production — fully hardened |
| `permissive` | Logs violations only | Troubleshooting — see what would be blocked |
| `disabled` | SELinux not loaded | Pre-configuration, compatibility testing |

> In production, always run `enforcing`. Use `permissive` temporarily to diagnose issues — never as a permanent state. `disabled` is rare: only for environments where SELinux is being phased out after careful planning.

---

**Q3: How do you diagnose what SELinux is blocking without disabling it?**

```bash
# Check for recent SELinux denials
sudo ausearch -m avc -ts recent

# Or read the audit log directly
sudo grep "denied" /var/log/audit/audit.log | tail -20

# Get human-readable explanation
sudo audit2why < /var/log/audit/audit.log

# See what context a file has
ls -Z /path/to/file

# See what context a process has
ps auxZ | grep httpd
```

> The audit log is your best friend. `audit2why` explains denials in plain English — it tells you exactly which policy rule triggered and often suggests a fix.

---

**Q4: After copying files to `/var/www/html/`, Apache returns 403 Forbidden even though permissions are correct. What's the SELinux fix?**

```bash
# Files copied from /tmp/ retain tmp_t label — Apache can't read them
ls -Z /var/www/html/
# system_u:object_r:tmp_t:s0  index.html  ← wrong label

# Fix: restore correct context
sudo restorecon -Rv /var/www/html/
# system_u:object_r:httpd_sys_content_t:s0  index.html  ✅
```

> This is the most common SELinux issue for web engineers. Files copied or moved from non-standard locations inherit the source label. `restorecon` applies the correct context based on the directory's policy.

---

**Q5: How do you permanently disable SELinux in a way that survives a reboot?**

```bash
# Edit the config file
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

# Verify
grep "^SELINUX=" /etc/selinux/config
# SELINUX=disabled

# Note: setenforce 0 is runtime only — does NOT survive reboot
# The config file change takes effect after the next reboot
```

> The only permanent change is in `/etc/selinux/config`. `setenforce 0` is frequently misunderstood as a "fix" — it's a temporary workaround that resets at every boot.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
