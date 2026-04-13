# Day 31 — Git Stash: Restoring Specific Stashed Changes

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Version Control / Git  
**Difficulty:** Intermediate  
**Phase:** Phase 3 — Kubernetes & Orchestration  
**Status:** ✅ Completed

---

## 📋 Task Summary

A developer stashed in-progress changes in `/usr/src/kodekloudrepos/official` on Storage Server. Restore specifically `stash@{1}`, commit the changes, and push to origin.

---

## 🧠 Concept — Git Stash

### What is `git stash`?

`git stash` temporarily shelves uncommitted changes — both staged and unstaged — giving you a clean working tree without losing your work. It's the "save for later" button in Git.

```
Working tree (dirty: half-done feature)
        │
        git stash
        │
        ▼
Clean working tree (safe to switch branches, pull, etc.)
        │
        git stash apply / pop
        │
        ▼
Working tree restored with in-progress changes
```

### The Stash Stack (LIFO)

Stashes are stored in a stack — Last In, First Out:

```
git stash list:
stash@{0}  ← most recent (pushed last)
stash@{1}  ← second most recent  ← task target
stash@{2}  ← oldest
```

`stash@{0}` is always the newest. When you `git stash` again, the new stash becomes `stash@{0}` and everything shifts down.

### `git stash apply` vs `git stash pop`

| Command | Restores changes | Removes from stash list |
|---------|-----------------|------------------------|
| `git stash apply stash@{N}` | ✅ | ❌ stash stays |
| `git stash pop stash@{N}` | ✅ | ✅ stash removed |

**`apply` is preferred when:**
- You want to keep the stash as a backup
- You're applying to multiple branches
- You're uncertain if the apply will conflict

**`pop` is preferred when:**
- You're done with the stash and want a clean list
- You're certain the restore succeeded

For this task, `apply` is the safer choice.

### What `git stash` Actually Saves

By default, `git stash` saves:
- ✅ Modified tracked files (staged and unstaged)
- ❌ Untracked new files (unless `git stash -u`)
- ❌ Ignored files (unless `git stash -a`)

```bash
git stash                # Save tracked changes only
git stash -u             # Also save untracked files
git stash -a             # Save everything including ignored
git stash push -m "WIP: login feature"  # With descriptive message
```

> **Real-world context:** Git stash is used constantly in real engineering workflows. A production alert fires while you're mid-feature — `git stash`, switch to hotfix branch, fix the issue, switch back, `git stash pop`. A code reviewer asks you to check out their branch — `git stash` your work first. Understanding stash identifiers and how to manage multiple stashes is a practical daily skill.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | Storage Server (`ststor01`) |
| User | natasha |
| Repository | `/usr/src/kodekloudrepos/official` |
| Target stash | `stash@{1}` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into Storage Server

```bash
ssh natasha@ststor01
```

### Step 2: Navigate to the repository

```bash
cd /usr/src/kodekloudrepos/official
```

### Step 3: List all stashes

```bash
git stash list
```

**Expected output:**
```
stash@{0}: WIP on master: abc1234 <commit message>
stash@{1}: WIP on master: def5678 <commit message>
```

Confirms `stash@{1}` exists.

### Step 4: Preview stash@{1} contents

```bash
git stash show stash@{1}
```

Shows which files were modified in this stash — good to know before applying.

```bash
git stash show -p stash@{1}
```

The `-p` flag shows the full diff — what exactly changed in those files.

### Step 5: Apply stash@{1}

```bash
git stash apply stash@{1}
```

**Expected output:**
```
On branch master
Changes not staged for commit:
        modified:   <filename>
```

The stash changes are now in the working tree. `stash@{1}` remains in the stash list (apply doesn't remove it).

### Step 6: Verify changes are present

```bash
git status
```

**Expected:** Modified files from the stash are shown as unstaged changes.

### Step 7: Stage all changes

```bash
git add .
```

### Step 8: Commit with a descriptive message

```bash
git commit -m "Restore stash@{1} changes"
```

**Expected:**
```
[master <hash>] Restore stash@{1} changes
```

### Step 9: Push to origin

```bash
git push origin master
```

### Step 10: Verify final state

```bash
git log --oneline -3
git stash list           # stash@{1} still present (apply doesn't remove)
```

✅ Stash restored, committed, and pushed.

---

## 📌 Commands Reference

```bash
# ─── Navigate ────────────────────────────────────────────
cd /usr/src/kodekloudrepos/official

# ─── Stash inspection ────────────────────────────────────
git stash list                        # List all stashes
git stash show stash@{1}              # Summary of changes in stash@{1}
git stash show -p stash@{1}           # Full diff of stash@{1}

# ─── Apply specific stash ────────────────────────────────
git stash apply stash@{1}             # Apply without removing from list
git stash pop stash@{1}               # Apply and remove from list

# ─── Stage and commit ────────────────────────────────────
git add .
git commit -m "Restore stash@{1} changes"

# ─── Push ────────────────────────────────────────────────
git push origin master

# ─── Stash management reference ──────────────────────────
git stash                             # Save current changes
git stash push -m "description"       # Save with message
git stash apply                       # Apply most recent (stash@{0})
git stash pop                         # Apply and remove most recent
git stash drop stash@{1}              # Delete specific stash
git stash clear                       # Delete ALL stashes (careful!)
git stash branch feature stash@{1}    # Create branch from stash
```

---

## ⚠️ Common Mistakes to Avoid

1. **Using `pop` when `apply` is safer** — `pop` removes the stash after applying. If the apply creates conflicts and things go wrong, the stash is gone. `apply` keeps it as a backup until you're confident everything worked.
2. **Wrong stash index** — `stash@{1}` not `stash@{2}` or `stash@{0}`. Always `git stash list` first to confirm the index before applying.
3. **Not staging after apply** — `git stash apply` restores changes to the working tree as **unstaged** modifications. You must `git add` before committing.
4. **Forgetting to push after commit** — The commit exists locally until `git push origin master`.
5. **Not previewing before applying** — Always `git stash show stash@{1}` first. If the stash was made on a different branch or different state, applying it could create unexpected conflicts.

---

## 🔍 Stash Conflict Resolution

If applying a stash creates conflicts:

```bash
git stash apply stash@{1}
# CONFLICT (content): Merge conflict in somefile.txt

# Fix conflicts in the file
vi somefile.txt

# Stage resolved files
git add somefile.txt

# Continue with commit
git commit -m "Restore stash@{1} changes"

# The stash@{1} still exists — drop it when done
git stash drop stash@{1}
```

---

## 🔗 References

- [`git stash` documentation](https://git-scm.com/docs/git-stash)
- [Atlassian — Git Stash](https://www.atlassian.com/git/tutorials/saving-changes/git-stash)
- [Git — Stashing and Cleaning](https://git-scm.com/book/en/v2/Git-Tools-Stashing-and-Cleaning)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
