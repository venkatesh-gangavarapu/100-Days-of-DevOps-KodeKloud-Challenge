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

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: You created a branch but accidentally based it on the wrong commit. How do you fix it without losing your work?**

```bash
# Current state: wrong base
git log --oneline --graph --all

# Option 1: Rebase the branch onto the correct base
git checkout xfusioncorp_beta
git rebase --onto master wrong_base xfusioncorp_beta

# Option 2: Create a new branch from the right place and cherry-pick
git checkout master
git checkout -b xfusioncorp_beta_fixed
git cherry-pick <commit-hashes-from-wrong-branch>

# Verify the new branch has the right base
git log --oneline --graph
```

> `git rebase --onto` is the surgical tool for changing a branch's base. It "lifts" the branch commits and replays them onto a different starting point.

---

**Q2: What's the difference between `git checkout -b` and `git switch -c`?**

```bash
# Old syntax (works everywhere)
git checkout -b xfusioncorp_beta

# Modern syntax (Git 2.23+, clearer intent)
git switch -c xfusioncorp_beta

# Also: switching branches
git checkout master     # old
git switch master       # new
```

> `git switch` was introduced in Git 2.23 to separate "switch branches" from "restore files" (both used to be `git checkout`). Both work identically. `checkout -b` is still universal and fine to use — many engineers use it out of habit.

---

**Q3: How do you enforce branch naming conventions in a team using Git hooks?**

```bash
# Server-side pre-receive hook: /opt/official.git/hooks/pre-receive
#!/bin/bash
while read oldrev newrev refname; do
  branch=$(echo "$refname" | sed 's|refs/heads/||')
  if ! echo "$branch" | grep -qE '^(feature|bugfix|release|hotfix)/.+'; then
    echo "ERROR: Branch '$branch' doesn't follow naming convention."
    echo "Use: feature/*, bugfix/*, release/*, or hotfix/*"
    exit 1
  fi
done
```

> Pre-receive hooks run on the server before accepting a push. If the hook exits non-zero, the push is rejected. This enforces naming conventions without relying on individual discipline.

---

**Q4: In CI/CD, a pipeline triggers on every branch push. How do you ensure CI only runs on branches matching a pattern?**

```yaml
# GitHub Actions
on:
  push:
    branches:
      - 'feature/**'
      - 'bugfix/**'
      - master

# GitLab CI
workflow:
  rules:
    - if: '$CI_COMMIT_BRANCH =~ /^(feature|bugfix)\//'
```

> Branch pattern matching in CI configs is essential for large repos — you don't want a CI run for every experimental branch. Naming conventions (feature/, bugfix/, release/) make CI filtering clean and predictable.

---

**Q5: What's the GitFlow branching model and how does `xfusioncorp_beta` fit into it?**

```
GitFlow model:
main          ← production-ready code only
develop       ← integration branch for features
feature/*     ← individual feature development
release/*     ← release preparation
hotfix/*      ← emergency production fixes

xfusioncorp_beta = feature branch in GitFlow terminology
  → branches from: develop
  → merges back to: develop (then develop → main via release)
```

> GitFlow is the classic branching strategy for teams with scheduled releases. For teams doing continuous delivery, GitHub Flow (just `main` + short-lived feature branches) is simpler. Knowing both helps you understand any team's Git workflow.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
