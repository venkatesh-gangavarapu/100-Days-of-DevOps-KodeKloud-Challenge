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

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: What's the difference between `git init` and `git init --bare`? When do you use each?**

| Command | Use case | Working tree |
|---------|---------|-------------|
| `git init` | Local development repo | Yes — files checked out |
| `git init --bare` | Central/server repo | No — only Git database |

> You can't push to a non-bare repo that has the branch checked out — Git refuses to update a branch that's currently checked out to avoid overwriting uncommitted work. Bare repos have no checked-out branch, so they accept pushes freely. Always use `--bare` for repos that teams push to.

---

**Q2: Someone tries to `git commit` directly inside a bare repository and gets an error. Why?**

```bash
cd /opt/official.git
git commit -m "test"
# fatal: this operation must be run in a work tree

# Why: a bare repo has no working tree — there are no files to stage or commit
# Bare repos only accept: git push (from external clones)
```

> A bare repo is a storage target, not a workspace. You work in clones, then push to the bare repo. Committing directly inside a bare repo is architecturally wrong — it's like writing directly to the "server's" `.git/` folder.

---

**Q3: How do you set up access control on a bare Git repository for a team?**

```bash
# Method 1: Unix group permissions
sudo groupadd gitteam
sudo usermod -aG gitteam alice
sudo usermod -aG gitteam bob
sudo chown -R :gitteam /opt/official.git
sudo chmod -R g+rwX /opt/official.git
sudo git config --file /opt/official.git/config core.sharedRepository group

# Method 2: Use Gitea/GitLab CE (recommended for teams)
# Self-hosted Git platform handles auth, permissions, and UI
```

> For small teams on a single server, Unix group permissions with `core.sharedRepository` work well. For anything larger, use a Git platform (Gitea, GitLab CE) — they provide per-user auth, SSH key management, branch protection, and audit logs.

---

**Q4: What are server-side hooks in a bare repository and why are they useful in production?**

```bash
# Hooks live in /opt/official.git/hooks/
ls /opt/official.git/hooks/
# pre-receive   → runs before refs are updated (push validation)
# post-receive  → runs after push completes (deployment trigger)
# update        → runs per-branch during push

# Example: auto-deploy on push to master
cat /opt/official.git/hooks/post-receive
#!/bin/bash
while read oldrev newrev refname; do
  if [ "$refname" = "refs/heads/master" ]; then
    git --work-tree=/var/www/html --git-dir=/opt/official.git checkout -f master
  fi
done
```

> `post-receive` hooks are how many small teams implement simple "git push to deploy" workflows. Every push to master automatically deploys to the web server. This is the simplest form of continuous deployment.

---

**Q5: How does a bare repository on a storage server compare to GitHub/GitLab as a central repo?**

> Functionally identical — GitHub and GitLab store your repositories as bare repos on their servers. When you `git clone https://github.com/user/repo.git`, you're cloning a bare repository. The `.git` URL suffix is the convention for bare repos.
>
> The difference: GitHub/GitLab add authentication, web UI, pull requests, CI/CD integration, and access controls on top of the bare repo storage. A bare repo on `ststor01` is the raw mechanism without any of those features.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
