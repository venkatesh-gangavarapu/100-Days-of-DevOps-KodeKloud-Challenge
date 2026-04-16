# Day 13 — Installing iptables & Securing Port 6000 with LBR-Only Whitelist

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Linux Security / Network Firewall / iptables  
**Difficulty:** Intermediate  
**Status:** ✅ Completed

---

## 📋 Task Summary

The security team raised a concern — Apache's port `6000` was open to all hosts with no firewall protection. The resolution:

1. Install `iptables` and all dependencies on **all 3 App Servers**
2. Block inbound port `6000` for **everyone except the LBR host** (`stlb01`)
3. Ensure rules **persist across reboots**

---

## 🧠 Concept — iptables Rule Ordering & Whitelisting

### How iptables Processes Rules

iptables evaluates rules **top to bottom** in each chain. The **first matching rule wins** — processing stops there and the packet is handled according to that rule's target (ACCEPT, DROP, REJECT).

```
Packet arrives on port 6000
        │
        ▼
Rule 1: Source = 172.16.238.14 (LBR)?  ──YES──► ACCEPT ✅
        │
        NO
        │
        ▼
Rule 2: Any source, port 6000?          ──YES──► DROP ❌
```

**This order is non-negotiable.** If DROP comes before ACCEPT, the LBR gets blocked too — because every packet matches the DROP rule first.

### ACCEPT vs DROP vs REJECT

| Target | Behaviour | Use Case |
|--------|-----------|---------|
| `ACCEPT` | Allow the packet through | Whitelisted sources |
| `DROP` | Silently discard — no response | Block without revealing service exists |
| `REJECT` | Discard and send error back | Block with explicit feedback |

> `DROP` is preferred for security hardening — it gives attackers no confirmation that a service even exists on the port. `REJECT` is more informative but reveals the port is managed.

### Why `-I` for ACCEPT and `-A` for DROP

```bash
iptables -I INPUT ...   # -I = Insert at top (position 1)
iptables -A INPUT ...   # -A = Append at bottom
```

The ACCEPT rule for LBR must be at the **top** using `-I`. The DROP for everyone else is appended with `-A` — it goes below and only catches traffic that didn't match the ACCEPT rule above it.

### Making Rules Persistent

iptables rules are **in-memory only by default**. They disappear on reboot. Two methods for persistence on RHEL/CentOS:

```bash
# Method 1: iptables-services (recommended on CentOS/RHEL)
sudo service iptables save
# Saves to: /etc/sysconfig/iptables
# Loaded automatically at boot by iptables.service

# Method 2: Manual save
sudo iptables-save | sudo tee /etc/sysconfig/iptables
```

> **Real-world context:** Host-based firewall rules like these are a fundamental defense layer in any production architecture. Even behind a network-level firewall or security group (AWS), host-level iptables rules enforce the principle of defense in depth — each server protects itself independently. The LBR-only whitelist pattern means that even if the network perimeter is compromised, direct lateral access to the application port is still blocked.

---

## 🖥️ Environment

| Role | Host | IP | User |
|------|------|----|------|
| Load Balancer | `stlb01` | `172.16.238.14` | loki |
| App Server 1 | `stapp01` | `172.16.238.10` | tony |
| App Server 2 | `stapp02` | `172.16.238.11` | steve |
| App Server 3 | `stapp03` | `172.16.238.12` | banner |

---

## 🔧 Solution — Step by Step

> Same steps on all 3 app servers. Shown once for `stapp01`.

### Step 1: SSH into the server

```bash
ssh tony@stapp01
```

### Step 2: Install iptables and iptables-services

```bash
sudo yum install -y iptables iptables-services
```

`iptables-services` provides the `iptables.service` systemd unit which handles saving and restoring rules at boot.

### Step 3: Start and enable iptables service

```bash
sudo systemctl start iptables
sudo systemctl enable iptables
```

### Step 4: Check existing rules (baseline)

```bash
sudo iptables -L INPUT -n --line-numbers
```

Note any pre-existing rules before adding new ones.

### Step 5: Add ACCEPT rule for LBR (must be first)

```bash
sudo iptables -I INPUT -p tcp --dport 6000 -s 172.16.238.14 -j ACCEPT
```

**Flag breakdown:**

| Flag | Meaning |
|------|---------|
| `-I INPUT` | Insert at top of INPUT chain |
| `-p tcp` | TCP protocol |
| `--dport 6000` | Destination port 6000 |
| `-s 172.16.238.14` | Source IP = LBR host only |
| `-j ACCEPT` | Allow this traffic |

### Step 6: Add DROP rule for all other sources

```bash
sudo iptables -A INPUT -p tcp --dport 6000 -j DROP
```

**Flag breakdown:**

| Flag | Meaning |
|------|---------|
| `-A INPUT` | Append to bottom of INPUT chain |
| `-p tcp` | TCP protocol |
| `--dport 6000` | Destination port 6000 |
| `-j DROP` | Silently discard — no response sent |

### Step 7: Verify rules are in correct order

```bash
sudo iptables -L INPUT -n --line-numbers
```

**Expected output:**
```
Chain INPUT (policy ACCEPT)
num  target  prot  opt  source           destination
1    ACCEPT  tcp   --   172.16.238.14    0.0.0.0/0    tcp dpt:6000
2    DROP    tcp   --   0.0.0.0/0        0.0.0.0/0    tcp dpt:6000
```

ACCEPT for LBR at line 1. DROP for all at line 2. ✅

### Step 8: Persist rules across reboots

```bash
sudo iptables-save | sudo tee /etc/sysconfig/iptables
```

**Expected output:**
```
iptables: Saving firewall rules to /etc/sysconfig/iptables: [  OK  ]
```

### Step 9: Verify persistence file contains our rules

```bash
sudo grep 6000 /etc/sysconfig/iptables
```

**Expected output:**
```
-A INPUT -s 172.16.238.14/32 -p tcp -m tcp --dport 6000 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 6000 -j DROP
```

### Step 10: Test the rules

```bash
# From LBR host (stlb01) — should succeed
curl http://stapp01:6000

# From jump host — should timeout/be blocked
curl --connect-timeout 5 http://stapp01:6000
# Expected: connection timed out (DROP silently discards)
```

✅ **Repeat Steps 1–10 on `stapp02` and `stapp03`.**

---

## 📌 Commands Reference

```bash
# ─── Installation ────────────────────────────────────────
sudo yum install -y iptables iptables-services
sudo systemctl start iptables
sudo systemctl enable iptables

# ─── Check baseline rules ────────────────────────────────
sudo iptables -L INPUT -n --line-numbers

# ─── Add whitelist rules (ORDER MATTERS) ─────────────────
# Rule 1: ACCEPT from LBR — insert at TOP
sudo iptables -I INPUT -p tcp --dport 6000 -s 172.16.238.14 -j ACCEPT
# Rule 2: DROP all others — append at BOTTOM
sudo iptables -A INPUT -p tcp --dport 6000 -j DROP

# ─── Verify rule order ───────────────────────────────────
sudo iptables -L INPUT -n --line-numbers
sudo iptables -L INPUT -n -v --line-numbers   # with packet counts

# ─── Persist across reboots ──────────────────────────────
sudo iptables-save | sudo tee /ect/sysconfig/iptables
sudo cat /etc/sysconfig/iptables           # verify saved rules

# ─── Test reboot persistence ─────────────────────────────
sudo systemctl restart iptables
sudo iptables -L INPUT -n --line-numbers   # rules should still be there

# ─── Useful iptables management ──────────────────────────
sudo iptables -D INPUT 2                   # Delete rule by line number
sudo iptables -F INPUT                     # Flush all INPUT rules (careful!)
sudo iptables -Z INPUT                     # Zero packet/byte counters
sudo iptables -L INPUT -n -v               # Show with traffic counters
```

---

## ⚠️ Common Mistakes to Avoid

1. **Putting DROP before ACCEPT** — The most critical mistake. iptables is first-match-wins. If DROP is at line 1, it matches the LBR packet too. Always INSERT the ACCEPT rule before APPENDing the DROP.
2. **Not installing `iptables-services`** — `iptables` alone gives you the binary. `iptables-services` provides the systemd service that restores saved rules at boot. Without it, `service iptables save` won't work.
3. **Forgetting `service iptables save`** — Rules added with `-I` or `-A` are in-memory only. One reboot and they're gone. Always persist immediately after adding rules.
4. **Wrong LBR IP** — Verify the LBR IP before writing rules. A typo here means the LBR is blocked and the application becomes unreachable from the load balancer.
5. **Testing from the wrong host** — Test accessibility from the LBR (should work) AND from another host (should be blocked). Testing from only one direction doesn't confirm both sides of the rule.
6. **Using REJECT instead of DROP for the block rule** — `REJECT` sends an error back, confirming to scanners that the port exists. `DROP` is silent — harder to enumerate from an attacker's perspective.

---

## 🔍 iptables Chain Flow

```
Inbound packet (port 6000)
        │
        ▼
┌───────────────────────────────────────────────┐
│  INPUT Chain                                  │
│                                               │
│  Rule 1: -s 172.16.238.14 --dport 6000 ACCEPT │◄── LBR matches here ✅
│  Rule 2: --dport 6000 DROP                    │◄── Everyone else stops here ❌
│  ...other rules...                            │
│  (default policy: ACCEPT)                    │
└───────────────────────────────────────────────┘
```

---

## 🔗 References

- [iptables man page](https://man7.org/linux/man-pages/man8/iptables.8.html)
- [Red Hat — Using iptables](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/security_guide/sec-using_iptables)
- [iptables-services on CentOS/RHEL](https://access.redhat.com/solutions/2265061)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: You added a ACCEPT rule for the LBR and a DROP rule for everyone else, but the LBR is also getting blocked. What's wrong?**

```bash
# Check rule order
sudo iptables -L INPUT -n --line-numbers

# If DROP is at line 1 and ACCEPT is at line 2 — that's the problem
# iptables is first-match-wins: DROP fires for ALL traffic including LBR

# Fix: delete wrong order and re-add correctly
sudo iptables -D INPUT 1                   # delete the misplaced DROP
sudo iptables -D INPUT 1                   # delete the now-first ACCEPT
# Re-add in correct order:
sudo iptables -I INPUT -p tcp --dport 6000 -s 172.16.238.14 -j ACCEPT  # LBR first
sudo iptables -A INPUT -p tcp --dport 6000 -j DROP                       # everyone else
```

> This is the single most common iptables whitelist mistake. ORDER IS EVERYTHING. ACCEPT for the allowed source must be above DROP for all others.

---

**Q2: Why use `DROP` instead of `REJECT` when blocking unauthorized traffic?**

> `REJECT` sends back an ICMP error or TCP RST — the client gets an explicit "connection refused" response. This tells attackers the port exists and is managed.
>
> `DROP` silently discards — the client gets no response and times out. From an attacker's perspective, they can't distinguish a `DROP` from a firewall from a host that doesn't exist. Reduces information leakage. In security hardening, silence is better than an explicit rejection.

---

**Q3: How do you verify that your whitelist rule is actually working — that LBR gets in and others get blocked?**

```bash
# Test from LBR (stlb01) — should succeed:
ssh loki@stlb01
curl http://stapp01:6000

# Test from jump host — should timeout (DROP = no response):
curl --connect-timeout 5 http://stapp01:6000
# Expected: curl: (28) Connection timed out

# Check packet counters to confirm traffic is hitting the rules:
sudo iptables -L INPUT -n -v --line-numbers
# The 'pkts' and 'bytes' columns show traffic hitting each rule
```

> Always test both directions: the allowed source should work AND another host should be blocked. Testing only one side doesn't prove the rule is correct.

---

**Q4: After a server reboot, the iptables whitelist rules are gone. What went wrong?**

```bash
# Rules were added but not persisted
sudo iptables -L INPUT -n   # rules gone after reboot

# Fix: install iptables-services and save
sudo yum install -y iptables-services
sudo systemctl enable iptables
sudo iptables-save | sudo tee /etc/sysconfig/iptables

# Verify the saved file has your rules:
sudo grep 6000 /etc/sysconfig/iptables
```

> `iptables` rules live in memory by default. `iptables-services` provides the systemd service that loads saved rules at boot from `/etc/sysconfig/iptables`. Without it, every reboot wipes your firewall rules.

---

**Q5: In AWS, how does this iptables host-level whitelist map to cloud concepts?**

> AWS Security Groups are the cloud equivalent of iptables rules — they control inbound/outbound traffic at the instance level. The whitelist pattern maps directly:
>
> | iptables | AWS Security Group |
> |----------|-------------------|
> | `ACCEPT -s 172.16.238.14 --dport 6000` | Inbound rule: Port 6000, Source: LBR security group |
> | `DROP --dport 6000` | No other inbound rule for port 6000 = implicit deny |
>
> In AWS, you'd create a security group for the app servers that only allows port 6000 from the LBR security group. Same concept, different interface.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
