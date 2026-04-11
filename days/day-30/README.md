# Day 30 — Git Reset Hard: Permanently Rewriting Commit History

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Version Control / Git  
**Difficulty:** Intermediate  
**Phase:** 🏁 Phase 2 Complete — Infrastructure & Networking  
**Status:** ✅ Completed

---

## 📋 Task Summary

The test repository `/usr/src/kodekloudrepos/media` on Storage Server has accumulated test commits that need to be permanently removed. Reset the commit history so only two commits remain — `initial commit` and `add data.txt file` — then force push to origin.

---

## 🧠 Concept — `git reset --hard` vs `git revert`

This challenge explicitly requires removing commits from history — the opposite of what we did on Day 27. Understanding when each tool is correct is essential.

### The Decision Framework

| Situation | Tool | Why |
|-----------|------|-----|
| Undo pushed commits on **shared** branch | `git revert` | Preserves history, safe for team |
| Remove commits from a **test/cleanup** scenario | `git reset --hard` + force push | Actually deletes commits |
| Undo local **unpushed** commits | `git reset --hard` | No remote to worry about |

### What `git reset --hard` Does

```
Before reset:
──── A (initial commit) ──── B (add data.txt) ──── C ──── D  ← HEAD

After git reset --hard <hash of B>:
──── A (initial commit) ──── B (add data.txt)  ← HEAD

C and D are gone from the branch history
```

`--hard` moves the HEAD pointer back to the target commit AND discards all working tree changes. There are three reset modes:

| Mode | HEAD moves | Staging area | Working tree |
|------|-----------|--------------|--------------|
| `--soft` | ✅ Yes | Unchanged | Unchanged |
| `--mixed` (default) | ✅ Yes | Cleared | Unchanged |
| `--hard` | ✅ Yes | Cleared | **Discarded** |

`--hard` is the most destructive — it discards everything after the target commit completely.

### Why Force Push is Required After Reset

After `git reset --hard`, the local branch history diverges from the remote:

```
local master:  A ──── B  ← HEAD (commits C,D removed)
origin/master: A ──── B ──── C ──── D  ← still has old commits
```

A normal `git push` is rejected — Git sees the local branch is behind the remote. `git push --force` overwrites the remote with the local state, permanently removing C and D from `origin/master` too.

### When Force Push Is Acceptable

| Scenario | Force push OK? |
|----------|---------------|
| Test/cleanup repo as in this task | ✅ Yes — explicitly requested |
| Your own feature branch, nobody else has pulled | ✅ Yes |
| Shared `master`/`main` in production | ❌ Never — breaks team clones |
| After interactive rebase on shared branch | ❌ Never |

> **Real-world context:** Force pushing to clean test repositories, remove sensitive data accidentally committed (API keys, passwords), or squash a messy commit history before a code review are all valid uses. The hard rule: force push is only safe when you are the only person working with that branch, or when the team has explicitly coordinated and is prepared for the history change.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | Storage Server (`ststor01`) |
| User | natasha |
| Repository | `/usr/src/kodekloudrepos/media` |
| Target commit | `add data.txt file` |
| Commits to remove | Everything after `add data.txt file` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into Storage Server

```bash
ssh natasha@ststor01
```

### Step 2: Navigate to the repository

```bash
cd /usr/src/kodekloudrepos/media
```

### Step 3: View full commit history

```bash
git log --oneline
```

**Example output:**
```
ghi9012 (HEAD -> master) some test commit
def5678 another test commit
abc1234 add data.txt file        ← this is our target
xyz0001 initial commit
```

Note the hash of `add data.txt file` — e.g. `abc1234`.

### Step 4: Reset HEAD to the target commit

```bash
git reset --hard abc1234
```

Replace `abc1234` with the actual hash.

**Expected output:**
```
HEAD is now at abc1234 add data.txt file
```

### Step 5: Verify only 2 commits remain

```bash
git log --oneline
```

**Expected output:**
```
abc1234 (HEAD -> master) add data.txt file
xyz0001 initial commit
```

Exactly 2 commits. ✅

### Step 6: Force push to origin

```bash
git push -f origin master
```

**Expected output:**
```
+ ghi9012...abc1234 master -> master (forced update)
```

The `+` and `(forced update)` confirm the force push succeeded.

### Step 7: Verify remote matches local

```bash
git log --oneline origin/master
```

**Expected:**
```
abc1234 (HEAD -> master, origin/master) add data.txt file
xyz0001 initial commit
```

Both local and remote now have exactly 2 commits. ✅

---

## 📌 Commands Reference

```bash
# ─── Navigate ────────────────────────────────────────────
cd /usr/src/kodekloudrepos/media

# ─── View history ────────────────────────────────────────
git log --oneline                          # See all commits
git log --oneline --all                    # Including remote refs

# ─── Find target commit hash ─────────────────────────────
git log --oneline --grep="add data.txt"    # Search by message

# ─── Reset to specific commit ────────────────────────────
git reset --hard <hash>                    # Move HEAD, discard everything after

# ─── Verify ──────────────────────────────────────────────
git log --oneline                          # Should show exactly 2 commits
git status                                 # Should be clean

# ─── Force push ──────────────────────────────────────────
git push -f origin master                  # Overwrite remote history
git push --force origin master             # Same, long form

# ─── Verify remote matches ───────────────────────────────
git fetch origin
git log --oneline origin/master

# ─── Reset mode reference ────────────────────────────────
git reset --soft  HEAD~1    # Move HEAD, keep changes staged
git reset --mixed HEAD~1    # Move HEAD, unstage changes (default)
git reset --hard  HEAD~1    # Move HEAD, discard all changes
git reset --hard  <hash>    # Jump directly to specific commit
```

---

## ⚠️ Common Mistakes to Avoid

1. **Using `git revert` when history deletion is required** — `git revert` adds a new commit that undoes changes but keeps all commits. The task requires only 2 commits in history — revert would result in 5+ commits.
2. **Forgetting `--hard`** — `git reset <hash>` without a mode defaults to `--mixed`, which moves HEAD but leaves files as unstaged changes. `--hard` is required to cleanly discard everything.
3. **Normal push after reset** — After `git reset --hard`, `git push` without `-f` will be rejected. The remote is "ahead" of local. Force is always required after rewriting history.
4. **Not verifying commit count before pushing** — Always run `git log --oneline` after the reset to confirm exactly 2 commits before force pushing. One extra commit means the reset targeted the wrong hash.
5. **Using this on production shared branches** — Force push on shared branches breaks every team member's local clone. This is only acceptable on test repos or personal branches, never on master in a production environment.

---

## 🔍 `git reset --hard` vs `git revert` — The Complete Picture

```
Day 27: git revert (safe undo on shared branch)
────────────────────────────────────────────────
A ──── B ──── C (bad) ──── D (revert C) ← HEAD
History preserved. New commit added. Safe to push normally.

Day 30: git reset --hard (destructive cleanup on test repo)
────────────────────────────────────────────────────────────
Before: A ──── B ──── C ──── D ← HEAD
After:  A ──── B ← HEAD
C and D gone. Force push required. Only for test/cleanup use.
```

Knowing which tool to reach for — and more importantly why — is what separates someone who knows Git commands from someone who understands Git.

---

## 🔗 References

- [`git reset` documentation](https://git-scm.com/docs/git-reset)
- [Atlassian — git reset](https://www.atlassian.com/git/tutorials/undoing-changes/git-reset)
- [Git — Reset Demystified](https://git-scm.com/book/en/v2/Git-Tools-Reset-Demystified)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
