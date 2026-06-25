# Day 74 — Jenkins Automated Database Backup: mysqldump + Scheduled Transfer

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** CI/CD / Jenkins / Database Backup / Automation  
**Difficulty:** Intermediate  
**Phase:** Phase 5 — Advanced Kubernetes & CI/CD  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create a Jenkins job `database-backup` that:
- Runs automatically every 10 minutes (`*/10 * * * *`)
- Takes a mysqldump of `kodekloud_db01` on App Server 1 (`stapp01`)
- Names the dump `db_$(date +%F).sql` (current date in YYYY-MM-DD format)
- Copies the dump to `/home/natasha/db_backups/` on Storage Server (`ststor01`)

---

## 🧠 Concept — Automated Database Backup

### Why Automate Database Backups with Jenkins?

Database backups are critical but frequently skipped when manual — "we'll do it before the next deployment" becomes "why didn't we have a backup when the disk failed?" Jenkins scheduled jobs make backups automatic, auditable (Console Output), and alertable (build failure notifications). 

```
Manual backup approach:
  Engineer SSHes to app server
  Runs mysqldump manually
  SCPs to storage server manually
  No consistency, no schedule, no audit trail

Jenkins automated approach:
  Runs every 10 minutes automatically
  Console Output = audit log of every backup attempt
  Build failure email/notification if backup fails
  Historical build list shows backup success/failure over time
```

### `mysqldump` — MySQL's Backup Utility

```bash
mysqldump -u USER -pPASSWORD DATABASE > output.sql
```

| Flag | Purpose |
|------|---------|
| `-u kodekloud_roy` | Database user |
| `-pasdfgdsd` | Password (no space between `-p` and password) |
| `kodekloud_db01` | Database name to dump |
| `> /tmp/db_$(date +%F).sql` | Output file with date in name |

**`date +%F`** outputs `YYYY-MM-DD` format — e.g., `2026-06-25`. The dump filename becomes `db_2026-06-25.sql`.

> ⚠️ **`-p` password syntax:** There is **no space** between `-p` and the password: `-pasdfgdsd`. Writing `-p asdfgdsd` (with a space) makes mysql prompt for a password interactively instead of reading it from the argument — the automated script hangs.

### Backup File Naming Strategy

```bash
db_$(date +%F).sql           → db_2026-06-25.sql
db_$(date +%FT%H:%M:%S).sql  → db_2026-06-25T14:30:00.sql (with time)
db_$(date +%Y%m%d_%H%M%S).sql → db_20260625_143000.sql (compact format)
```

`date +%F` (date only) means running the job 144 times per day (every 10 min) **overwrites the same file each time** — only the most recent backup of each day is kept. Running every 10 minutes with date+time in the filename keeps 144 separate files per day. The task specifies `date +%F` so we use that.

### The Data Flow

```
Jenkins (*/10 * * * *)
  │
  │  Publish Over SSH
  ▼
stapp01 (tony) — exec commands:
  1. Install sshpass (if needed)
  2. mkdir /home/natasha/db_backups on ststor01
  3. mysqldump kodekloud_db01 → /tmp/db_$(date +%F).sql
  4. sshpass scp /tmp/db_$(date +%F).sql → ststor01:/home/natasha/db_backups/
```

> **Real-world context:** Automated database backups are a foundational DevOps responsibility. Every database that has business-critical data needs: scheduled backups (RPO — Recovery Point Objective), tested restoration procedures, backup validation (not just running mysqldump but verifying the output can be restored), off-site storage (backups not on the same server as the database), and alerting when backups fail. This task implements the scheduling and copying; a production implementation would additionally compress the dump, validate its size is non-zero, test restoration on a separate DB server, and retain backups for a configurable period (7 days, 30 days, etc.).

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Jenkins job | `database-backup` (Freestyle) |
| Schedule | `*/10 * * * *` (every 10 min) |
| Source | stapp01 (tony/Ir0nM@n) |
| Database | `kodekloud_db01` |
| DB user | `kodekloud_roy` / `asdfgdsd` |
| Dump name | `db_$(date +%F).sql` |
| Destination | ststor01 (natasha/Bl@kW) |
| Destination path | `/home/natasha/db_backups/` |

---

## 🔧 Solution — Step by Step

### Step 1: Configure App Server 1 SSH connection

```
Manage Jenkins → System → Publish over SSH → Add:
  Name: app-server-1
  Hostname: stapp01
  Username: tony
  Password: Ir0nM@n (Advanced)
  Test Configuration → Success ✅
→ Save
```

### Step 2: Create job and set schedule

```
New Item → database-backup → Freestyle project → OK
Build Triggers → ☑ Build periodically
  Schedule: */10 * * * *
```

### Step 3: Add SSH build step

```
Build Steps → Send files or execute commands over SSH
  SSH Server: app-server-1
  Exec command:
    sudo yum install -y sshpass 2>/dev/null || true
    sshpass -p 'Bl@kW' ssh -o StrictHostKeyChecking=no \
      natasha@ststor01 "mkdir -p /home/natasha/db_backups"
    mysqldump -u kodekloud_roy -pasdfgdsd kodekloud_db01 \
      > /tmp/db_$(date +%F).sql
    sshpass -p 'Bl@kW' scp -o StrictHostKeyChecking=no \
      /tmp/db_$(date +%F).sql \
      natasha@ststor01:/home/natasha/db_backups/
→ Save
```

### Step 4: Build Now and verify

```bash
# Jenkins: Build Now → Console Output → SUCCESS ✅

# On ststor01 (verification):
ssh natasha@ststor01
ls -lh /home/natasha/db_backups/
# db_2026-06-25.sql  (non-zero size) ✅

head -3 /home/natasha/db_backups/db_$(date +%F).sql
# Expected:
# -- MySQL dump 10.xx, for Linux...
# -- Host: localhost    Database: kodekloud_db01
```

---

## 📌 Verification Checklist

```
☑ app-server-1 (stapp01) configured in Publish Over SSH and tested
☑ Job "database-backup" created as Freestyle project
☑ Schedule set to */10 * * * * exactly
☑ SSH build step with mysqldump and scp commands
☑ Build Now → SUCCESS
☑ Console Output confirms: mysqldump ran, scp transferred
☑ db_YYYY-MM-DD.sql exists at /home/natasha/db_backups/ on ststor01
☑ File is non-zero size (actual dump content)
```

---

## ⚠️ Common Mistakes to Avoid

1. **Space in mysql password flag** — `-p asdfgdsd` (space) = interactive prompt, script hangs. `-pasdfgdsd` (no space) = reads from argument, works in automation.
2. **Destination directory missing** — `scp` fails silently or with error if `/home/natasha/db_backups/` doesn't exist. Always `mkdir -p` before scp.
3. **Dump file overwriting** — `date +%F` uses only the date, so multiple runs per day overwrite the same file. Intentional per the task requirements. If you need per-run files, use `date +%F_%H%M%S`.
4. **mysqldump output going to wrong path** — `> /tmp/db_$(date +%F).sql` redirects stdout to file. If `mysqldump` fails (wrong password, wrong DB name), it writes an error message to the .sql file instead of SQL — the file exists but contains no usable data. Always verify file content, not just file existence.
5. **Schedule format** — Task requires exactly `*/10 * * * *`. Using `H/10 * * * *` (Jenkins hash form) is technically equivalent but the task validation checks for the specific literal string.

---

## 🔍 Exec Command Step by Step

```bash
# 1. Install sshpass (silently, don't fail if already installed)
sudo yum install -y sshpass 2>/dev/null || true

# 2. Ensure destination directory exists on storage server
sshpass -p 'Bl@kW' ssh -o StrictHostKeyChecking=no \
  natasha@ststor01 "mkdir -p /home/natasha/db_backups"
# Runs on ststor01: creates /home/natasha/db_backups if it doesn't exist

# 3. Create the database dump on stapp01
mysqldump -u kodekloud_roy -pasdfgdsd kodekloud_db01 \
  > /tmp/db_$(date +%F).sql
# date +%F = YYYY-MM-DD (e.g., 2026-06-25)
# Output: /tmp/db_2026-06-25.sql

# 4. Copy dump to storage server
sshpass -p 'Bl@kW' scp -o StrictHostKeyChecking=no \
  /tmp/db_$(date +%F).sql \
  natasha@ststor01:/home/natasha/db_backups/
# Transfers the file from stapp01 to ststor01
```

All commands execute **on stapp01** — that's the Publish Over SSH target.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is `mysqldump` and what does it produce?**

`mysqldump` is MySQL's logical backup utility — it exports a database as SQL statements: `CREATE TABLE`, `INSERT INTO`, etc. The resulting `.sql` file can recreate the database from scratch on any MySQL instance by executing the statements in order. Physical backups (like Percona XtraBackup) copy raw InnoDB files — faster for large databases but require the same MySQL version and storage engine. Logical backups from `mysqldump` are portable across MySQL versions and easy to inspect in a text editor. For smaller databases (under a few GB), mysqldump is the standard approach. For multi-terabyte production databases with strict RTO/RPO requirements, tools like Percona XtraBackup or AWS RDS automated snapshots are more appropriate.

---

**Q2: Why does `-p` with no space work differently than `-p ` (with space) in MySQL commands?**

MySQL's command-line tools (`mysql`, `mysqldump`, `mysqladmin`) follow a specific parsing rule for the `-p` flag: if the password follows immediately with no space (`-pasdfgdsd`), it's read from the command-line argument. If there's a space (`-p asdfgdsd`) or just `-p` alone, MySQL ignores anything after the space as a password argument and instead prompts interactively for the password. In automated scripts where there's no interactive terminal to receive the prompt, the script hangs indefinitely waiting for keyboard input that never arrives. This is one of the most common causes of MySQL automation scripts failing silently — the process is alive but blocking on stdin.

---

**Q3: What are the RPO and RTO considerations for a database backup job running every 10 minutes?**

RPO (Recovery Point Objective) is how much data you can afford to lose — a 10-minute schedule means at worst 10 minutes of data is unrecoverable if the database fails between backups. For a busy transactional database, losing 10 minutes of orders or user data may be unacceptable; for a configuration database that changes infrequently, 10 minutes (or even hours) may be acceptable. RTO (Recovery Time Objective) is how quickly you can restore — a mysqldump file is restored with `mysql -u user -p database < backup.sql`, but large dumps can take significant time to import. Point-in-time recovery using MySQL binary logs allows restoring to the exact second before failure, at the cost of additional complexity.

---

**Q4: How would you validate that a database backup is usable, not just that the file exists?**

File existence and non-zero size are necessary but insufficient — a failed `mysqldump` writes error messages to the .sql file, so the file exists but contains no usable SQL. Better validation: check file size is above a minimum threshold (`[ $(stat -c%s backup.sql) -gt 1000 ]`), verify the file starts with the MySQL dump header (`head -1 backup.sql | grep -q "MySQL dump"`), and for critical databases, restore the dump to a test database and run row counts. In production, backup validation (automated test restoration) runs separately from backup creation, typically nightly or weekly, using the most recent backup. A backup that's never been test-restored is a backup of unknown quality.

---

**Q5: How would you add backup retention to this job — keeping only the last 7 days of backups?**

Add a cleanup command at the end of the exec script:
```bash
# Remove backups older than 7 days
sshpass -p 'Bl@kW' ssh -o StrictHostKeyChecking=no natasha@ststor01 \
  "find /home/natasha/db_backups/ -name 'db_*.sql' -mtime +7 -delete"
```
`find -mtime +7` matches files modified more than 7 days ago. This runs after every backup, pruning old files automatically. Since `date +%F` creates one file per day, this keeps 7 files. For multiple runs per day (using date+time in filename), adjust the logic to keep the most recent N files per day or use a different retention policy. Retention management is critical — without it, backup directories fill disk over time.

---

**Q6: How would you alert the on-call team if a database backup fails?**

Jenkins provides several notification options: (1) **Email Notification** — configure Post-build Actions → E-mail Notification → send email when build fails. (2) **Slack Notification plugin** — post to a `#ops-alerts` channel when the backup job fails. (3) **PagerDuty Integration** — trigger a PagerDuty incident for backup failures that require immediate attention. (4) **Jenkins build history monitoring** — external monitoring (Datadog, Prometheus via Jenkins Prometheus plugin) tracks failed build rate and alerts when the backup job hasn't succeeded in over N minutes. The critical alert threshold: if the backup job hasn't succeeded in the last 30 minutes (3 scheduled runs), something is wrong. Combined with build timestamps, this creates a reliable backup monitoring signal.

---

## 🔗 References

- [mysqldump Documentation](https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html)
- [Jenkins Build Triggers](https://www.jenkins.io/doc/book/pipeline/syntax/#triggers)
- [Publish Over SSH Plugin](https://plugins.jenkins.io/publish-over-ssh/)
- [MySQL Backup Strategies](https://dev.mysql.com/doc/refman/8.0/en/backup-types.html)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
