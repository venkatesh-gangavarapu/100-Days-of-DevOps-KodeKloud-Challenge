# Day 25 — Complete Git Workflow: Branch → Add → Commit → Merge → Push

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Version Control / Git  
**Difficulty:** Intermediate  
**Phase:** Phase 2 — Infrastructure & Networking  
**Status:** ✅ Completed

---

## 📋 Task Summary

Complete end-to-end Git workflow on the `media` repository on Storage Server:

1. Create branch `xfusion` from `master`
2. Copy `/tmp/index.html` into the repo
3. `git add` and `git commit` the file on `xfusion`
4. Merge `xfusion` back into `master`
5. Push **both branches** to origin

---

## 🧠 Concept — The Complete Git Feature Branch Workflow

This task combines every Git operation from Days 21–24 into one complete workflow — the same cycle that development teams repeat dozens of times per week.

### The Full Cycle Visualized

```
origin/master ──── C1 ──── C2 ─────────────────────────── C3(merge) ──►
                              \                             /
                               └── xfusion: add index.html ──►

Local:
master  ──── C1 ──── C2 ──────────────────────────────── C3(merge)
                      \                                  /
                       xfusion ──── C_index.html ────────
```

### Why Push Both Branches?

After merging `xfusion` into `master` locally, two things need to be pushed:

1. **`origin/xfusion`** — So the remote knows this branch exists with its commits. Other team members can check it out, review the history, or continue working on it.
2. **`origin/master`** — So the remote receives the merge commit and `master` on the server reflects the merged state.

Pushing only `master` would leave `origin/xfusion` missing. Pushing only `xfusion` would leave the remote `master` behind your local merge.

### `git merge` — Fast-Forward vs Merge Commit

```bash
git merge xfusion
```

Since `master` hasn't changed since `xfusion` branched off, Git performs a **fast-forward merge** — it simply moves the `master` pointer forward to the `xfusion` commit. No merge commit is created:

```
Before merge:               After fast-forward merge:
master → C2                 master → C3 (index.html commit)
xfusion → C3               xfusion → C3
```

If you want to preserve the branch history explicitly:
```bash
git merge --no-ff xfusion    # Forces a merge commit even on fast-forward
```

> **Real-world context:** This complete workflow — branch, add, commit, merge, push — is the atomic unit of feature development in every team using Git. CI/CD pipelines trigger on pushes to specific branches. Code review processes are built around PRs between branches. Automated testing runs on branch pushes. Understanding each step of this workflow, and why the order matters, is foundational DevOps knowledge.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | Storage Server (`ststor01`) |
| User | natasha |
| Repository | `/usr/src/kodekloudrepos/media` |
| Remote | `/opt/media.git` |
| Source branch | `master` |
| Feature branch | `xfusion` |
| File to add | `/tmp/index.html` |

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

### Step 3: Verify current state

```bash
git status
git branch
git log --oneline -3
```

Clean working tree, on master, aware of commit history before making changes.

### Step 4: Ensure on master

```bash
git checkout master
```

### Step 5: Create xfusion branch from master

```bash
git checkout -b xfusion
```

**Expected:**
```
Switched to a new branch 'xfusion'
```

### Step 6: Copy index.html into the repository

```bash
cp /tmp/index.html .
```

### Step 7: Verify the file is present and untracked

```bash
git status
```

**Expected:**
```
On branch xfusion
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        index.html
```

### Step 8: Stage the file

```bash
git add index.html
```

**Verify staging:**
```bash
git status
```

**Expected:**
```
On branch xfusion
Changes to be committed:
        new file:   index.html
```

### Step 9: Commit the file

```bash
git commit -m "Add index.html to xfusion branch"
```

**Expected:**
```
[xfusion <hash>] Add index.html to xfusion branch
 1 file changed, 1 insertion(+)
 create mode 100644 index.html
```

### Step 10: Push xfusion branch to origin

```bash
git push origin xfusion
```

**Expected:**
```
To /opt/media.git
 * [new branch]      xfusion -> xfusion
```

### Step 11: Switch back to master

```bash
git checkout master
```

### Step 12: Merge xfusion into master

```bash
git merge xfusion
```

**Expected (fast-forward):**
```
Updating <hash>..<hash>
Fast-forward
 index.html | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 index.html
```

### Step 13: Push master to origin

```bash
git push origin master
```

**Expected:**
```
To /opt/media.git
   <hash>..<hash>  master -> master
```

### Step 14: Verify full state

```bash
git log --oneline --all --graph
```

**Expected:**
```
* <hash> (HEAD -> master, origin/master, origin/xfusion, xfusion) Add index.html to xfusion branch
* <hash> Initial commit
```

Both local and remote branches point to the same commit. ✅

---

## 📌 Commands Reference

```bash
# ─── Setup ───────────────────────────────────────────────
cd /usr/src/kodekloudrepos/media
git status && git branch

# ─── Branch ──────────────────────────────────────────────
git checkout master
git checkout -b xfusion

# ─── Add file ────────────────────────────────────────────
cp /tmp/index.html .
git status                          # Confirm untracked
git add index.html
git status                          # Confirm staged

# ─── Commit ──────────────────────────────────────────────
git commit -m "Add index.html to xfusion branch"
git log --oneline -3                # Confirm commit

# ─── Push xfusion ────────────────────────────────────────
git push origin xfusion

# ─── Merge to master ─────────────────────────────────────
git checkout master
git merge xfusion
git log --oneline -3                # Confirm merge

# ─── Push master ─────────────────────────────────────────
git push origin master

# ─── Final verification ──────────────────────────────────
git log --oneline --all --graph
git branch -a                       # All local + remote branches
```

---

## ⚠️ Common Mistakes to Avoid

1. **Pushing only one branch** — Both `xfusion` and `master` must be pushed. The task explicitly requires pushing changes to origin for both.
2. **Forgetting `git add` before `git commit`** — `git commit` only commits staged changes. A file copied into the repo is untracked until `git add` is run.
3. **Merging before pushing xfusion** — Push `xfusion` to origin before merging to master. This ensures the remote has `xfusion`'s history independently — not just as part of the master merge.
4. **Copying the file to the wrong location** — `cp /tmp/index.html .` copies to the current directory (the repo root). Running this from outside the repo directory would place it in the wrong path.
5. **Not verifying `git status` between steps** — Each `git status` call confirms the expected state before the next operation. This catches mistakes before they compound.

---

## 🔍 Git State at Each Step

```
Step 3: master → C1, working tree clean
Step 5: xfusion created → points to C1 (same as master)
Step 7: xfusion, index.html untracked
Step 8: xfusion, index.html staged
Step 9: xfusion → C2 (index.html committed)
Step 10: origin/xfusion → C2 ✅
Step 11: switched back to master → C1 (index.html not here yet)
Step 12: master → C2 (fast-forward merge, index.html now on master)
Step 13: origin/master → C2 ✅
```

---

## 🔗 References

- [Git Branching — Basic Branching and Merging](https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging)
- [`git merge` documentation](https://git-scm.com/docs/git-merge)
- [`git push` documentation](https://git-scm.com/docs/git-push)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: You pushed the feature branch but forgot to push master after merging. The CI pipeline reports master is behind. How do you fix it?**

```bash
# Check local vs remote state
git log --oneline origin/master..master
# Shows commits on local master not yet on origin

# Push master to origin
git push origin master

# Verify remote is in sync
git fetch origin
git log --oneline origin/master
```

> After merging a feature branch into master locally, you must explicitly push master. The merge commit only exists locally until pushed. CI pipelines check `origin/master` — if you don't push, the pipeline doesn't see the merged code.

---

**Q2: The merge was a fast-forward. What does that mean and when does it NOT fast-forward?**

> **Fast-forward**: master hasn't changed since you branched. Git just moves the master pointer forward to the feature tip — no merge commit created.
>
> **Not fast-forward** (creates a merge commit): master has new commits since you branched off. Git creates a merge commit with two parents.
>
> ```bash
> # Force a merge commit even on fast-forward (preserves branch history):
> git merge --no-ff xfusion
>
> # Check if merge will be a fast-forward:
> git log --oneline master..xfusion     # commits in xfusion not in master
> git log --oneline xfusion..master     # commits in master not in xfusion (if any → not FF)
> ```
>
> Many teams use `--no-ff` to preserve branch topology in history, making it easier to see which commits belonged to which feature.

---

**Q3: `git push origin xfusion` was rejected with "non-fast-forward". What happened and how do you fix it?**

```bash
# Someone else pushed to origin/xfusion after you last pulled
git fetch origin
git log --oneline origin/xfusion..xfusion   # your commits ahead
git log --oneline xfusion..origin/xfusion   # their commits you don't have

# Option 1: Merge their changes into yours
git pull origin xfusion
git push origin xfusion

# Option 2: Rebase your commits on top of theirs (cleaner history)
git fetch origin
git rebase origin/xfusion
git push origin xfusion
```

> "Non-fast-forward" push rejection means the remote has commits your local branch doesn't have. Git refuses to overwrite them. Fetch first, integrate, then push.

---

**Q4: How do you write a meaningful commit message? What makes a good vs bad commit message?**

```bash
# Bad commit messages:
git commit -m "fix"
git commit -m "changes"
git commit -m "wip"
git commit -m "updated files"

# Good commit messages (imperative mood, explains WHY):
git commit -m "Add index.html with placeholder content for xfusion branch"
git commit -m "Fix login redirect loop when session expires"
git commit -m "Upgrade nginx from 1.20 to 1.24 for CVE-2023-44487 fix"
```

> Good commit messages: use imperative mood ("Add", not "Added"), are 50 chars or less for the subject, explain WHY not WHAT (the diff shows what), and reference ticket numbers when relevant. Bad messages make `git log` useless and blame archaeology painful.

---

**Q5: What's the difference between `git push origin xfusion` and `git push --set-upstream origin xfusion`?**

```bash
# First-time push — sets tracking relationship
git push --set-upstream origin xfusion
# Or shorter:
git push -u origin xfusion

# After tracking is set — shorthand works
git push           # pushes current branch to its tracked remote branch
git pull           # pulls from tracked remote branch

# Check tracking relationship
git branch -vv
# * xfusion  abc1234 [origin/xfusion] Add index.html
```

> `-u` (set-upstream) creates a tracking relationship between the local branch and the remote branch. After that, plain `git push` and `git pull` know which remote/branch to use without specifying them explicitly.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
