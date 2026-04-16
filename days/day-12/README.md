# Day 12 — Production Incident: Apache Unreachable on Port 6300

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Linux Networking / Apache / Firewall / Incident Response  
**Difficulty:** Intermediate  
**Status:** ✅ Completed

---

## 📋 Task Summary

Monitoring flagged that Apache on **App Server 1** (`stapp01`) was unreachable on port `6300`. The task was to diagnose without assumptions, fix without weakening security, and verify from the jump host:

```bash
curl http://stapp01:6300
```

---

## 🔴 Actual Incident Findings

### Initial assumption — firewalld

First instinct was `firewalld` — the standard firewall on RHEL/CentOS:

```bash
sudo firewall-cmd --list-all
# bash: firewall-cmd: command not found
```

`firewalld` wasn't installed. This is an important signal — the environment is using `iptables` directly instead.

### Layer-by-Layer Diagnosis

**Layer 1 — Service status:**
```bash
sudo systemctl status httpd
# Active: active (running) ✅
```
Apache was running. Not the problem.

**Layer 2 — Port binding:**
```bash
sudo ss -tlnp | grep httpd
grep -i "^Listen" /etc/httpd/conf/httpd.conf
# Listen 6300 ✅
```
Apache was correctly configured and bound to port 6300. Not the problem.

**Layer 3 — Firewall (iptables):**
```bash
sudo iptables -L INPUT -n --line-numbers
```
No ACCEPT rule for port 6300 existed. All inbound traffic to 6300 was falling through to the default DROP/REJECT policy.

**Root cause confirmed: `iptables` had no ACCEPT rule for port 6300.**

### The Fix

```bash
sudo iptables -I INPUT -p tcp --dport 6300 -j ACCEPT
```

`-I INPUT` inserts the rule at the top of the INPUT chain — ensuring it's evaluated before any DROP rules below it.

**Verify from jump host:**
```bash
curl http://stapp01:6300
# HTML response ✅
```

---

## 🧠 Concept — iptables vs firewalld

This incident highlighted a critical environmental difference that assumptions can miss.

| Feature | `firewalld` | `iptables` |
|---------|------------|------------|
| Interface | High-level, zone-based | Low-level, rule-based |
| Default on | RHEL 7+, CentOS 7+ | Older RHEL/CentOS, Debian |
| Persistence | Built-in (`--permanent`) | Requires `iptables-save` / `iptables-persistent` |
| Runtime changes | `firewall-cmd --reload` | Immediate on rule insert |
| Check command | `firewall-cmd --list-all` | `iptables -L -n` |

> Always check **which** firewall is active before trying to manage it. `command not found` on `firewall-cmd` is your signal to switch to `iptables`.

### The Four-Layer Diagnosis Model

```
Layer 1 → Is the service running?
           systemctl status httpd                ✅ running

Layer 2 → Is the service bound to the right port?
           ss -tlnp | grep httpd                 ✅ bound to 6300
           grep "^Listen" /etc/httpd/conf/httpd.conf

Layer 3 → Is the firewall allowing inbound traffic?
           firewall-cmd --list-all               ❌ command not found
           iptables -L INPUT -n                  ❌ no ACCEPT rule for 6300
           → FIX: iptables -I INPUT -p tcp --dport 6300 -j ACCEPT

Layer 4 → Is SELinux blocking the port?
           semanage port -l | grep http_port_t   (verify if SELinux enforcing)
```

**All four layers must be clear for a service to be reachable.**

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 1 (`stapp01`) |
| User | tony |
| Service | Apache HTTP Server (`httpd`) |
| Required Port | `6300` |
| Firewall | `iptables` (not firewalld) |
| Config File | `/etc/httpd/conf/httpd.conf` |

---

## 🔧 Full Resolution Commands

```bash
# ─── Diagnosis ───────────────────────────────────────────
sudo systemctl status httpd                    # Service running ✅
sudo ss -tlnp | grep httpd                     # Bound to 6300 ✅
grep -i "^Listen" /etc/httpd/conf/httpd.conf   # Listen 6300 ✅
sudo iptables -L INPUT -n --line-numbers       # No ACCEPT rule for 6300 ❌

# ─── Fix ─────────────────────────────────────────────────
sudo iptables -I INPUT -p tcp --dport 6300 -j ACCEPT

# ─── Make iptables rule persistent across reboots ────────
sudo service iptables save
# or
sudo iptables-save | sudo tee /etc/sysconfig/iptables

# ─── Verify ──────────────────────────────────────────────
sudo iptables -L INPUT -n | grep 6300          # Rule present ✅
curl http://stapp01:6300                       # HTML response ✅
```

---

## ⚠️ Key Lessons from This Incident

1. **Don't assume the firewall technology** — `firewalld` and `iptables` are both common. `command not found` is diagnostic information — it tells you which one is in use.
2. **Work top-down through every layer** — Apache was running and correctly configured the whole time. Only the firewall layer was broken. Skipping straight to "restart Apache" would have solved nothing.
3. **Persist iptables rules** — `iptables -I` takes effect immediately but doesn't survive a reboot. Always follow up with `iptables-save` to make the rule permanent.
4. **Test locally before testing remotely** — `curl http://localhost:6300` from the server itself confirms whether the service is the issue. If that works and remote doesn't — it's always the firewall.
5. **`-I` vs `-A` in iptables** — `-I INPUT` inserts at the top (evaluated first). `-A INPUT` appends at the bottom (may never be reached if a DROP rule is above it). Always use `-I` for ACCEPT rules on specific ports.

---

## 🔍 iptables Key Commands Reference

```bash
# List all INPUT rules with line numbers
sudo iptables -L INPUT -n --line-numbers

# Insert ACCEPT rule at top of INPUT chain
sudo iptables -I INPUT -p tcp --dport 6300 -j ACCEPT

# Append rule at bottom (use with caution)
sudo iptables -A INPUT -p tcp --dport 6300 -j ACCEPT

# Delete a rule by line number
sudo iptables -D INPUT 3

# Save rules permanently (RHEL/CentOS)
sudo service iptables save

# Save rules permanently (Debian/Ubuntu)
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

---

## 🔗 References

- [iptables man page](https://man7.org/linux/man-pages/man8/iptables.8.html)
- [Apache httpd — Listen Directive](https://httpd.apache.org/docs/2.4/bind.html)
- [firewalld vs iptables — Red Hat](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/security_guide/sec-using_firewalls)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: A service is running and bound to the correct port but `curl` from another host still times out. What's your diagnostic sequence?**

```bash
# Layer 1: Is the service running?
sudo systemctl status httpd              # ✅ running

# Layer 2: Is it bound to the right port?
sudo ss -tlnp | grep httpd              # ✅ port 6300

# Layer 3: Can I reach it locally?
curl http://localhost:6300              # ✅ works locally

# Layer 4: Firewall blocking remote access?
sudo iptables -L INPUT -n | grep 6300  # ❌ no ACCEPT rule
# OR for firewalld:
sudo firewall-cmd --list-all

# Fix:
sudo iptables -I INPUT -p tcp --dport 6300 -j ACCEPT
```

> If it works locally but not remotely — it's always the firewall (or SELinux on RHEL). Work down these four layers every time.

---

**Q2: What's the difference between `iptables -I` and `iptables -A` when adding firewall rules?**

> `-I` (insert) places the rule at the **top** of the chain — it's evaluated first. `-A` (append) places it at the **bottom** — evaluated last.
>
> For ACCEPT rules on specific ports, always use `-I`. If you use `-A` and there's a DROP-all rule above it, your ACCEPT rule is never reached — the DROP fires first and the traffic is blocked.

---

**Q3: How do you make iptables rules persist across server reboots?**

```bash
# RHEL/CentOS (with iptables-services installed)
sudo service iptables save
# Saves to: /etc/sysconfig/iptables

# Or manually:
sudo iptables-save | sudo tee /etc/sysconfig/iptables

# Debian/Ubuntu:
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Verify rules survive a reload:
sudo systemctl restart iptables
sudo iptables -L INPUT -n | grep 6300
```

> `iptables` rules are in-memory only by default — a reboot wipes them. Always persist immediately after adding rules. This is a very common oversight in incident response: fix works, then mysteriously breaks the next morning after a maintenance reboot.

---

**Q4: In a production environment, how do you decide between `firewalld` and `iptables`?**

> The environment dictates the choice — don't switch unless necessary:
> - RHEL 7+, CentOS 7+, Fedora → `firewalld` is the default and expected
> - Older RHEL/CentOS 6, some minimal installs → `iptables` directly
> - Kubernetes nodes → often both disabled in favor of network policy (Calico, Cilium)
>
> Check which is present: `which firewall-cmd` vs `which iptables`. Then use what's there. Mixing both on the same server causes unpredictable behavior — pick one.

---

**Q5: What's the SELinux layer check you should always include in a "service unreachable" diagnostic?**

```bash
# Check if SELinux is enforcing
getenforce

# Check if the port is in the allowed list for the service type
sudo semanage port -l | grep http_port_t

# If port 6300 is missing:
sudo semanage port -a -t http_port_t -p tcp 6300

# Check for recent SELinux denials
sudo ausearch -m avc -ts recent | grep httpd
```

> On SELinux-enforcing RHEL/CentOS systems, four layers must all pass: service running → correct port → firewall ACCEPT → SELinux allows the port. Missing any one layer breaks connectivity.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
