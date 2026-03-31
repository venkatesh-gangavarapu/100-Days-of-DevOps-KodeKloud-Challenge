# Day 24 — Creating a Feature Branch from Master in Git

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Version Control / Git / Branch Management  
**Difficulty:** Beginner  
**Phase:** Phase 2 — Infrastructure & Networking  
**Status:** ✅ Completed

---

## 📋 Task Summary

The Nautilus development team wants to isolate new feature work in a dedicated branch. On the Storage Server:

1. Navigate to `/usr/src/kodekloudrepos/beta`
2. Create branch `xfusioncorp_beta` from `master`
3. No code changes — branch creation only

---

## 🧠 Concept — Git Branching Strategy

### What a Branch Is

A branch in Git is simply a **lightweight movable pointer to a commit**. Creating a branch costs almost nothing — it's just a 41-byte file containing a commit hash. This is why Git branching is so cheap compared to older VCS systems like SVN.

```
master branch:
A ──── B ──── C  ← master (HEAD)
               │
               └── xfusioncorp_beta  ← new branch, same commit C
```

Both `master` and `xfusioncorp_beta` point to the same commit right now. As development progresses on the feature branch, they diverge:

```
A ──── B ──── C  ← master
               \
                D ──── E  ← xfusioncorp_beta
```

### Why Feature Branches Matter

| Without branches | With branches |
|-----------------|---------------|
| All changes directly on master | Isolated work on feature branches |
| Breaking changes affect everyone | Broken code stays in the branch |
| Hard to review specific features | PRs show exactly what changed |
| Risky hotfix deployments | Master always stable and deployable |

### `git checkout -b` vs `git branch` + `git checkout`

```bash
# Two commands (old way)
git branch xfusioncorp_beta      # create branch
git checkout xfusioncorp_beta    # switch to it

# One command (preferred)
git checkout -b xfusioncorp_beta # create AND switch in one shot

# Modern Git 2.23+ syntax
git switch -c xfusioncorp_beta   # same as checkout -b
```

> **Real-world context:** Feature branches are the cornerstone of every modern development workflow — GitFlow, GitHub Flow, trunk-based development all use them. The branch naming convention `xfusioncorp_beta` follows a common pattern: `<team/project>_<feature>`. In production environments, branch names often encode more context: `feature/user-auth`, `bugfix/login-crash`, `release/v2.1.0`. DevOps engineers create and manage these branches regularly when setting up repositories, CI/CD pipelines, and deployment environments.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | Storage Server (`ststor01`) |
| User | natasha |
| Repository | `/usr/src/kodekloudrepos/beta` |
| Source branch | `master` |
| New branch | `xfusioncorp_beta` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into Storage Server

```bash
ssh natasha@ststor01
```

### Step 2: Navigate to the repository

```bash
cd /usr/src/kodekloudrepos/beta
```

### Step 3: Check current status and branches

```bash
git status
git branch
```

Confirms current branch and that the working tree is clean before creating a new branch.

### Step 4: Ensure you are on master

```bash
git checkout master
```

The new branch must be created **from master** — always verify you're on the correct source branch first.

### Step 5: Create the new branch from master

```bash
git checkout -b xfusioncorp_beta
```

**Expected output:**
```
Switched to a new branch 'xfusioncorp_beta'
```

### Step 6: Verify the branch exists and is active

```bash
git branch
```

**Expected output:**
```
  master
* xfusioncorp_beta
```

The `*` marks the currently active branch — `xfusioncorp_beta` is checked out. ✅

### Step 7: Confirm no changes were made to the code

```bash
git status
```

**Expected output:**
```
On branch xfusioncorp_beta
nothing to commit, working tree clean
```

No staged files, no modifications — branch created cleanly. ✅

---

## 📌 Commands Reference

```bash
# ─── Navigate to repo ────────────────────────────────────
cd /usr/src/kodekloudrepos/beta

# ─── Check current state ─────────────────────────────────
git status                          # Working tree status
git branch                          # List local branches
git log --oneline -5                # Last 5 commits

# ─── Create branch from master ───────────────────────────
git checkout master                 # Ensure on master first
git checkout -b xfusioncorp_beta    # Create and switch in one command

# ─── Verify ──────────────────────────────────────────────
git branch                          # * marks active branch
git status                          # Confirm clean working tree

# ─── Branch management reference ─────────────────────────
git branch                          # List local branches
git branch -a                       # List all branches (including remote)
git branch -d branch_name           # Delete merged branch
git branch -D branch_name           # Force delete unmerged branch
git branch -m old_name new_name     # Rename branch

# ─── Modern Git syntax (2.23+) ───────────────────────────
git switch master                   # Switch to master
git switch -c xfusioncorp_beta      # Create and switch (same as checkout -b)
```

---

## ⚠️ Common Mistakes to Avoid

1. **Creating the branch from the wrong source** — If you're on a different branch when you run `git checkout -b`, the new branch starts from there, not master. Always `git checkout master` first and verify with `git branch` before creating.
2. **Making accidental code changes** — The task explicitly prohibits this. `git status` before and after confirms the working tree stayed clean.
3. **Confusing local and remote branches** — `git checkout -b` creates a local branch only. It doesn't exist on the remote until you `git push origin xfusioncorp_beta`. For this task, local creation is sufficient.
4. **Using `git branch xfusioncorp_beta` without switching** — `git branch` alone creates the branch but leaves you on master. Use `git checkout -b` or follow up with `git checkout xfusioncorp_beta` to switch.

---

## 🔍 Git Branch Workflow — The Big Picture

```
Repository state after Day 21 (bare repo created)
Repository state after Day 22 (cloned to /usr/src/kodekloudrepos/beta)

Today:
  master ──────────────────────────► (stable, production-ready)
               │
               └── xfusioncorp_beta  (new feature development happens here)

Future (after developers work on the branch):
  master ──── C1 ──── C2 ─────────────────────► merge ──►
                        \                              /
                         C3 ──── C4 ──── C5 ──────────
                         xfusioncorp_beta (feature work)
```

---

## 🔗 References

- [Git Branching — Basic Branching](https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging)
- [`git checkout` documentation](https://git-scm.com/docs/git-checkout)
- [`git switch` documentation (modern)](https://git-scm.com/docs/git-switch)
- [GitFlow Branching Model](https://nvie.com/posts/a-successful-git-branching-model/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
