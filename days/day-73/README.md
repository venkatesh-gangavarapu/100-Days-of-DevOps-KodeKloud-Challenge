# Day 73 — Jenkins Scheduled Job: Apache Log Collection & Centralization

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** CI/CD / Jenkins / Scheduling / Log Management  
**Difficulty:** Intermediate  
**Phase:** Phase 5 — Advanced Kubernetes & CI/CD  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create a Jenkins job `copy-logs` that:
- Runs automatically every 6 minutes (`*/6 * * * *`)
- Copies Apache `access_log` and `error_log` from App Server 3 (`stapp03`) at `/var/log/httpd/`
- Places them at `/usr/src/security/` on the Storage Server (`ststor01`)
- Verified by at least one successful manual build

---

## 🧠 Concept — Scheduled Builds & Centralized Log Collection

### Why Jenkins for Log Collection?

This pattern — using Jenkins as a scheduled task runner for infrastructure operations — is lightweight and familiar to teams already using Jenkins for CI/CD. Before investing in a full log aggregation stack (ELK, Splunk, Loki), collecting logs on a schedule gives the team access to logs for manual review.

```
Manual approach (before Jenkins):
  Engineer SSHes to each app server
  Downloads logs manually
  No schedule, no consistency

Jenkins scheduled collection:
  Runs every 6 minutes automatically
  Logs always available at /usr/src/security/
  Console Output provides execution audit trail
  No manual intervention required
```

### The Multi-Server Copy Problem

The challenge: Jenkins can easily SSH to one server. Copying files FROM one server TO another (stapp03 → ststor01) requires a bridge. Options:

```
Option A: SSH to stapp03, then sshpass+scp from stapp03 to ststor01
  Pro: One SSH hop, cleaner
  Con: Requires sshpass on stapp03

Option B: SSH to stapp03, copy to Jenkins workspace, then copy to ststor01
  Pro: No dependencies on stapp03 for ststor01 credentials
  Con: Two separate SSH steps, files transit Jenkins

Option C: Jenkins Execute Shell using local sshpass
  Pro: All controlled from Jenkins master
  Con: Requires sshpass on Jenkins server, SSH keys or credentials in script
```

Today's solution uses **Option A** — SSH to stapp03 via Publish Over SSH, then use `sshpass + scp` on stapp03 to push logs directly to ststor01. Single hop, single build step.

### Jenkins Build Scheduler — Cron Syntax

Jenkins uses a standard cron-like syntax for scheduled builds:

```
*/6 * * * *
│   │ │ │ └── Day of week (0=Sun, 7=Sun)
│   │ │ └──── Month (1-12)
│   │ └────── Day of month (1-31)
│   └──────── Hour (0-23)
└──────────── Minute (0-59)

*/6 * * * *   → every 6 minutes
*/10 * * * *  → every 10 minutes
0 * * * *     → top of every hour
0 2 * * *     → 2:00 AM daily
```

**Jenkins-specific `H` symbol:**

`H/6 * * * *` — Jenkins "hash" symbol distributes load. Instead of all jobs running at :00, :06, :12..., `H` picks a consistent but staggered offset per-job. For high-frequency schedules like log collection, `*/6` and `H/6` are both valid; the task requires `*/6`.

### Apache Default Log Locations

| Distribution | Log Path |
|-------------|----------|
| RHEL/CentOS | `/var/log/httpd/access_log` and `/var/log/httpd/error_log` |
| Ubuntu/Debian | `/var/log/apache2/access.log` and `/var/log/apache2/error.log` |

stapp03 uses RHEL/CentOS — path is `/var/log/httpd/`.

> **Real-world context:** The pattern here — centralized log collection before investing in dedicated tooling — is used everywhere. Jenkins runs nightly or periodic jobs to pull logs, rotate them, compress them, or ship them to S3. For teams already operating Jenkins, adding a scheduled log collection job is zero additional infrastructure cost. The production evolution is: scheduled copy → Fluentd/Filebeat tailing and streaming → full ELK/Loki stack. Today's task represents stage one of that progression.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Jenkins job | `copy-logs` (Freestyle) |
| Schedule | `*/6 * * * *` (every 6 min) |
| Source server | `stapp03` (banner/BigGr33n) |
| Source path | `/var/log/httpd/` |
| Destination server | `ststor01` (natasha/Bl@kW) |
| Destination path | `/usr/src/security/` |

---

## 🔧 Solution — Step by Step

### Step 1: Configure App Server 3 in Publish Over SSH

```
Manage Jenkins → System → Publish over SSH → Add:
  Name: app-server-3
  Hostname: stapp03
  Username: banner
  Password: BigGr33n (via Advanced)
  Test Configuration → Success ✅
```

### Step 2: Create job and set schedule

```
New Item → copy-logs → Freestyle project
Build Triggers → ☑ Build periodically
  Schedule: */6 * * * *
```

### Step 3: SSH build step

```
Build Steps → Send files or execute commands over SSH
  SSH Server: app-server-3
  Exec command:
    sudo yum install -y sshpass 2>/dev/null || true
    sshpass -p 'Bl@kW' scp -o StrictHostKeyChecking=no \
      /var/log/httpd/access_log \
      natasha@ststor01:/usr/src/security/
    sshpass -p 'Bl@kW' scp -o StrictHostKeyChecking=no \
      /var/log/httpd/error_log \
      natasha@ststor01:/usr/src/security/
→ Save
```

> **Note:** Ensure `/usr/src/security/` exists on ststor01 first:
> ```
> ssh natasha@ststor01 'sudo mkdir -p /usr/src/security'
> ```
> Or add this to the exec command if stapp03 can SSH to ststor01 without it:
> ```
> sshpass -p 'Bl@kW' ssh -o StrictHostKeyChecking=no natasha@ststor01 'sudo mkdir -p /usr/src/security'
> ```

### Step 4: Build Now and verify

```
Build Now → Console Output → SUCCESS ✅

ssh natasha@ststor01
ls -la /usr/src/security/
# access_log and error_log present ✅
```

---

## 📌 Verification Checklist

```
☑ Publish Over SSH plugin installed
☑ app-server-3 (stapp03) configured and tested in global settings
☑ Job "copy-logs" created as Freestyle project
☑ Build periodically set to */6 * * * *
☑ SSH build step executes scp of both log files to ststor01
☑ Manual build succeeds (Build Now)
☑ Console Output shows no errors
☑ access_log and error_log present at /usr/src/security/ on ststor01
☑ Schedule confirmed — next runs visible in job's build history
```

---

## ⚠️ Common Mistakes to Avoid

1. **Wrong cron expression** — `6 * * * *` means "at minute 6 of every hour," not "every 6 minutes." The correct expression for every 6 minutes is `*/6 * * * *` (the `*/` means "every").
2. **Wrong Apache log path** — RHEL/CentOS uses `/var/log/httpd/`. Ubuntu uses `/var/log/apache2/`. Match the distribution running on stapp03.
3. **Destination directory doesn't exist** — `scp` fails with "no such file or directory" if `/usr/src/security/` doesn't exist on ststor01. Create it first via SSH before the scp commands.
4. **sshpass not installed** — If `sshpass` isn't on stapp03, the scp command fails. Add `sudo yum install -y sshpass` at the top of the exec command, or use a pre-configured SSH key.
5. **StrictHostKeyChecking failures** — First-time SSH connections fail on host key verification. `-o StrictHostKeyChecking=no` disables this check for automated scripts.

---

## 🔍 Exec Command Breakdown

```bash
# Install sshpass if not present (silently, don't fail if already installed)
sudo yum install -y sshpass 2>/dev/null || true

# Ensure destination directory exists on ststor01
sshpass -p 'Bl@kW' ssh -o StrictHostKeyChecking=no \
  natasha@ststor01 'sudo mkdir -p /usr/src/security'

# Copy access_log from stapp03 to ststor01
sshpass -p 'Bl@kW' scp -o StrictHostKeyChecking=no \
  /var/log/httpd/access_log \
  natasha@ststor01:/usr/src/security/

# Copy error_log from stapp03 to ststor01
sshpass -p 'Bl@kW' scp -o StrictHostKeyChecking=no \
  /var/log/httpd/error_log \
  natasha@ststor01:/usr/src/security/
```

All commands run **on stapp03** (the SSH target). The `sshpass` on stapp03 enables passwordless SCP to ststor01 inline.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What does `*/6 * * * *` mean in Jenkins cron syntax and how does it differ from `6 * * * *`?**

`*/6 * * * *` uses the step syntax — the `*/` means "every N," so `*/6` in the minute field means "every 6 minutes" (0, 6, 12, 18, 24, 30, 36, 42, 48, 54). `6 * * * *` without the `*/` means "at minute 6 of every hour" — the job runs once per hour at 6 minutes past the hour. The `*/` prefix is essential for interval-based schedules. Similar patterns: `*/15 * * * *` every 15 minutes, `*/30 * * * *` every 30 minutes. For hourly and daily schedules without intervals, `0 * * * *` (top of every hour) and `0 2 * * *` (2:00 AM daily) don't need `*/`.

---

**Q2: Why use Jenkins for log collection when dedicated tools like Filebeat or Fluentd exist?**

For teams already running Jenkins, adding a scheduled collection job is zero additional infrastructure — no new agents to deploy, no new configuration management, no new monitoring. It's practical for: initial triage while evaluating proper log infrastructure, environments where installing agents on servers isn't allowed or practical, and periodic bulk collection (backup-style) rather than real-time streaming. The limitation is that Jenkins collection is polling-based (not real-time), files are copied wholesale rather than streamed, and there's no parsing or indexing. For production observability, Filebeat/Fluentd feeding ELK/Loki/Splunk is the right answer — but Jenkins scheduled jobs cover the immediate need while that's being built.

---

**Q3: What is `sshpass` and why is it used here instead of SSH keys?**

`sshpass` provides a non-interactive way to supply an SSH/SCP password via command line or environment variable — SSH itself doesn't support inline password passing for security reasons. It's a practical workaround for scripted connections where setting up SSH key pairs isn't feasible or authorized. The security tradeoff is real: the password appears in the command string, which can be visible in process listings (`ps aux`) and shell history. In production, SSH key-based authentication (`ssh-keygen`, `ssh-copy-id`) is strongly preferred — no password in the command, no password to rotate, standard Unix authentication. For a lab environment, `sshpass` is acceptable; for production, set up passwordless SSH keys between stapp03 and ststor01 and remove `sshpass` entirely.

---

**Q4: How would you evolve this log collection approach into a real-time log streaming solution?**

The progression: (1) **Jenkins scheduled copy** (today) — polling every 6 minutes, batch copy. (2) **Filebeat agents** on each app server — tail log files in real time, ship to a central Elasticsearch or Logstash endpoint. Zero Jenkins involvement, no polling delay, parsed structured logs. (3) **Full ELK/Loki stack** — Elasticsearch for storage and indexing, Logstash/Fluentd for parsing and enrichment, Kibana/Grafana for visualization and alerting. Real-time search across all server logs, anomaly detection, alerting on error rate spikes. The Jenkins approach handles "we need logs quickly, let's not set up infrastructure today" — Filebeat handles production-grade streaming.

---

**Q5: What are the security implications of putting SSH passwords in Jenkins job exec commands?**

The password appears in: (1) Jenkins console output — anyone with Console Output read permission sees it. (2) The build step configuration in Jenkins — anyone with Job/Configure permission sees it. (3) Process listing on stapp03 during execution — `ps aux` shows the full command including the `-p 'password'` flag briefly. Mitigations: use Jenkins Credentials to store passwords rather than plaintext in exec commands, configure Publish Over SSH to use private keys rather than passwords (configure key-based auth between stapp03 and ststor01), mask credentials in console output using the "Mask Passwords" plugin, and restrict Console Output read access via yesterday's RBAC configuration. For a lab, plaintext is acceptable; production implementations should never expose credentials in job configurations.

---

**Q6: How would you handle log rotation — ensuring the copied logs include all new entries since the last run?**

Simple file copy (`scp access_log`) overwrites the destination file each run — you always have a copy of the current log file, but lose the delta between runs if the log rotates. For incremental collection: (1) **Timestamp the files** — `scp access_log natasha@ststor01:/usr/src/security/access_log.$(date +%Y%m%d%H%M)`. (2) **Track position** — use `rsync` instead of `scp`, or write a script that tracks file offset and only transfers new lines (similar to what Filebeat does internally). (3) **Logrotate integration** — coordinate Jenkins collection with logrotate schedules so you always capture rotated files before they're deleted. (4) **Use the log rotation files** — Apache typically creates `access_log.1`, `access_log.2.gz` on rotation; include these in the collection alongside the active log.

---

## 🔗 References

- [Jenkins Build Triggers — Cron](https://www.jenkins.io/doc/book/pipeline/syntax/#cron-syntax)
- [Publish Over SSH Plugin](https://plugins.jenkins.io/publish-over-ssh/)
- [Apache Log Files](https://httpd.apache.org/docs/2.4/logs.html)
- [sshpass man page](https://linux.die.net/man/1/sshpass)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
