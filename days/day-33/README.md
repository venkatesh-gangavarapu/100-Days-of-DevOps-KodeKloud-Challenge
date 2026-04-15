# Day 33 — Git Merge Conflict Resolution

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Version Control / Git / Conflict Resolution  
**Difficulty:** Intermediate  
**Phase:** Phase 3 — Kubernetes & Orchestration  
**Status:** ✅ Completed

---

## 📋 Task Summary

Max was trying to push changes to the `story-blog` repository but was rejected because Sarah had already pushed conflicting changes. The task was to:

1. Pull Sarah's changes from origin
2. Resolve the merge conflict in `story-index.txt`
3. Ensure all 4 story titles are present
4. Fix the typo: `Mooose` → `Mouse`
5. Commit and push to origin

---

## 🧠 Concept — Merge Conflicts

### Why Conflicts Happen

A conflict occurs when two developers modify **the same lines** of the same file independently. Git cannot decide which version to keep — it needs a human to resolve it.

```
Sarah pushes:          Max has locally:        Git's problem:
Line 3: The Fox        Line 3: The Lion         Same line, different content
         and Grapes             and Mooose       → CONFLICT
```

### The Conflict Markers

When Git detects a conflict, it pauses and inserts markers into the file:

```
<<<<<<< HEAD
Max's version of the conflicting lines
=======
Sarah's version of the conflicting lines
>>>>>>> origin/master
```

| Marker | Meaning |
|--------|---------|
| `<<<<<<< HEAD` | Start of YOUR local changes |
| `=======` | Divider between the two versions |
| `>>>>>>> origin/master` | Start of the INCOMING remote changes |

Resolution means: **remove all three markers** and keep the correct final content.

### The Pull → Conflict → Resolve → Push Cycle

```
git push → rejected (remote ahead)
        │
        ▼
git pull → conflict detected → files marked
        │
        ▼
edit files → remove markers → keep correct content
        │
        ▼
git add → git commit → git push ✅
```

> **Real-world context:** Merge conflicts are a daily reality in any team using Git. The engineers who handle them calmly and correctly — reading both sides before choosing — are the ones teams trust with critical merges. Conflicts aren't failures; they're Git asking for a human decision. Understanding how to read markers and resolve them cleanly is a fundamental collaboration skill.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | Storage Server (`ststor01`) |
| User | `max` / `Max_pass123` |
| Repository | `/home/max/story-blog` |
| Conflicting file | `story-index.txt` |
| Required fix | All 4 story titles + `Mooose` → `Mouse` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH as max

```bash
ssh max@ststor01
```

### Step 2: Navigate to the repository

```bash
cd /home/max/story-blog
```

### Step 3: Check current status

```bash
git status
git log --oneline
```

### Step 4: Attempt to push (see the actual error)

```bash
git push origin master
```

**Expected error:**
```
! [rejected]  master -> master (fetch first)
error: failed to push some refs to 'origin'
hint: Updates were rejected because the remote contains work that you do not have locally.
```

### Step 5: Pull from origin

```bash
git pull origin master
```

If Git can auto-merge — great. If there's a conflict:
```
CONFLICT (content): Merge conflict in story-index.txt
Automatic merge failed; fix conflicts and then commit the result.
```

### Step 6: Check the conflict markers

```bash
cat story-index.txt
```

**Example conflicted file:**
```
1. The Lion and the Mouse
<<<<<<< HEAD
2. The Max's New Story
=======
2. The Fox and the Grapes
>>>>>>> origin/master
3. ...
```

### Step 7: Resolve the conflict

```bash
vi story-index.txt
```

Edit the file to include **all 4 stories** and fix `Mooose` → `Mouse`. The final file should look like:

```
1. The Lion and the Mouse
2. The Fox and the Grapes
3. <story 3 title>
4. <story 4 title>
```

**Key rules while resolving:**
- Remove ALL conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
- Keep content from BOTH sides where applicable
- Fix `Mooose` → `Mouse` while you're in the file
- Verify 4 story titles are present

### Step 8: Verify no conflict markers remain

```bash
grep -n "<<<<<<\|=======\|>>>>>>>" story-index.txt
# Should return nothing — no markers left
```

### Step 9: Verify typo is fixed

```bash
grep -i "mooose" story-index.txt
# Should return nothing
grep -i "mouse" story-index.txt
# Should show: The Lion and the Mouse ✅
```

### Step 10: Stage the resolved file

```bash
git add story-index.txt
```

### Step 11: Commit the resolution

```bash
git commit -m "Resolved merge conflict in story-index.txt, fix Mooose typo"
```

### Step 12: Push to origin

```bash
git push origin master
```

**Expected:**
```
master -> master ✅
```

### Step 13: Verify on Gitea UI

- Login as `max` or `sarah`
- Navigate to `story-blog` repository
- Open `story-index.txt`
- Confirm: 4 story titles present, `Mouse` (not `Mooose`) ✅

📸 **Take a screenshot** of the final `story-index.txt` in Gitea.

---

## 📌 Commands Reference

```bash
# ─── Identify the problem ────────────────────────────────
git status
git push origin master           # See rejection error
git log --oneline                # Local commits
git log --oneline origin/master  # Remote commits

# ─── Pull and handle conflict ────────────────────────────
git pull origin master           # Fetch + merge remote changes

# ─── After conflict is detected ──────────────────────────
git status                       # Shows "both modified" files
cat story-index.txt              # Read the conflict markers
vi story-index.txt               # Resolve manually

# ─── Verify resolution ───────────────────────────────────
grep -n "<<<<<<\|=======\|>>>>>>>" story-index.txt  # No markers = clean
grep -i "mooose" story-index.txt                    # Should be empty
grep -i "mouse" story-index.txt                     # Should show correct line

# ─── Complete the resolution ─────────────────────────────
git add story-index.txt
git commit -m "Resolved merge conflict in story-index.txt, fix Mooose typo"
git push origin master

# ─── Quick typo fix (if not caught during conflict) ──────
sed -i 's/Mooose/Mouse/g' story-index.txt
git add story-index.txt
git commit -m "Fix typo: Mooose -> Mouse"
git push origin master
```

---

## ⚠️ Common Mistakes to Avoid

1. **Leaving conflict markers in the file** — The most common mistake. Always `grep` for `<<<<<<<` before staging to confirm markers are gone.
2. **Keeping only one side of the conflict** — Both Max and Sarah's stories belong in the index. Read both sides before deciding — the correct resolution often includes content from both.
3. **Not fixing the typo during conflict resolution** — The typo fix and conflict resolution can be done in the same edit. Fix both at once rather than making two separate commits.
4. **Force pushing instead of pulling** — `git push -f` would overwrite Sarah's work entirely. Always `git pull` first to incorporate both changes.
5. **Not verifying in Gitea** — Always check the final state in the UI. The task requires visual confirmation with a screenshot.

---

## 🔍 Reading Conflict Markers — A Mental Model

```
<<<<<<< HEAD           ← "What I have locally (Max's changes)"
Max's content here
=======                ← "Divider — the two versions are separated here"
Sarah's content here
>>>>>>> origin/master  ← "What came from the remote (Sarah's changes)"
```

Resolution options:
1. **Keep yours:** Remove markers + Sarah's section
2. **Keep theirs:** Remove markers + Max's section  
3. **Keep both:** Remove all markers, arrange both pieces correctly ← usually correct
4. **Write new:** Remove everything and write a fresh version that incorporates both

For this task, option 3 is correct — all 4 stories need to be in the index.

---

## 🔗 References

- [Git — Basic Merge Conflicts](https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging#_basic_merge_conflicts)
- [Atlassian — Resolving Merge Conflicts](https://www.atlassian.com/git/tutorials/using-branches/merge-conflicts)
- [`git pull` documentation](https://git-scm.com/docs/git-pull)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
