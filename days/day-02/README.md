# Day 02 — Creating a Temporary User Account with Expiry Date

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Linux User Management  
**Difficulty:** Beginner  
**Status:** ✅ Completed

---

## 📋 Task Summary

A developer named `anita` requires temporary access to **App Server 2** (`stapp02`) in the Stratos Datacenter for a project-based assignment. The account must expire on `2027-01-28` and the username must follow lowercase naming conventions.

---

## 🧠 Concept — Account Expiry & Lifecycle Management

In any real infrastructure, **not all user accounts are permanent.** Contractors, vendors, temporary project members, and intern accounts should always have a defined lifecycle. Leaving accounts active beyond their purpose is a direct security risk — it's one of the most common findings in a security audit.

Linux handles this cleanly through the `/etc/shadow` file, which stores account aging information separately from `/etc/passwd`.

### Key account aging fields:

| Field | Command | Purpose |
|-------|---------|---------|
| Account expiry date | `useradd -e` / `chage -E` | Date after which login is disabled |
| Password expiry | `chage -M` | Days before password must be changed |
| Inactive period | `useradd -f` | Days after password expires before account locks |

> **Real-world context:** In enterprise environments, this is typically handled by Active Directory or LDAP with automated provisioning/deprovisioning. But on standalone Linux servers — app servers, build servers, jump hosts — manual account expiry is still common and critical to get right.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 2 (`stapp02`) |
| Datacenter | Stratos Datacenter |
| OS | CentOS / RHEL-based |
| Access | SSH |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 2

```bash
ssh steve@stapp02
```

### Step 2: Create user `anita` with expiry date in one command

```bash
sudo useradd -e 2027-01-28 anita
```

**Flag breakdown:**

| Flag | Purpose |
|------|---------|
| `useradd` | Command to create a new user |
| `-e 2027-01-28` | Sets account expiry date (format: YYYY-MM-DD) |
| `anita` | Username in lowercase as required |

### Step 3: Verify the expiry date using `chage`

```bash
sudo chage -l anita
```

**Output:**
```
Login:                             anita
Password expires:                  never
Password inactive:                 never
Account expires:                   Jan 28, 2027
Minimum number of days between password change: 0
Maximum number of days between password change: 99999
Number of days of warning before password expires: 7
```

`Account expires: Jan 28, 2027` confirms the expiry is set correctly. ✅

### Step 4: Verify via `/etc/shadow`

```bash
sudo grep "anita" /etc/shadow
```

**Output:**
```
anita:!:19754:0:99999:7:::20847
```

The **8th colon-separated field** (`20847`) is the expiry date stored as the number of days since the Unix epoch (January 1, 1970). That number maps to `2027-01-28`.

### Step 5: Confirm lowercase username

```bash
getent passwd anita
```

**Output:**
```
anita:x:1002:1002::/home/anita:/bin/bash
```

Lowercase confirmed. ✅

---

## 📌 Commands Reference

```bash
# Create user with expiry date
sudo useradd -e 2027-01-28 anita

# Verify expiry (human-readable)
sudo chage -l anita

# Verify via shadow file
sudo grep "anita" /etc/shadow

# Confirm username entry
getent passwd anita

# --- Alternative methods to set/update expiry ---

# Using usermod (modify existing user)
sudo usermod -e 2027-01-28 anita

# Using chage (dedicated account aging tool)
sudo chage -E 2027-01-28 anita

# --- Useful extras ---

# Remove expiry from an account (set to never expire)
sudo chage -E -1 anita

# Convert epoch days to readable date (Python quick check)
python3 -c "import datetime; print(datetime.date(1970,1,1) + datetime.timedelta(days=20847))"
```

---

## ⚠️ Common Mistakes to Avoid

1. **Wrong date format** — `useradd -e` and `chage -E` expect `YYYY-MM-DD`. Using `DD-MM-YYYY` silently fails or errors out.
2. **Confusing account expiry with password expiry** — These are different fields. `chage -l` shows both clearly — always verify the right one.
3. **Not verifying after creation** — `chage -l` is your best friend here. Always run it to confirm, especially before handing off the task.
4. **Uppercase in username** — Linux usernames are case-sensitive. `Anita` and `anita` are different users. Always verify with `getent passwd`.

---

## 🔍 Understanding `/etc/shadow` Account Expiry Field

```
anita : ! : 19754 : 0 : 99999 : 7 : : 20847 :
  1     2     3    4    5      6  7    8      9
```

| Field | Meaning |
|-------|---------|
| 1 | Username |
| 2 | Encrypted password (`!` = locked/no password set) |
| 3 | Days since epoch when password was last changed |
| 4 | Minimum days before password can be changed |
| 5 | Maximum days password is valid |
| 6 | Warning days before password expiry |
| 7 | Inactive days after expiry before account is disabled |
| **8** | **Account expiry in days since epoch ← this is what we set** |
| 9 | Reserved |

---

## 🔗 References

- [`useradd` man page](https://man7.org/linux/man-pages/man8/useradd.8.html)
- [`chage` man page](https://man7.org/linux/man-pages/man1/chage.1.html)
- [Understanding `/etc/shadow`](https://www.cyberciti.biz/faq/understanding-etcshadow-file/)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: Why should temporary accounts always have an expiry date set at creation time rather than cleaned up manually later?**

> Manual cleanup is unreliable — people forget. An expired contractor account left active for 6 months is a common audit finding. Setting the expiry at creation time automates enforcement: the account disables itself. In compliance-heavy environments (SOC 2, PCI-DSS), having automated account lifecycle controls is a hard requirement.

---

**Q2: What's the difference between `useradd -e` and `chage -E`? When would you use each?**

> Both set the account expiry date. `useradd -e` is used at creation time as a single-command setup. `chage -E` modifies an existing account — use it when extending or changing the expiry of an account that's already live. In automation scripts, `chage` is preferred for updates because it doesn't risk accidental recreation.

---

**Q3: How do you verify an account's expiry date after setting it?**

```bash
sudo chage -l anita
# Shows: Account expires: Jan 28, 2027

# Or check /etc/shadow directly:
sudo grep "anita" /etc/shadow
# 8th field = days since epoch → convert with Python:
python3 -c "import datetime; print(datetime.date(1970,1,1) + datetime.timedelta(days=20847))"
```

> Always verify with `chage -l` — it's human-readable. The raw `/etc/shadow` value is epoch days, which is useful when scripting or auditing programmatically.

---

**Q4: A user's account expired yesterday and they're locked out. How do you quickly extend it by 30 days?**

```bash
# Get today's date + 30 days
NEWEXPIRY=$(date -d "+30 days" +%Y-%m-%d)

# Update the account
sudo chage -E "$NEWEXPIRY" anita

# Verify
sudo chage -l anita
```

> This is a common helpdesk scenario. Automate it if you're extending multiple accounts — a one-liner loop over a list of usernames saves time and avoids typos.

---

**Q5: How does account expiry differ from password expiry, and why does that distinction matter?**

> Account expiry (`chage -E`) disables the entire account on a date — login is completely blocked. Password expiry (`chage -M`) forces a password reset after N days but doesn't disable the account. For contractor/temp accounts, always use account expiry, not just password expiry. Password expiry alone means the contractor can reset their password and continue accessing the system indefinitely.

---

**Q6: In Ansible, how would you enforce account expiry at scale across 50 servers?**

```yaml
- name: Create temporary user with expiry
  hosts: all
  tasks:
    - name: Create user anita with expiry
      ansible.builtin.user:
        name: anita
        expires: 1801238400   # Unix timestamp for 2027-01-28
        state: present
```

> Ansible's `user` module takes `expires` as a Unix timestamp. Convert with `date -d "2027-01-28" +%s`. Idempotent — run it 100 times, same result. This is how you enforce account lifecycle at fleet scale.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
