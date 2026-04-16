# Day 14 — Fleet-Wide Apache Troubleshooting & Port 3002 Configuration

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Linux Service Management / Apache / Fleet Operations  
**Difficulty:** Intermediate  
**Status:** ✅ Completed

---

## 📋 Task Summary

Monitoring flagged Apache as unavailable on one app server in Stratos DC. The task was to:

1. **Identify** which app server had the faulty Apache service
2. **Fix** the service on the faulty host
3. **Ensure Apache runs on port `3002`** across all 3 app servers
4. Confirm all servers are up — no hosted content required, service just needs to be running

---

## 🧠 Concept — Fleet-Wide Service Triage

### Efficient Multi-Server Diagnosis

In a fleet environment, SSH-ing into each server one by one is slow and error-prone. A simple loop from the jump host checks all servers in seconds:

```bash
for host in stapp01 stapp02 stapp03; do
  echo "=== $host ==="
  ssh $host "sudo systemctl status httpd --no-pager | grep -E 'Active|running|failed'"
done
```

This is the foundation of fleet operations — one command, full picture. The same pattern scales to 3 servers or 300.

### The Apache Port Change Checklist

Changing Apache from port 80 to any non-standard port requires clearing **three independent layers** — all of which can independently block the service:

```
Layer 1 → httpd.conf        Change Listen directive
Layer 2 → SELinux            Add port to http_port_t
Layer 3 → Firewall           Allow inbound on new port
```

Miss any one and Apache either fails to start or starts but is unreachable.

### Why `httpd -t` Before Every Restart

Apache config syntax errors cause the service to fail on restart — silently from the outside. Always validate before restarting:

```bash
sudo httpd -t
# Syntax OK  → safe to restart
# Syntax error → fix before proceeding
```

One config typo at 2am can take down all virtual hosts on the server. `httpd -t` is your safety net.

> **Real-world context:** Fleet-wide service management is core SRE/DevOps work. Whether you're running 3 servers or 300, the approach is the same — identify the scope of the issue, triage efficiently across the fleet, fix systematically, verify at each step. Tools like Ansible (which we installed on Day 8) automate exactly this pattern. Today we do it manually to understand what Ansible will later replace.

---

## 🖥️ Environment

| Server | Hostname | User |
|--------|----------|------|
| App Server 1 | `stapp01` | tony |
| App Server 2 | `stapp02` | steve |
| App Server 3 | `stapp03` | banner |

**Target port:** `3002` on all servers

---

## 🔧 Solution — Step by Step

### Phase 1: Fleet Triage — Find the Faulty Server

```bash
# From jump host — check all servers in one shot
for host in stapp01 stapp02 stapp03; do
  echo "=== $host ==="
  ssh $host "sudo systemctl status httpd --no-pager | grep -E 'Active|running|failed'"
done
```

The server showing `failed` or `inactive (dead)` is the faulty host. Note it and proceed to fix all three.

---

### Phase 2: Fix Each Server

> Run the following on **stapp01**, **stapp02**, and **stapp03**.

#### Step 1: SSH into the server

```bash
ssh tony@stapp01     # repeat with steve@stapp02, banner@stapp03
```

#### Step 2: Check current Listen port

```bash
grep -i "^Listen" /etc/httpd/conf/httpd.conf
```

Note whether it's set to `80`, `3002`, or something else.

#### Step 3: Set Listen port to 3002

```bash
sudo sed -i 's/^Listen.*/Listen 3002/' /etc/httpd/conf/httpd.conf
```

**Verify:**
```bash
grep -i "^Listen" /etc/httpd/conf/httpd.conf
# Expected: Listen 3002
```

#### Step 4: Allow port 3002 in SELinux (if enforcing)

```bash
# Check SELinux status
getenforce

# Check if 3002 is already allowed for HTTP
sudo semanage port -l | grep http_port_t
```

**If 3002 is NOT listed:**
```bash
sudo semanage port -a -t http_port_t -p tcp 3002
```

**Verify:**
```bash
sudo semanage port -l | grep http_port_t
# Expected: http_port_t  tcp  3002, 80, 81, 443, ...
```

> If `semanage` is not available: `sudo yum install -y policycoreutils-python-utils`

#### Step 5: Validate Apache config syntax

```bash
sudo httpd -t
# Expected: Syntax OK
```

Never skip this. A bad config will crash the service on restart.

#### Step 6: Start and enable Apache

```bash
sudo systemctl start httpd
sudo systemctl enable httpd
```

#### Step 7: Verify service is running and bound to 3002

```bash
sudo systemctl status httpd
sudo ss -tlnp | grep 3002
```

**Expected:**
```
Active: active (running)
LISTEN  0  511  *:3002  *:*  users:(("httpd",pid=XXXX,...))
```

---

### Phase 3: Final Fleet Verification (from jump host)

```bash
# Check service status across all servers
for host in stapp01 stapp02 stapp03; do
  echo "=== $host ==="
  ssh $host "sudo systemctl is-active httpd && sudo ss -tlnp | grep 3002"
done
```

**Expected output for each host:**
```
=== stapp01 ===
active
LISTEN  0  511  *:3002  *:*  users:(("httpd",...))
```

```bash
# Test HTTP response from jump host
for host in stapp01 stapp02 stapp03; do
  echo -n "$host: "
  curl -s -o /dev/null -w "HTTP %{http_code}\n" http://$host:3002
done
```

**Expected:** `HTTP 200` or `HTTP 403` (403 is fine — no content hosted, but Apache is responding) ✅

---

## 📌 Commands Reference

```bash
# ─── Fleet Triage (from jump host) ──────────────────────
for host in stapp01 stapp02 stapp03; do
  echo "=== $host ==="
  ssh $host "sudo systemctl status httpd --no-pager | grep -E 'Active|running|failed'"
done

# ─── Port Configuration ──────────────────────────────────
grep -i "^Listen" /etc/httpd/conf/httpd.conf
sudo sed -i 's/^Listen.*/Listen 3002/' /etc/httpd/conf/httpd.conf

# ─── SELinux ─────────────────────────────────────────────
getenforce
sudo semanage port -l | grep http_port_t
sudo semanage port -a -t http_port_t -p tcp 3002
# Install if missing:
sudo yum install -y policycoreutils-python-utils

# ─── Config Validation ───────────────────────────────────
sudo httpd -t                        # Syntax check — always before restart

# ─── Service Management ──────────────────────────────────
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl status httpd
sudo systemctl restart httpd

# ─── Verification ────────────────────────────────────────
sudo ss -tlnp | grep 3002
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://stapp01:3002

# ─── Fleet Verification (jump host) ─────────────────────
for host in stapp01 stapp02 stapp03; do
  echo -n "$host port 3002: "
  curl -s -o /dev/null -w "HTTP %{http_code}\n" http://$host:3002
done

# ─── Logs (if service won't start) ───────────────────────
sudo tail -30 /var/log/httpd/error_log
sudo journalctl -u httpd -n 30 --no-pager
```

---

## ⚠️ Common Mistakes to Avoid

1. **Fixing only the faulty server** — The task requires port 3002 on ALL three servers. Even the healthy ones need the port changed from 80 to 3002.
2. **Skipping `httpd -t`** — Config syntax errors take the service down silently on restart. Validate first, every time.
3. **Forgetting SELinux** — On enforcing systems, Apache cannot bind to 3002 unless it's in `http_port_t`. The service starts but immediately exits — and the error only appears in `journalctl` or `catalina.out`.
4. **Not running `systemctl enable`** — Fixes the service now but it won't survive a reboot. Always enable alongside start.
5. **Treating HTTP 403 as a failure** — No content is hosted yet, so Apache returns 403. That's correct behaviour — the service is up and responding. 200 would require a hosted `index.html`.

---

## 🔍 Apache Troubleshooting Decision Tree

```
Apache unreachable on port 3002?
        │
        ├── Is service running?
        │   systemctl status httpd
        │   No  → start + enable
        │   Yes → continue
        │
        ├── Is it bound to 3002?
        │   ss -tlnp | grep httpd
        │   No  → fix Listen in httpd.conf, httpd -t, restart
        │   Yes → continue
        │
        ├── Is SELinux blocking 3002?
        │   semanage port -l | grep http_port_t
        │   3002 missing → semanage port -a -t http_port_t -p tcp 3002
        │
        └── Is firewall blocking 3002?
            iptables -L INPUT -n | grep 3002
            No rule → iptables -I INPUT -p tcp --dport 3002 -j ACCEPT
```

---

## 🔗 References

- [Apache httpd — Binding to Addresses and Ports](https://httpd.apache.org/docs/2.4/bind.html)
- [SELinux — HTTP Port Management](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux/)
- [`systemctl` man page](https://man7.org/linux/man-pages/man1/systemctl.1.html)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: Apache starts but immediately exits with no obvious error in `systemctl status`. Where do you look?**

```bash
# systemctl status shows the exit code but not the reason
sudo systemctl status httpd
# Active: failed (Result: exit-code)

# Dive into journalctl for the launch sequence
sudo journalctl -u httpd -n 30 --no-pager

# Then Apache's own error log
sudo tail -30 /var/log/httpd/error_log

# Validate config — a syntax error causes immediate exit
sudo httpd -t
# Syntax error on line 92: ...
```

> When a service starts and immediately dies, always check: `journalctl` for init-layer errors, then the application's own error log. `httpd -t` is the fastest diagnostic — if it says "Syntax OK" the config isn't the issue.

---

**Q2: Why must you add port 3002 to SELinux's `http_port_t` before Apache can bind to it?**

> Apache runs as `httpd_t` in SELinux. The kernel enforces a policy that says `httpd_t` can only bind to ports listed in `http_port_t`. Port 3002 isn't there by default — only standard web ports (80, 443, 8080, etc.) are.
>
> When Apache tries to bind to 3002, SELinux intercepts the syscall, checks the policy, finds no match, and denies it. Apache exits with an obscure error. The fix:
> ```bash
> sudo semanage port -a -t http_port_t -p tcp 3002
> ```
> This adds 3002 to the allowed list — Apache can now bind successfully.

---

**Q3: How would you check Apache's status across all 3 app servers with a single command from the jump host?**

```bash
for host in stapp01 stapp02 stapp03; do
  echo -n "$host: "
  ssh $host "sudo systemctl is-active httpd" 2>/dev/null || echo "unreachable"
done

# For more detail:
for host in stapp01 stapp02 stapp03; do
  echo "=== $host ==="
  ssh $host "sudo systemctl status httpd --no-pager | grep -E 'Active|Listen'"
done
```

> This loop pattern is the foundation of fleet operations. In production with 100+ servers, you'd replace the loop with Ansible: `ansible appservers -m service -a "name=httpd state=started"`.

---

**Q4: `curl http://stapp01:3002` returns HTTP 403 after you set it up. Is the service broken?**

> No — 403 Forbidden means Apache is running and responding on port 3002. The 403 occurs because there's no `index.html` or any files in the document root to serve. Apache correctly returns 403 when directory listing is disabled and no index file exists.
>
> `HTTP 403` = Apache is up and working ✅  
> `Connection refused` = Apache not running or wrong port ❌  
> `Connection timed out` = Firewall blocking ❌

---

**Q5: What does `httpd -t` actually check and why should you run it before every Apache restart?**

```bash
sudo httpd -t
# Syntax OK  ← safe to restart

# If there's an error:
# AH00526: Syntax error on line 42 of /etc/httpd/conf/httpd.conf:
# Invalid command 'Listenn', perhaps misspelled or defined by a module not included
```

> `httpd -t` parses and validates the entire Apache config — `httpd.conf` and all included files — without starting the server. A single typo in a config file will crash Apache on restart and take down all virtual hosts. Running `httpd -t` first catches the error before it causes an outage. Make it a habit: **never restart Apache without running `httpd -t` first**.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
