# Day 08 — Installing Ansible 4.10.0 Globally via pip3 on Jump Host

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Configuration Management / Ansible  
**Difficulty:** Intermediate  
**Status:** ✅ Completed

---

## 📋 Task Summary

The Nautilus DevOps team has selected **Ansible** as their configuration management and automation tool. The jump host will act as the **Ansible control node**. The task was to:

- Install **Ansible version `4.10.0`** on the jump host
- Use **`pip3` only** (not yum or apt)
- Ensure the Ansible binary is **globally accessible** — all users on the system can run Ansible commands

---

## 🧠 Concept — Ansible Architecture & Why pip3

### What is Ansible?

Ansible is an **agentless** configuration management and automation platform. Unlike Chef or Puppet, there is nothing to install on managed nodes — Ansible communicates over SSH using the existing Python interpreter on the remote host.

```
┌─────────────────────────────────────────────────────┐
│                  ANSIBLE ARCHITECTURE                │
│                                                      │
│  ┌──────────────┐   SSH + Python   ┌──────────────┐ │
│  │  Control Node│ ────────────────►│ Managed Node │ │
│  │  (Jump Host) │                  │  (stapp01)   │ │
│  │              │ ────────────────►│  (stapp02)   │ │
│  │  ansible     │                  │  (stapp03)   │ │
│  │  installed   │   No agent       │  No agent    │ │
│  │  here only   │   required       │  required    │ │
│  └──────────────┘                  └──────────────┘ │
└─────────────────────────────────────────────────────┘
```

**Why Ansible wins for getting started:**
- No agent to install on managed nodes
- Uses SSH — already configured from Day 7
- YAML-based playbooks — human-readable
- Idempotent by design — run it 10 times, same result

### Ansible Package Versions — Important Distinction

| Package | What it is | Version in this task |
|---------|-----------|---------------------|
| `ansible` | Community package — bundles collections + core | `4.10.0` |
| `ansible-core` | Core engine only | `2.11.x` (bundled inside 4.10.0) |

When you install `ansible==4.10.0`, you get `ansible-core 2.11.x` underneath. The `ansible --version` command reports the **core** version — this is expected and correct.

### Global vs User Install — The Critical Difference

```bash
# USER install (default, no sudo) — only installs for current user
pip3 install ansible==4.10.0
# Installs to: ~/.local/lib/python3.x/site-packages/
# Binary at:   ~/.local/bin/ansible  ← NOT in other users' PATH

# GLOBAL install (with sudo) — accessible to all users
sudo pip3 install ansible==4.10.0
# Installs to: /usr/local/lib/python3.x/site-packages/
# Binary at:   /usr/local/bin/ansible  ← in everyone's PATH ✅
```

> **Real-world context:** In production, Ansible control nodes are typically dedicated servers or CI/CD systems where multiple users or service accounts need access to run playbooks. Installing globally ensures consistency — one version, available everywhere, no "it works on my user but not in the pipeline" issues.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Host | Jump Host |
| User | thor |
| Install Method | pip3 (system-wide with sudo) |
| Target Version | ansible==4.10.0 |

---

## 🔧 Solution — Step by Step

### Step 1: Verify pip3 is available

```bash
pip3 --version
```

**Expected output:**
```
pip 21.x.x from /usr/lib/python3/dist-packages/pip (python 3.x)
```

### Step 2: Install Ansible 4.10.0 globally

```bash
sudo pip3 install ansible==4.10.0
```

The `sudo` is essential — without it, pip3 installs into the current user's home directory, making it unavailable to other users.

**Output:**
```
Collecting ansible==4.10.0
  Downloading ansible-4.10.0.tar.gz (...)
...
Successfully installed ansible-4.10.0 ansible-core-2.11.x ...
```

### Step 3: Verify binary location is globally accessible

```bash
which ansible
```

**Expected output:**
```
/usr/local/bin/ansible
```

`/usr/local/bin` is in the default `$PATH` for all users — this confirms global accessibility.

### Step 4: Verify the installed version

```bash
ansible --version
```

**Expected output:**
```
ansible [core 2.11.x]
  config file = None
  configured module search path = ['/home/thor/.ansible/plugins/modules', ...]
  ansible python module location = /usr/local/lib/python3.x/site-packages/ansible
  executable location = /usr/local/bin/ansible
  python version = 3.x.x (...)
```

### Step 5: Confirm global access — test as another user

```bash
# Binary exists in globally accessible path
ls -l /usr/local/bin/ansible

# Test another user can run it
su - tony -c "ansible --version"
```

No errors, version prints cleanly — global access confirmed. ✅

---

## 📌 Commands Reference

```bash
# Verify pip3 is available
pip3 --version

# Install Ansible 4.10.0 globally (sudo required for global install)
sudo pip3 install ansible==4.10.0

# Verify binary location
which ansible

# Check installed version
ansible --version

# Confirm it's globally accessible
ls -l /usr/local/bin/ansible

# Test as another user
su - tony -c "ansible --version"

# ─── Useful pip3 commands ───

# List installed packages and versions
pip3 list | grep ansible

# Show detailed package info
pip3 show ansible

# Install specific version (upgrade if needed)
sudo pip3 install --upgrade ansible==4.10.0

# Uninstall if needed
sudo pip3 uninstall ansible

# ─── Quick Ansible sanity checks post-install ───

# Ping localhost via Ansible
ansible localhost -m ping

# Check Ansible configuration
ansible-config dump --only-changed
```

---

## ⚠️ Common Mistakes to Avoid

1. **Installing without `sudo`** — The most common mistake. Without `sudo`, pip3 installs to `~/.local/` and only the current user can access it. Always use `sudo pip3 install` for global availability.
2. **Confusing `ansible` version with `ansible-core` version** — Installing `ansible==4.10.0` gives you `ansible-core 2.11.x`. The `ansible --version` output shows the core version. This is correct — don't be confused by the mismatch.
3. **Using `yum install ansible`** — The task explicitly requires pip3. The yum repo often provides an older version and has different dependency handling. Stick to pip3 when specified.
4. **Not verifying the binary path** — Always run `which ansible` after install. If it returns `~/.local/bin/ansible` instead of `/usr/local/bin/ansible`, the install wasn't global.
5. **PATH issues on some systems** — On some systems `/usr/local/bin` may not be in root's PATH by default. Verify with `echo $PATH` if `which ansible` returns nothing after a global install.

---

## 🔍 Ansible Folder Structure Reference

```
/usr/local/bin/            → ansible, ansible-playbook, ansible-galaxy binaries
/usr/local/lib/python3.x/
  └── site-packages/
      └── ansible/         → Ansible Python modules and core library
/etc/ansible/              → Default config directory (created on first run)
  ├── ansible.cfg          → Main configuration file
  └── hosts                → Default inventory file
~/.ansible/                → Per-user cache, roles, collections
```

---

## 🔗 References

- [Ansible Installation Guide — pip](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-in-a-virtual-environment-with-pip)
- [Ansible 4.x Release Notes](https://github.com/ansible-community/ansible-build-data)
- [ansible vs ansible-core — What's the difference?](https://docs.ansible.com/ansible/devel/reference_appendices/release_and_maintenance.html)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
