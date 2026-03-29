# Day 22 — Cloning a Git Repository to a Working Directory

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Version Control / Git  
**Difficulty:** Beginner  
**Phase:** Phase 2 — Infrastructure & Networking  
**Status:** ✅ Completed

---

## 📋 Task Summary

Clone the existing bare Git repository at `/opt/beta.git` on the Storage Server into `/usr/src/kodekloudrepos` as user `natasha`. No modifications to the repository, permissions, or existing directories are allowed.

---

## 🧠 Concept — Cloning a Bare Repository

### What `git clone` Does

`git clone` creates a full working copy of a repository — including all commits, branches, and tags. The clone is linked back to the source via a remote called `origin`.

```
Source (bare repo)                Clone (working directory)
/opt/beta.git/                    /usr/src/kodekloudrepos/beta/
  ├── HEAD                          ├── .git/           ← full git database
  ├── objects/     ──clone──►       │   ├── objects/    ← all history copied
  └── refs/                         │   └── refs/
                                    └── <working files> ← checked out
```

### Local vs Remote Clone

`git clone` works the same whether the source is:
- A local path: `git clone /opt/beta.git`
- SSH: `git clone user@host:/path/repo.git`
- HTTPS: `git clone https://github.com/user/repo.git`

The protocol changes but the result is identical — a working directory with `origin` pointing back to the source.

### Why the Destination Path Matters

```bash
git clone /opt/beta.git /usr/src/kodekloudrepos/beta
#                        └──────── explicit destination
```

Without the destination argument, git uses the repo name as the folder:
```bash
git clone /opt/beta.git
# Creates: ./beta/   (in current directory)
```

Specifying the full destination path is always cleaner and more explicit — especially on shared servers where the current directory matters.

> **Real-world context:** Cloning a repository to a specific server path is standard practice in deployment pipelines. CI/CD systems (Jenkins, GitHub Actions) clone repositories to workspace directories before building. Automation tools like Ansible use `git clone` to deploy application code to target servers. Understanding exactly where the clone lands and what remote it points to is fundamental to maintaining reliable deployments.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | Storage Server (`ststor01`) |
| User | `natasha` |
| Source repository | `/opt/beta.git` |
| Destination | `/usr/src/kodekloudrepos/beta` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into Storage Server as natasha

```bash
ssh natasha@ststor01
```

### Step 2: Verify source repository exists

```bash
ls -la /opt/beta.git
```

Confirms the bare repository is present and accessible.

### Step 3: Verify destination directory exists

```bash
ls -la /usr/src/kodekloudrepos
```

The directory should already exist — do not create or modify it.

### Step 4: Clone the repository

```bash
git clone /opt/beta.git /usr/src/kodekloudrepos/beta
```

**Expected output:**
```
Cloning into '/usr/src/kodekloudrepos/beta'...
done.
```

Or if the repo is empty:
```
Cloning into '/usr/src/kodekloudrepos/beta'...
warning: You appear to have cloned an empty repository.
done.
```

Both outputs are valid — empty repository warning just means no commits have been pushed yet.

### Step 5: Verify the clone

```bash
ls -la /usr/src/kodekloudrepos/beta/
```

**Expected:** A working directory with a `.git/` folder.

```bash
cd /usr/src/kodekloudrepos/beta/
git status
```

**Expected:**
```
On branch main
nothing to commit, working tree clean
```

```bash
git remote -v
```

**Expected:**
```
origin  /opt/beta.git (fetch)
origin  /opt/beta.git (push)
```

The `origin` remote pointing to `/opt/beta.git` confirms the clone is correctly linked. ✅

---

## 📌 Commands Reference

```bash
# ─── Verify prerequisites ────────────────────────────────
ls -la /opt/beta.git                           # Source exists
ls -la /usr/src/kodekloudrepos                 # Destination exists

# ─── Clone ───────────────────────────────────────────────
git clone /opt/beta.git /usr/src/kodekloudrepos/beta

# ─── Verify ──────────────────────────────────────────────
ls -la /usr/src/kodekloudrepos/beta/           # Working dir created
cd /usr/src/kodekloudrepos/beta/
git status                                     # Clean working tree
git remote -v                                  # origin = /opt/beta.git
git log --oneline                              # Commit history (if any)
git branch -a                                  # All branches

# ─── Useful git clone flags ──────────────────────────────
git clone --depth 1 /opt/beta.git /dest        # Shallow clone (latest only)
git clone --branch dev /opt/beta.git /dest     # Clone specific branch
git clone --mirror /opt/beta.git /dest         # Full mirror of bare repo
```

---

## ⚠️ Common Mistakes to Avoid

1. **Running as root when the task specifies natasha** — Always confirm `whoami` before running commands on tasks that specify a particular user.
2. **Cloning into the parent directory instead of a subdirectory** — `git clone /opt/beta.git /usr/src/kodekloudrepos` would try to clone into the existing directory itself. The correct path is `/usr/src/kodekloudrepos/beta` — creating the `beta` subdirectory inside it.
3. **Modifying permissions on `/usr/src/kodekloudrepos`** — The task explicitly prohibits this. The directory already exists with its current permissions — leave them as-is.
4. **Using `sudo git clone`** — The task requires natasha to own the clone. Using sudo creates the clone owned by root. If natasha has read access to `/opt/beta.git`, a plain `git clone` (no sudo) is correct.
5. **Worrying about the empty repository warning** — `warning: You appear to have cloned an empty repository` is expected if no commits have been pushed to the source. The clone is still valid and correctly configured.

---

## 🔍 Git Clone vs Git Init — When to Use Each

| Scenario | Command | Result |
|----------|---------|--------|
| Starting fresh, no existing repo | `git init` | Empty local repo, no remote |
| Getting a copy of existing repo | `git clone <source>` | Full copy + `origin` remote configured |
| Setting up a central server repo | `git init --bare` | Bare repo — teams push/pull to this |
| Mirroring a repo exactly | `git clone --mirror` | Bare clone with all refs |

---

## 🔗 References

- [`git clone` documentation](https://git-scm.com/docs/git-clone)
- [Git on the Server — Getting Git on a Server](https://git-scm.com/book/en/v2/Git-on-the-Server-Getting-Git-on-a-Server)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
