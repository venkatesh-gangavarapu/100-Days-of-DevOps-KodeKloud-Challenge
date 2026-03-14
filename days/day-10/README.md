# Day 10 — Writing a Bash Backup Script with Remote SCP Copy

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Bash Scripting / Backup Automation  
**Difficulty:** Intermediate  
**Status:** ✅ Completed

---

## 📋 Task Summary

The `xFusionCorp Industries` production support team needed a bash script to automate static website backups on **App Server 1** (`stapp01`). The script must:

- Create a zip archive of `/var/www/html/news`
- Save it locally at `/backup/xfusioncorp_news.zip`
- Copy it to **Nautilus Storage Server** (`ststor01`) at `/backup/`
- Run without any password prompts
- Never use `sudo` internally
- Be executable by user `tony`
- Live at `/scripts/news_backup.sh`

---

## 🧠 Concept — Backup Automation Fundamentals

### Why Automate Backups This Way?

In production, backup scripts follow a two-destination pattern — a **local copy** for fast recovery and a **remote copy** for resilience. If the local server fails, the remote copy survives. This is the foundation of the **3-2-1 backup rule**:

```
3 copies of data
2 on different storage media
1 offsite (or on a separate server)
```

In this task:
- Local `/backup/` = fast local recovery (cleared weekly)
- Remote `/backup/` on `ststor01` = durable offsite copy

### Key Bash Scripting Principles Applied

| Principle | Application |
|-----------|------------|
| Variables for config | All paths and hosts defined at the top — easy to maintain |
| No hardcoded credentials | Passwordless SSH handles auth — no passwords in the script |
| No sudo | Script runs entirely as `tony` — permissions set correctly on dirs |
| Single responsibility | Script does one thing: archive and ship |

### Why No `sudo` in the Script?

Using `sudo` inside automated scripts creates problems:
- Requires TTY or `NOPASSWD` sudoers entry — fragile in automation
- Runs parts of the script as root unnecessarily — violates least privilege
- Breaks when run from cron jobs which don't have an interactive TTY

The correct pattern: set correct ownership on `/backup/` and `/scripts/` for the running user — then the script never needs escalation.

### How Passwordless SCP Works

SCP uses the same key-based authentication as SSH. Once `ssh-copy-id` has placed `tony`'s public key in `natasha@ststor01:~/.ssh/authorized_keys`, any `scp` or `ssh` command from `tony@stapp01` to `natasha@ststor01` works without a password — including inside automated scripts and cron jobs.

> **Real-world context:** This exact pattern — zip, local save, SCP to remote — is how many small-to-medium teams handled website backups before moving to cloud object storage (S3, GCS). Even today, understanding this pattern is essential because it underpins more sophisticated solutions: the logic is the same, only the transport layer changes (rsync, s3cmd, rclone instead of scp).

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| App Server 1 | `stapp01` — user `tony` |
| Storage Server | `ststor01` — user `natasha` |
| Source Directory | `/var/www/html/news` |
| Archive Name | `xfusioncorp_news.zip` |
| Local Backup Path | `/backup/` on `stapp01` |
| Remote Backup Path | `/backup/` on `ststor01` |
| Script Location | `/scripts/news_backup.sh` |

---

## 🔧 Solution — Step by Step

### Pre-requisites (manual steps outside the script)

#### Step 1: SSH into App Server 1

```bash
ssh tony@stapp01
```

#### Step 2: Install the zip package

```bash
sudo yum install -y zip
```

> The `zip` binary must exist on the system before the script runs. The task explicitly requires manual installation outside the script.

#### Step 3: Create required directories and set ownership

```bash
sudo mkdir -p /scripts /backup
sudo chown tony:tony /scripts /backup
```

This is what makes `sudo`-free script execution possible — `tony` owns both directories and can write to them directly.

#### Step 4: Set up passwordless SSH to the Storage Server

```bash
# Generate key pair if not already present
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Copy public key to storage server (enter password once)
ssh-copy-id natasha@ststor01

# Verify passwordless access
ssh natasha@ststor01 "hostname"
# Expected: ststor01 (no password prompt)
```

#### Step 5: Ensure `/backup/` exists on the Storage Server

```bash
ssh natasha@ststor01 "mkdir -p /backup"
```

---

### The Script — `/scripts/news_backup.sh`

```bash
#!/bin/bash
# news_backup.sh
# Purpose    : Create zip archive of /var/www/html/news and copy to local + remote backup
# Author     : tony (App Server 1)
# Location   : /scripts/news_backup.sh
# Note       : No sudo used. Passwordless SSH to ststor01 must be pre-configured.

# ─── Variables ────────────────────────────────────────────
SOURCE_DIR="/var/www/html/news"
ARCHIVE_NAME="xfusioncorp_news.zip"
LOCAL_BACKUP="/backup"
REMOTE_USER="natasha"
REMOTE_HOST="ststor01"
REMOTE_BACKUP="/backup"

# ─── Step 1: Create zip archive of the source directory ───
zip -r "${LOCAL_BACKUP}/${ARCHIVE_NAME}" "${SOURCE_DIR}"

# ─── Step 2: Copy archive to Nautilus Storage Server ──────
scp "${LOCAL_BACKUP}/${ARCHIVE_NAME}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BACKUP}/"
```

#### Step 6: Write the script to the server

```bash
vi /scripts/news_backup.sh
# Paste the script content and save
```

#### Step 7: Make it executable by tony

```bash
chmod 755 /scripts/news_backup.sh
```

#### Step 8: Run the script

```bash
bash /scripts/news_backup.sh
```

#### Step 9: Verify local archive exists

```bash
ls -lh /backup/xfusioncorp_news.zip
```

**Expected output:**
```
-rw-r--r-- 1 tony tony 12K Jan 28 10:00 /backup/xfusioncorp_news.zip
```

#### Step 10: Verify archive on Storage Server

```bash
ssh natasha@ststor01 "ls -lh /backup/xfusioncorp_news.zip"
```

**Expected output:**
```
-rw-r--r-- 1 natasha natasha 12K Jan 28 10:00 /backup/xfusioncorp_news.zip
```

✅ Backup created locally and copied remotely — no password prompts anywhere.

---

## 📌 Commands Reference

```bash
# ─── Pre-requisite Setup ──────────────────────────────────
sudo yum install -y zip                         # Install zip
sudo mkdir -p /scripts /backup                  # Create directories
sudo chown tony:tony /scripts /backup           # Set correct ownership
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" # Generate SSH key
ssh-copy-id natasha@ststor01                    # Push public key to storage server
ssh natasha@ststor01 "mkdir -p /backup"         # Ensure remote backup dir exists

# ─── Script Deployment ───────────────────────────────────
vi /scripts/news_backup.sh                      # Write the script
chmod 755 /scripts/news_backup.sh               # Make executable

# ─── Run & Verify ────────────────────────────────────────
bash /scripts/news_backup.sh                    # Execute script
ls -lh /backup/xfusioncorp_news.zip             # Verify local archive
ssh natasha@ststor01 "ls -lh /backup/"          # Verify remote archive

# ─── Useful zip commands ──────────────────────────────────
zip -r archive.zip /path/to/dir    # Recursive zip of a directory
unzip -l archive.zip               # List contents without extracting
unzip archive.zip -d /destination  # Extract to specific directory
```

---

## ⚠️ Common Mistakes to Avoid

1. **Using `sudo` inside the script** — Breaks in cron jobs (no TTY). Fix by setting correct ownership on target directories before scripting.
2. **Not setting up passwordless SSH before writing the script** — SCP inside the script will hang waiting for a password. Always test `ssh user@host "hostname"` before relying on it in automation.
3. **Hardcoding passwords in the script** — Never. Use SSH key-based auth for machine-to-machine transfers.
4. **Not using variables for paths** — Hardcoded paths across a script make maintenance painful. Define everything at the top as variables.
5. **Forgetting `chmod 755`** — A script without execute permission can't be run directly. Always verify with `ls -l /scripts/news_backup.sh`.
6. **Not verifying both destinations** — Always confirm both the local `/backup/` and the remote `/backup/` have the archive after the first run.

---

## 🔍 Script Design — Production Enhancements (Beyond the Task)

In a real production environment, this script would typically include:

```bash
#!/bin/bash

# Timestamped archives — prevents overwrites
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="xfusioncorp_news_${TIMESTAMP}.zip"

# Exit on any error
set -e

# Logging
LOG_FILE="/var/log/news_backup.log"
echo "[$(date)] Starting backup" >> "${LOG_FILE}"

# Error handling
if ! zip -r "${LOCAL_BACKUP}/${ARCHIVE_NAME}" "${SOURCE_DIR}"; then
    echo "[$(date)] ERROR: zip failed" >> "${LOG_FILE}"
    exit 1
fi

if ! scp "${LOCAL_BACKUP}/${ARCHIVE_NAME}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BACKUP}/"; then
    echo "[$(date)] ERROR: SCP failed" >> "${LOG_FILE}"
    exit 1
fi

echo "[$(date)] Backup completed: ${ARCHIVE_NAME}" >> "${LOG_FILE}"
```

These additions — timestamps, `set -e`, logging, and error handling — are what separate a production-grade script from a task submission.

---

## 🔗 References

- [`zip` man page](https://linux.die.net/man/1/zip)
- [`scp` man page](https://man7.org/linux/man-pages/man1/scp.1.html)
- [Bash Scripting Best Practices](https://google.github.io/styleguide/shellguide.html)
- [3-2-1 Backup Strategy](https://www.backblaze.com/blog/the-3-2-1-backup-strategy/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
