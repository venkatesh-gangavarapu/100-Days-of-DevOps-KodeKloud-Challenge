# Day 06 — Installing Cronie & Scheduling Cron Jobs on All App Servers

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Linux Task Scheduling / Automation  
**Difficulty:** Beginner–Intermediate  
**Status:** ✅ Completed

---

## 📋 Task Summary

The `Nautilus` sysadmin team needs to validate cron-based automation before rolling out scheduled scripts across the fleet. The task was to:

1. Install the `cronie` package on **all 3 App Servers** in Stratos DC
2. Start and enable the `crond` service
3. Add a cron job `*/5 * * * * echo hello > /tmp/cron_text` for the `root` user

---

## 🧠 Concept — Cron & Task Scheduling in Linux

**Cron** is the native Linux job scheduler. It reads schedule definitions from **crontab files** and executes commands at the specified times — without any manual intervention. It's the foundation of operational automation on Linux systems.

### `cronie` vs `cron` — What's the difference?

| Package | Used On | Notes |
|---------|---------|-------|
| `cronie` | RHEL, CentOS, Fedora | Modern cron daemon — actively maintained |
| `cron` / `crontab` | Debian, Ubuntu | Traditional implementation |
| `fcron` | Various | Feature-rich alternative |

On RHEL/CentOS-based systems (which Stratos DC uses), the package is `cronie` and the service is `crond`.

### Anatomy of a Cron Expression

```
*/5  *    *    *    *    echo hello > /tmp/cron_text
 │   │    │    │    │    └── Command to execute
 │   │    │    │    └─────── Day of week  (0–7, 0 and 7 = Sunday)
 │   │    │    └──────────── Month        (1–12)
 │   │    └───────────────── Day of month (1–31)
 │   └────────────────────── Hour         (0–23)
 └────────────────────────── Minute       (0–59)
                                          */5 = every 5 minutes
```

### Common Cron Expression Patterns

| Expression | Meaning |
|-----------|---------|
| `*/5 * * * *` | Every 5 minutes |
| `0 * * * *` | Every hour (on the hour) |
| `0 2 * * *` | Every day at 2:00 AM |
| `0 2 * * 0` | Every Sunday at 2:00 AM |
| `0 0 1 * *` | First day of every month at midnight |
| `@reboot` | Once at system startup |
| `@daily` | Once per day (same as `0 0 * * *`) |

### Where Crontabs Live

```
/var/spool/cron/          → Per-user crontab files (e.g. /var/spool/cron/root)
/etc/crontab              → System-wide crontab (includes username field)
/etc/cron.d/              → Drop-in cron files for packages/applications
/etc/cron.hourly|daily|weekly|monthly/  → Script drop-in directories
```

> **Real-world context:** Cron is everywhere in production. Log rotation (`logrotate`), Let's Encrypt certificate renewal (`certbot renew`), database backups, metrics collection, disk cleanup, report generation — virtually all scheduled operational work runs through cron or a cron-compatible scheduler. Knowing how to install, configure, and debug it is foundational DevOps work.

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

### Step 2: Install the cronie package

```bash
sudo yum install -y cronie
```

### Step 3: Start and enable the crond service

```bash
sudo systemctl start crond
sudo systemctl enable crond
```

`enable` ensures `crond` starts automatically on every future reboot — not just this session.

### Step 4: Verify crond is running

```bash
sudo systemctl status crond
```

**Expected output:**
```
● crond.service - Command Scheduler
   Loaded: loaded (/usr/lib/systemd/system/crond.service; enabled)
   Active: active (running) since ...
```

### Step 5: Add the cron job for root user

**Method 1 — Non-interactive (scriptable, preferred for automation):**
```bash
echo "*/5 * * * * echo hello > /tmp/cron_text" | sudo crontab -u root -
```

**Method 2 — Interactive editor:**
```bash
sudo crontab -u root -e
# Add this line and save:
# */5 * * * * echo hello > /tmp/cron_text
```

### Step 6: Verify the cron entry is registered

```bash
sudo crontab -u root -l
```

**Expected output:**
```
*/5 * * * * echo hello > /tmp/cron_text
```

### Step 7: Confirm the job executes

After up to 5 minutes:
```bash
cat /tmp/cron_text
```

**Expected output:**
```
hello
```

✅ Cron job is live and executing.

**Repeat Steps 1–7 on `stapp02` (steve) and `stapp03` (banner).**

---

## 📌 Commands Reference

```bash
# Install cronie
sudo yum install -y cronie

# Service management
sudo systemctl start crond
sudo systemctl enable crond
sudo systemctl status crond
sudo systemctl restart crond

# Add cron job non-interactively (root user)
echo "*/5 * * * * echo hello > /tmp/cron_text" | sudo crontab -u root -

# List root's cron jobs
sudo crontab -u root -l

# Edit root's crontab interactively
sudo crontab -u root -e

# Remove all cron jobs for root (use carefully)
sudo crontab -u root -r

# List cron jobs for current user
crontab -l

# View cron execution logs
sudo tail -f /var/log/cron

# Verify cron output file
cat /tmp/cron_text

# Check where crontab is stored
cat /var/spool/cron/root
```

---

## ⚠️ Common Mistakes to Avoid

1. **Starting `crond` but not enabling it** — `systemctl start` runs it now; `systemctl enable` makes it survive reboots. Always do both.
2. **Forgetting `-u root`** — Running `crontab -e` without specifying the user edits the *current user's* crontab, not root's. Always specify `-u root` explicitly when managing root's jobs.
3. **Using `sudo crontab -e` without `-u root`** — This edits root's crontab via sudo but is less explicit. Using `-u root` is clearer and safer in scripts.
4. **Overwriting vs appending crontab** — The pipe method (`echo "..." | crontab -u root -`) **replaces** the entire crontab. If root already has jobs, use `crontab -u root -l` first, append, then pipe the full content back. Or use `-e` to edit safely.
5. **Not checking cron logs when jobs don't run** — `/var/log/cron` is your first stop for debugging. Check it before assuming the job is broken.

---

## 🔍 Debugging Cron Jobs

```bash
# Check if crond is running
systemctl is-active crond

# Watch cron logs live
sudo tail -f /var/log/cron

# Check for errors in syslog
sudo grep CRON /var/log/syslog

# Verify cron output file was written
ls -la /tmp/cron_text
cat /tmp/cron_text

# Test the command manually before trusting cron
echo hello > /tmp/cron_text && cat /tmp/cron_text
```

---

## 🔗 References

- [`crontab` man page](https://man7.org/linux/man-pages/man5/crontab.5.html)
- [cronie — Red Hat Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/automating_system_tasks/index)
- [Cron Expression Reference — crontab.guru](https://crontab.guru/)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: A cron job is not running even though `crond` is active and the crontab entry looks correct. How do you debug it?**

```bash
# Step 1: Confirm crond is actually running
systemctl is-active crond

# Step 2: Check cron execution logs
sudo tail -50 /var/log/cron
# Look for: (root) CMD (echo hello > /tmp/cron_text)

# Step 3: Test the command manually as the cron user
sudo su - root -c 'echo hello > /tmp/cron_text'

# Step 4: Check environment — cron has a minimal PATH
# Commands that work in your shell may fail in cron
# Solution: use full paths in cron jobs
# BAD:  */5 * * * * python backup.py
# GOOD: */5 * * * * /usr/bin/python3 /opt/scripts/backup.py
```

> 80% of cron debugging comes down to: PATH differences, no shell expansion, no TTY, and permissions. Always use absolute paths in cron jobs.

---

**Q2: What's the difference between `systemctl start crond` and `systemctl enable crond`? What happens if you only run `start`?**

> `start` launches the service right now in the current session. `enable` configures it to start automatically at every future boot. If you only run `start`, the service works until the next reboot — then it's gone. Always run both in sequence: `start` then `enable`, or use `systemctl enable --now crond` to do both in one command.

---

**Q3: A cron job runs fine manually but fails silently when executed by cron. What are the most common causes?**

> 1. **Missing PATH** — cron starts with `/usr/bin:/bin`. If your command is in `/usr/local/bin` or `/sbin`, use the full path.
> 2. **No HOME** — scripts that reference `~` or `$HOME` fail. Use absolute paths.
> 3. **No display/TTY** — scripts using interactive tools (editors, `sudo` requiring password) fail. Design scripts for non-interactive execution.
> 4. **Output discarded** — cron discards stdout/stderr unless you redirect or configure a `MAILTO`. Add `2>&1 >> /var/log/myjob.log` to capture errors.
> 5. **User environment not loaded** — `.bashrc` and `.bash_profile` are not sourced in cron. Set all required env vars explicitly in the crontab or script.

---

**Q4: How do you add a cron job non-interactively from a script or Ansible?**

```bash
# One-liner to add without replacing existing jobs
(crontab -u root -l 2>/dev/null; echo "*/5 * * * * echo hello > /tmp/cron_text") | crontab -u root -

# Ansible approach (idempotent)
- name: Add cron job
  ansible.builtin.cron:
    name: "echo hello every 5 min"
    minute: "*/5"
    job: "echo hello > /tmp/cron_text"
    user: root
    state: present
```

> The Ansible `cron` module is the cleanest approach — it's idempotent (won't duplicate on re-run) and uses the `name` field as a unique identifier. The bash one-liner works for ad-hoc use but can create duplicates if run multiple times.

---

**Q5: What's the `@reboot` cron directive and when would you use it in production?**

```bash
# Runs the command once at system startup
@reboot /opt/scripts/startup_check.sh

# Equivalent to:
# Nothing (no cron equivalent — @reboot is unique to cron)
```

> `@reboot` is used for: clearing stale lock files on boot, starting processes that systemd doesn't manage, running post-boot validation scripts, or triggering one-time setup tasks on first boot. It's simpler than writing a systemd service for short-lived startup tasks.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
