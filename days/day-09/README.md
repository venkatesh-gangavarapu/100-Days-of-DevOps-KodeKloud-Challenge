# Day 09 — Production Incident: MariaDB Service Down — Full Root Cause Analysis

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Linux Service Management / Database Incident Response  
**Difficulty:** Intermediate  
**Status:** ✅ Completed

---

## 📋 Task Summary

A production incident was raised for the `Nautilus` application in Stratos DC — the application could not connect to the database. The MariaDB service was down on database server `stdb01`. The task was to diagnose the root cause and fully restore the service.

> This wasn't a single fix. It required **two layers of diagnosis** using logs at each step — which is exactly how real production incidents unfold.

---

## 🔴 Incident Timeline — What Actually Happened

### First `systemctl start` — fails immediately

```bash
sudo systemctl start mariadb
# Job for mariadb.service failed.
# See: systemctl status mariadb and journalctl -xeu mariadb.service
```

---

### Layer 1 — Read `journalctl` logs

```bash
sudo journalctl -u mariadb -n 50 --no-pager
```

**What the logs revealed:**
```
mariadb-check-socket[24312]: Socket file /var/lib/mysql/mysql.sock exists.
mariadb-check-socket[24312]: No process is using /var/lib/mysql/mysql.sock,
                              which means it is a garbage file
mariadb.service: Main process exited, code=exited, status=1/FAILURE
mariadb.service: Failed with result 'exit-code'.
Failed to start MariaDB 10.5 database server.
```

**Root Cause 1: Stale orphaned socket file.**

MariaDB had previously crashed and left `/var/lib/mysql/mysql.sock` behind. Every startup attempt triggered a pre-flight socket check — the script detected the file, confirmed nothing was using it, flagged it as garbage, and aborted before `mysqld` even started.

**Fix 1:**
```bash
sudo rm -f /var/lib/mysql/mysql.sock
sudo systemctl start mariadb
# Still failing — the error is deeper
```

---

### Layer 2 — Read MariaDB's own error log

`journalctl` only shows systemd wrapper messages. Once the socket check passed, the failure was happening inside `mysqld` itself — which writes to its own log.

```bash
sudo cat /var/log/mariadb/mariadb.log
```

**What the logs revealed:**
```
[Note]  InnoDB: 10.5.29 started; log sequence number 45103; transaction id 20
[Note]  Server socket created on IP: '::'.
[ERROR] mariadbd: Can't create/write to file '/run/mariadb/mariadb.pid'
        (Errcode: 13 "Permission denied")
[ERROR] Can't start server: can't create PID file: Permission denied
```

**Root Cause 2: Wrong ownership on `/run/mariadb/` directory.**

InnoDB initialized cleanly. Data was intact. No corruption anywhere. But MariaDB runs as the `mysql` system user — and `/run/mariadb/` was owned by `root`. The `mysql` user couldn't write the PID file, so `mysqld` exited with code 1 every time.

**Fix 2:**
```bash
sudo ls -la /run/mariadb/
# drwxr-xr-x root root /run/mariadb/  ← wrong owner

sudo chown -R mysql:mysql /run/mariadb/
sudo systemctl start mariadb
sudo systemctl enable mariadb
# Active: active (running) ✅  |  Loaded: enabled ✅
```

---

## 🧠 Concept — Layered Incident Diagnosis

This incident is a textbook example of why a single log source is never enough. Two independent failures were stacked:

```
Problem 1 → Stale socket file       → blocked pre-flight check (journalctl)
Problem 2 → PID dir wrong ownership → blocked mysqld startup  (mariadb.log)
```

Fixing Problem 1 and walking away would have left the service broken. The database engine itself was completely healthy throughout — this was a pure infrastructure failure at both stages.

### The Diagnostic Ladder — Always Follow This Order

```
1. CHECK    →  systemctl status mariadb        What state is the service in?
2. READ     →  journalctl -u mariadb           What does systemd report?
3. DIG      →  /var/log/mariadb/mariadb.log   What does the process report?
4. ISOLATE  →  find the exact file or path causing the failure
5. FIX      →  address the root cause, not the symptom
6. VERIFY   →  active + enabled + accepting connections
```

### Why Two Log Sources Were Needed

`journalctl -u mariadb` captures **systemd-layer events** — pre-flight scripts, unit state transitions, wrapper output. Once the socket check passed and control handed off to `mysqld`, all further errors were written only to MariaDB's **own error log** at `/var/log/mariadb/mariadb.log`. They never surface in journalctl.

This is a pattern that applies across many services — the init system log and the application log are separate, and both are required for full diagnosis.

### Why `/run/mariadb/` Had Wrong Ownership

`/run/` is a **tmpfs** — it is rebuilt fresh on every system boot from `systemd-tmpfiles` rules. Normally systemd creates `/run/mariadb/` with `mysql:mysql` ownership during boot. If the directory was manually created, if the system had an incomplete boot, or if `tmpfiles.d` rules were misconfigured — the directory can come up owned by `root`, and MariaDB's `mysql`-user process can't write to it.

> **Real-world context:** This failure pattern is common after OS patching, kernel upgrades, or server migrations — the service starts fine in testing, then fails silently after the first production reboot because runtime directories weren't created with correct ownership. PID file permission failures mean the engine is healthy but the process can't register itself with the init system. It's an infrastructure problem, not a database problem — and only the process-level error log makes that distinction clear.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | Database Server (`stdb01`) |
| Datacenter | Stratos Datacenter |
| User | peter |
| Service | MariaDB 10.5.29 |
| PID File Path | `/run/mariadb/mariadb.pid` |
| Socket File | `/var/lib/mysql/mysql.sock` |
| Error Log | `/var/log/mariadb/mariadb.log` |

---

## 🔧 Full Resolution — Step by Step

### Step 1: SSH into the database server

```bash
ssh peter@stdb01
```

### Step 2: Check service status — always first

```bash
sudo systemctl status mariadb
# Active: inactive (dead)
# Loaded: disabled
```

### Step 3: Read journalctl — Layer 1 diagnosis

```bash
sudo journalctl -u mariadb -n 50 --no-pager
# Found: stale socket file at /var/lib/mysql/mysql.sock
```

### Step 4: Remove stale socket, attempt restart

```bash
sudo rm -f /var/lib/mysql/mysql.sock
sudo systemctl start mariadb
# Still failing — proceed to Layer 2
```

### Step 5: Read MariaDB error log — Layer 2 diagnosis

```bash
sudo cat /var/log/mariadb/mariadb.log
# Found: Permission denied on /run/mariadb/mariadb.pid (Errcode: 13)
```

### Step 6: Inspect and fix PID directory ownership

```bash
ls -la /run/mariadb/
# drwxr-xr-x root root  ← problem confirmed

sudo chown -R mysql:mysql /run/mariadb/
```

### Step 7: Start and enable the service

```bash
sudo systemctl start mariadb
sudo systemctl enable mariadb
```

### Step 8: Verify fully restored

```bash
sudo systemctl status mariadb
# Active: active (running)  |  Loaded: enabled ✅

mysql -u root -e "SHOW DATABASES;"
# Database list returned — application connectivity restored ✅
```

---

## 📌 Commands Reference

```bash
# ─── Diagnosis ───────────────────────────────────────
sudo systemctl status mariadb                   # Service state
sudo journalctl -u mariadb -n 50 --no-pager     # Systemd-layer logs
sudo cat /var/log/mariadb/mariadb.log           # Process-level error log
sudo ls -la /run/mariadb/                       # PID dir ownership
sudo ls -la /var/lib/mysql/                     # Data dir ownership
df -h                                           # Disk space check

# ─── Fix ─────────────────────────────────────────────
sudo rm -f /var/lib/mysql/mysql.sock            # Remove stale socket
sudo chown -R mysql:mysql /run/mariadb/         # Fix PID dir ownership
sudo systemctl start mariadb
sudo systemctl enable mariadb

# ─── Verify ──────────────────────────────────────────
sudo systemctl is-active mariadb                # Expected: active
sudo systemctl is-enabled mariadb               # Expected: enabled
mysql -u root -e "SHOW DATABASES;"             # Confirm DB connectivity
mysqladmin -u root status                       # Service health summary
```

---

## ⚠️ Key Lessons from This Incident

1. **Always read logs before touching anything** — `systemctl restart` without log analysis would have masked the root cause and solved nothing.
2. **One log source is never enough** — `journalctl` shows the init system layer. The application error log shows the process layer. Both are required for complete diagnosis.
3. **Multiple failures can be stacked** — After fixing Problem 1, always re-run the full diagnostic sequence. Don't assume one fix resolves everything.
4. **InnoDB health does not equal service health** — The database engine was perfectly fine throughout. Data intact. No corruption. The failures were pure infrastructure — socket file and directory ownership.
5. **`enable` is not optional in production** — `systemctl start` brings it up now. `systemctl enable` ensures it survives reboots. Skipping `enable` means the same incident reopens at the next maintenance window.

---

## 🔗 References

- [MariaDB Error Log Documentation](https://mariadb.com/kb/en/error-log/)
- [systemd tmpfiles.d — Runtime Directory Management](https://www.freedesktop.org/software/systemd/man/tmpfiles.d.html)
- [`journalctl` man page](https://man7.org/linux/man-pages/man1/journalctl.1.html)
- [MariaDB — Starting and Stopping](https://mariadb.com/kb/en/starting-and-stopping-mariadb-automatically/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
