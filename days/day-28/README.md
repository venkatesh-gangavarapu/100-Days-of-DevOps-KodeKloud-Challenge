# Day 28 — Git Cherry-Pick: Applying a Specific Commit to Master

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Version Control / Git  
**Difficulty:** Intermediate  
**Phase:** Phase 2 — Infrastructure & Networking  
**Status:** ✅ Completed

---

## 📋 Task Summary

The feature branch in `/usr/src/kodekloudrepos/demo` has in-progress work but one specific commit (`Update info.txt`) needs to be applied to `master` without merging the entire feature branch. Use `git cherry-pick` to accomplish this, then push master to origin.

---

## 🧠 Concept — `git cherry-pick`

### What Cherry-Pick Does

`git cherry-pick` takes a single commit from anywhere in the repository history and **replays its changes** as a new commit on the current branch. The source branch is completely untouched.

```
feature: A ──── B (Update info.txt) ──── C ──── D  ← in-progress work
                │
           cherry-pick ↓
master:  A ──────────────────────────────────── B' (Update info.txt)
```

`B'` is a new commit — it has the same changes as `B` but a different commit hash (because its parent and timestamp differ).

### Cherry-Pick vs Merge vs Rebase

| Tool | What it brings | Use case |
|------|---------------|---------|
| `git merge` | All commits from source branch | Completed feature ready for integration |
| `git rebase` | Replays all branch commits onto new base | Clean linear history |
| `git cherry-pick` | **One specific commit only** | Hotfixes, selective backports, partial integration |

### Why Not Merge the Entire Feature Branch?

The feature branch has in-progress work — commits `C` and `D` are incomplete. Merging the entire branch would bring broken, unfinished code into `master`. Cherry-pick takes surgical precision — only `B` (the ready, tested commit) lands on master.

> **Real-world context:** Cherry-pick is the standard hotfix deployment pattern. A critical bug is fixed on a development branch (`feature/fix-login-crash`). You can't merge the whole branch — it has other half-baked features. You cherry-pick the fix commit onto `master` and `release` branches specifically. This is also how security patches get backported across multiple release versions in open source projects.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | Storage Server (`ststor01`) |
| User | natasha |
| Repository | `/usr/src/kodekloudrepos/demo` |
| Source branch | `feature` |
| Target branch | `master` |
| Commit to cherry-pick | `Update info.txt` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into Storage Server

```bash
ssh natasha@ststor01
```

### Step 2: Navigate to the repository

```bash
cd /usr/src/kodekloudrepos/demo
```

### Step 3: Check branches available

```bash
git branch -a
```

**Expected:**
```
* master
  feature
  remotes/origin/master
  remotes/origin/feature
```

### Step 4: Find the target commit hash on feature branch

```bash
git log feature --oneline
```

**Expected output (example):**
```
def9012 some other in-progress commit
abc5678 Update info.txt        ← this one
xyz1234 initial commit
```

Note the hash next to `Update info.txt` — e.g. `abc5678`.

### Step 5: Switch to master branch

```bash
git checkout master
```

### Step 6: Cherry-pick the specific commit

```bash
git cherry-pick abc5678
```

Replace `abc5678` with the actual hash from Step 4.

**Expected output:**
```
[master def1234] Update info.txt
 1 file changed, 1 insertion(+)
```

### Step 7: Verify the commit landed on master

```bash
git log --oneline
```

**Expected:**
```
def1234 (HEAD -> master) Update info.txt
xyz1234 initial commit
```

`Update info.txt` is now on master. ✅

### Step 8: Verify feature branch is unchanged

```bash
git log feature --oneline
```

Feature branch still has all its original commits — untouched. ✅

### Step 9: Push master to origin

```bash
git push origin master
```

**Expected:**
```
To /opt/demo.git
   xyz1234..def1234  master -> master
```

---

## 📌 Commands Reference

```bash
# ─── Navigate ────────────────────────────────────────────
cd /usr/src/kodekloudrepos/demo

# ─── Find the commit hash ────────────────────────────────
git log feature --oneline                    # Find "Update info.txt" hash
git log feature --oneline --all              # All branches
git log --all --oneline --grep="Update info.txt"  # Search by message

# ─── Cherry-pick ─────────────────────────────────────────
git checkout master
git cherry-pick <hash>                       # Apply specific commit

# ─── Verify ──────────────────────────────────────────────
git log --oneline                            # Confirm on master
git log feature --oneline                   # Confirm feature unchanged
git show HEAD                               # See what was cherry-picked

# ─── Push ────────────────────────────────────────────────
git push origin master

# ─── Cherry-pick reference ───────────────────────────────
git cherry-pick <hash>                       # Single commit
git cherry-pick <hash1> <hash2>              # Multiple specific commits
git cherry-pick <hash1>..<hash2>             # Range of commits
git cherry-pick --no-commit <hash>           # Stage without committing
git cherry-pick --abort                      # Abort if conflicts arise
git cherry-pick --continue                   # Continue after resolving conflicts
```

---

## ⚠️ Common Mistakes to Avoid

1. **Merging the entire feature branch** — The task requires cherry-picking ONE commit. `git merge feature` would bring all in-progress commits to master. Use `git cherry-pick` with the specific hash.
2. **Cherry-picking from the wrong branch** — Always verify the hash by running `git log feature --oneline` first. Don't assume the hash.
3. **Being on the wrong branch when cherry-picking** — `git cherry-pick` applies the commit to wherever HEAD currently is. Always `git checkout master` before cherry-picking into master.
4. **Not pushing after cherry-pick** — The cherry-picked commit exists only locally until `git push origin master` sends it to the remote.
5. **Confusing cherry-pick with merge** — Cherry-pick creates a new commit with a different hash. It's not the same commit as the source — it's a replay of the same changes.

---

## 🔍 Cherry-Pick Conflict Resolution

If the cherry-picked changes conflict with existing code on master:

```bash
# Git pauses cherry-pick and shows conflicts
git status
# Shows: "both modified: info.txt" or similar

# Open conflicting files and resolve manually
vi info.txt
# Remove conflict markers (<<<<, ====, >>>>)

# Stage resolved files
git add info.txt

# Complete the cherry-pick
git cherry-pick --continue

# Or abort entirely if needed
git cherry-pick --abort
```

---

## 🔗 References

- [`git cherry-pick` documentation](https://git-scm.com/docs/git-cherry-pick)
- [Atlassian — git cherry-pick](https://www.atlassian.com/git/tutorials/cherry-pick)
- [Git — Rewriting History](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: A critical security fix was applied on the `develop` branch but production runs `main`. You can't merge all of `develop` because it has untested features. What do you do?**

```bash
# Find the exact security fix commit
git log develop --oneline --grep="CVE-2024"
# abc1234 Fix CVE-2024-1234: SQL injection in login form

# Cherry-pick that commit onto main
git checkout main
git cherry-pick abc1234

# Push to trigger production deployment
git push origin main
```

> This is the textbook hotfix cherry-pick scenario. Security patches, critical bug fixes, and urgent config changes frequently need to go to production before the full feature branch is ready. Cherry-pick is the surgical tool for exactly this situation.

---

**Q2: Cherry-pick completed but the commit on `master` has a different hash than on `feature`. Why?**

> A Git commit hash is computed from: file content + author + timestamp + **parent commit hash**. When cherry-pick replays a commit onto `master`, the parent hash is different (it's `master`'s tip, not `feature`'s previous commit). Different parent = different hash.
>
> The CHANGES are identical. The commit hash is different. This is expected and correct. It's also why cherry-picking the same commit to multiple branches creates multiple different hashes — same patch, different ancestry.

---

**Q3: Cherry-pick hit a conflict. How do you resolve it and continue?**

```bash
git cherry-pick abc1234
# CONFLICT (content): Merge conflict in info.txt
# error: could not apply abc1234... Update info.txt

# Step 1: See what's conflicting
git status
# both modified: info.txt

# Step 2: Open and resolve the conflict
vi info.txt
# Remove conflict markers, keep correct content

# Step 3: Stage the resolved file
git add info.txt

# Step 4: Continue the cherry-pick
git cherry-pick --continue
# Commits with the resolved changes

# OR abort entirely if you change your mind
git cherry-pick --abort
```

> Cherry-pick conflicts happen when `master` has already modified the same code the cherry-picked commit touches. The resolution process is identical to merge conflict resolution.

---

**Q4: How do you cherry-pick a range of commits (e.g., a security patch that spans 3 commits)?**

```bash
# Cherry-pick last 3 commits from feature branch
git log feature --oneline
# ghi0003 Fix CVE: update validation logic
# def0002 Fix CVE: sanitize input
# abc0001 Fix CVE: add input check

# Cherry-pick the range (abc0001 exclusive, ghi0003 inclusive)
git cherry-pick abc0001^..ghi0003

# Or specify each commit individually
git cherry-pick abc0001 def0002 ghi0003
```

> The `^..` syntax means "everything after abc0001 up to and including ghi0003". The `^` is necessary because ranges are exclusive of the start — without it you'd miss the first commit.

---

**Q5: How does cherry-pick relate to how open-source projects backport security patches across multiple release versions?**

> This is exactly how Linux kernel maintainers, Python, and other major projects handle security patches:
>
> 1. Fix is developed against the latest development branch
> 2. The fix commit is cherry-picked onto each supported release branch (v3.10, v3.11, v3.12)
> 3. Each branch gets its own version of the patch (different hashes, same changes)
> 4. Each branch produces its own release (3.10.x, 3.11.x, 3.12.x)
>
> The stable branches don't merge from main — they only receive carefully cherry-picked security and bugfix commits. Cherry-pick is the mechanism that makes long-term stable release branches possible.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
