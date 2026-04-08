# Day 27 — Git Revert: Safely Undoing the Latest Commit

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Version Control / Git  
**Difficulty:** Intermediate  
**Phase:** Phase 2 — Infrastructure & Networking  
**Status:** ✅ Completed

---

## 📋 Task Summary

The development team pushed a bad commit to `/usr/src/kodekloudrepos/games` on the Storage Server. The task was to revert HEAD to the previous commit (`initial commit`) using a new revert commit with the message `revert games`.

---

## 🧠 Concept — `git revert` vs `git reset`

This is one of the most important distinctions in Git — choosing the wrong tool here can break a shared repository for the entire team.

### The Core Difference

| Command | Mechanism | History | Safe on shared branches? |
|---------|-----------|---------|--------------------------|
| `git reset --hard` | Moves HEAD pointer back — **deletes** commits | Rewritten | ❌ Never — breaks team clones |
| `git revert` | Creates a **new commit** that inverts changes | Preserved | ✅ Always — safe for pushed branches |

### What `git revert HEAD` Does

```
Before revert:
──── A (initial commit) ──── B (bad commit) ← HEAD

After git revert HEAD:
──── A (initial commit) ──── B (bad commit) ──── C (revert games) ← HEAD
                                                   └── inverts all changes from B
```

The bad commit `B` still exists in the history — it's not deleted. Commit `C` contains the exact inverse of `B`'s changes, bringing the working tree back to the state it was in at `A`. This is what makes `revert` safe — the full audit trail is preserved.

### Why `git reset` Would Be Wrong Here

If the bad commit has already been pushed to `origin/master`, resetting locally creates a **diverged history**:

```
origin/master: A ──── B
local/master:  A          (after reset)

git push → rejected (non-fast-forward)
git push --force → OVERWRITES remote history → breaks everyone's clone
```

Force pushing to a shared branch is a cardinal sin in team Git workflows. `git revert` avoids this entirely.

### When to Use Each

| Situation | Tool |
|-----------|------|
| Undo pushed commits on shared branch | `git revert` ✅ |
| Undo local unpushed commits | `git reset` (safe locally) |
| Undo last commit, keep changes staged | `git reset --soft HEAD~1` |
| Undo last commit, discard changes | `git reset --hard HEAD~1` |
| Revert a specific old commit (not HEAD) | `git revert <hash>` |

> **Real-world context:** In production environments, `git revert` is the standard response to "we need to undo what just got merged." It's used in hotfix workflows, rollback procedures, and anywhere an auditable undo is required. The fact that the revert itself is a commit means it shows up in changelogs, release notes, and audit logs — which matters for compliance-sensitive environments.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | Storage Server (`ststor01`) |
| User | natasha |
| Repository | `/usr/src/kodekloudrepos/games` |
| Action | Revert HEAD to previous commit |
| Revert commit message | `revert games` (all lowercase) |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into Storage Server

```bash
ssh natasha@ststor01
```

### Step 2: Navigate to the repository

```bash
cd /usr/src/kodekloudrepos/games
```

### Step 3: Check current commit log

```bash
git log --oneline
```

**Expected output:**
```
abc1234 (HEAD -> master, origin/master) <bad commit message>
def5678 initial commit
```

This confirms:
- HEAD is on the bad commit (`abc1234`)
- Previous commit is `initial commit` (`def5678`)

### Step 4: Stage the revert without auto-committing

```bash
git revert --no-commit HEAD
```

`--no-commit` stages the inverse changes without creating the commit yet — giving us control over the exact commit message.

### Step 5: Commit with the required message

```bash
git commit -m "revert games"
```

> **Note:** The task requires all lowercase: `revert games` — not `Revert games` or `Revert HEAD`. Copy exactly.

### Step 6: Verify the log

```bash
git log --oneline
```

**Expected output:**
```
xyz9999 (HEAD -> master) revert games
abc1234 <bad commit>
def5678 initial commit
```

The revert commit sits on top of the bad commit — history intact. ✅

### Step 7: Verify working tree is back to initial commit state

```bash
git diff HEAD~2 HEAD
# Should show no net difference (revert cancels the bad commit)

git diff def5678 HEAD
# Should show empty diff — same state as initial commit
```

### Step 8: Push to origin

```bash
git push origin master
```

✅ Revert committed and pushed. Shared repository safely updated.

---

## 📌 Commands Reference

```bash
# ─── Inspect before acting ───────────────────────────────
cd /usr/src/kodekloudrepos/games
git log --oneline                        # See commit history
git show HEAD                            # See what the bad commit changed
git diff HEAD~1 HEAD                     # Diff between bad commit and previous

# ─── Revert with custom commit message ───────────────────
git revert --no-commit HEAD              # Stage the inverse without committing
git commit -m "revert games"            # Commit with exact required message

# ─── Alternative: single command (auto-opens editor) ─────
git revert HEAD                          # Opens editor for message
# Change message to: revert games
# Save and close

# ─── Verify ──────────────────────────────────────────────
git log --oneline                        # Revert commit visible at HEAD
git diff def5678 HEAD                    # Compare with initial commit (empty = good)

# ─── Push ────────────────────────────────────────────────
git push origin master

# ─── Reference: Other revert scenarios ───────────────────
git revert abc1234                       # Revert a specific commit by hash
git revert HEAD~2                        # Revert commit 2 before HEAD
git revert HEAD~3..HEAD                  # Revert last 3 commits
git revert --abort                       # Abort revert if conflicts arise
```

---

## ⚠️ Common Mistakes to Avoid

1. **Using `git reset --hard` on a pushed branch** — This rewrites history. A force push to a shared branch breaks every team member's local clone. Always use `git revert` on branches others have pulled.
2. **Wrong commit message case** — The task requires `revert games` (all lowercase). `Revert games` or `REVERT GAMES` will fail task validation. Copy the exact string.
3. **Using `--no-edit` without controlling the message** — `git revert HEAD --no-edit` uses an auto-generated message like `Revert "bad commit message"` — not `revert games`. Use `--no-commit` + `git commit -m` to control the message precisely.
4. **Forgetting to push after reverting** — The revert commit exists only locally until pushed. `git push origin master` sends it to the remote.
5. **Reverting the wrong commit** — Always run `git log --oneline` first to confirm which commit is HEAD and which is the `initial commit`.

---

## 🔍 `git revert` Under the Hood

When you run `git revert HEAD`, Git:

1. Reads the diff of the HEAD commit (what it added/removed)
2. Inverts that diff (additions become removals, removals become additions)
3. Applies the inverted diff to the current working tree
4. Stages the result
5. Creates a new commit with the staged changes

The new commit is a **mirror image** of the reverted commit — it contains exactly the changes needed to return the repository to the state before the reverted commit was applied.

---

## 🔗 References

- [`git revert` documentation](https://git-scm.com/docs/git-revert)
- [Atlassian — Undoing Changes with git revert](https://www.atlassian.com/git/tutorials/undoing-changes/git-revert)
- [Git — Reset, Checkout, and Revert](https://www.atlassian.com/git/tutorials/resetting-checking-out-and-reverting)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
