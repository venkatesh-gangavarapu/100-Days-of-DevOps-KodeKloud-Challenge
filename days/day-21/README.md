# Day 21 — Setting Up a Bare Git Repository on Storage Server

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Version Control / Git / Source Code Management  
**Difficulty:** Beginner  
**Phase:** Phase 2 — Infrastructure & Networking  
**Status:** ✅ Completed

---

## 📋 Task Summary

The Nautilus development team needs a centralized Git repository for a new project. Setup on Storage Server (`ststor01`):

1. Install `git` via `yum`
2. Create a bare repository at `/opt/official.git`

---

## 🧠 Concept — Bare vs Regular Git Repository

### What is a Bare Repository?

A **bare repository** contains only the Git internals — no working tree (no checked-out files). It is the standard format for **central/remote repositories** that teams push to and pull from.

```
Regular repository (git init)        Bare repository (git init --bare)
─────────────────────────────        ─────────────────────────────────
myproject/                           official.git/
  ├── .git/          ← git data        ├── HEAD
  │   ├── HEAD                         ├── branches/
  │   ├── objects/                     ├── config          ← bare = true
  │   └── refs/                        ├── description
  ├── index.html     ← working files   ├── hooks/
  ├── app.js                           ├── info/
  └── README.md                        ├── objects/
                                       └── refs/
```

In a bare repository:
- The Git database lives directly at the root (not inside `.git/`)
- There are no working files — just version control data
- **You cannot `git commit` directly inside it**
- **You can `git push` to it and `git clone` from it**

### Why `.git` Suffix by Convention?

Bare repositories are named with a `.git` suffix by convention — `official.git`, `myapp.git`. This signals to users and tooling that it's a bare server-side repository, not a working directory. GitHub and GitLab follow the same convention (`github.com/user/repo.git`).

### How Teams Use a Bare Repository

```
Developer A                    Storage Server                Developer B
     │                         /opt/official.git                  │
     │── git clone ──────────────────────────────────────────────►│
     │                                                             │
     │── git push origin main ──────────────────────────────►     │
     │                         (receives + stores commits)        │
     │                                                        ◄────│── git pull
```

> **Real-world context:** This is exactly what happens when you create a repository on GitHub, GitLab, or Bitbucket — a bare repository is created on their servers. Self-hosted Git servers (Gitea, Gogs, GitLab CE) store all repositories as bare repos on disk. Understanding bare repositories is foundational to understanding how any Git hosting platform works at the infrastructure level.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | Storage Server (`ststor01`) |
| User | natasha |
| Repository path | `/opt/official.git` |
| Repository type | Bare |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into Storage Server

```bash
ssh natasha@ststor01
```

### Step 2: Install git

```bash
sudo yum install -y git
```

### Step 3: Verify git is installed

```bash
git --version
# Expected: git version 2.x.x
```

### Step 4: Create the bare repository

```bash
sudo git init --bare /opt/official.git
```

**Expected output:**
```
Initialized empty Git repository in /opt/official.git/
```

### Step 5: Verify the repository structure

```bash
ls -la /opt/official.git/
```

**Expected output:**
```
total 40
drwxr-xr-x  7 root root 4096 ... .
drwxr-xr-x 12 root root 4096 ... ..
-rw-r--r--  1 root root   23 ... HEAD
drwxr-xr-x  2 root root 4096 ... branches
-rw-r--r--  1 root root   66 ... config
-rw-r--r--  1 root root   73 ... description
drwxr-xr-x  2 root root 4096 ... hooks
drwxr-xr-x  2 root root 4096 ... info
drwxr-xr-x  4 root root 4096 ... objects
drwxr-xr-x  4 root root 4096 ... refs
```

### Step 6: Confirm bare = true in config

```bash
cat /opt/official.git/config
```

**Expected output:**
```
[core]
        repositoryformatversion = 0
        filemode = true
        bare = true
```

`bare = true` confirms this is a proper bare repository. ✅

### Step 7: Test — clone from another machine

```bash
# From jump host (optional verification)
git clone natasha@ststor01:/opt/official.git /tmp/test-clone
# Expected: Cloning into '/tmp/test-clone'... warning: You appear to have cloned an empty repository.
```

An empty clone warning is expected — the repo has no commits yet. The clone succeeding confirms the bare repository is accessible. ✅

---

## 📌 Commands Reference

```bash
# ─── Installation ────────────────────────────────────────
sudo yum install -y git
git --version

# ─── Create bare repository ──────────────────────────────
sudo git init --bare /opt/official.git

# ─── Verify ──────────────────────────────────────────────
ls -la /opt/official.git/
cat /opt/official.git/config         # bare = true confirms it

# ─── Test clone from jump host ───────────────────────────
git clone natasha@ststor01:/opt/official.git /tmp/test-clone

# ─── Useful Git server commands ──────────────────────────
# Check all repos on storage server
ls /opt/*.git

# View bare repo log (once commits exist)
git --git-dir=/opt/official.git log --oneline

# List branches in bare repo
git --git-dir=/opt/official.git branch -a

# ─── Convert regular repo to bare (reference) ────────────
# git clone --bare /path/to/repo /path/to/repo.git
```

---

## ⚠️ Common Mistakes to Avoid

1. **`git init` without `--bare`** — Creates a regular repository with a working tree. You cannot push to a non-bare repository that has a checked-out branch. Always use `--bare` for server-side repos.
2. **Wrong path** — The task requires exactly `/opt/official.git`. Any variation (missing `/opt/`, different name) will fail validation.
3. **Not using `sudo`** — `/opt/` is typically root-owned. Without `sudo`, `git init --bare` fails with permission denied.
4. **Expecting files inside the bare repo** — A freshly created bare repo is empty. No `index.html`, no commits, no branches visible. That's correct — it's waiting for the first push.
5. **Confusing `HEAD` file with a directory** — The `HEAD` file in a bare repo is a text file pointing to the default branch (`ref: refs/heads/main`). It's not a checked-out commit.

---

## 🔍 Bare Repository File Structure Explained

```
/opt/official.git/
├── HEAD          → Points to default branch (ref: refs/heads/main)
├── branches/     → Legacy — not used in modern Git
├── config        → Repository config (bare = true lives here)
├── description   → Used by GitWeb — ignored by most tools
├── hooks/        → Server-side hook scripts (pre-receive, post-receive, etc.)
├── info/
│   └── exclude   → Global gitignore for this repo
├── objects/      → All commits, trees, blobs stored here (content-addressed)
│   ├── info/
│   └── pack/
└── refs/         → Branch and tag pointers
    ├── heads/    → Local branches
    └── tags/     → Tags
```

---

## 🔗 References

- [Git on the Server — Bare Repositories](https://git-scm.com/book/en/v2/Git-on-the-Server-Getting-Git-on-a-Server)
- [`git init` documentation](https://git-scm.com/docs/git-init)
- [Git Internals — Git Objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
