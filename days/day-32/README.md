# Day 32 — Git Rebase: Replaying Feature Branch Commits onto Master

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Version Control / Git  
**Difficulty:** Intermediate  
**Phase:** Phase 3 — Kubernetes & Orchestration  
**Status:** ✅ Completed

---

## 📋 Task Summary

In `/usr/src/kodekloudrepos/beta` on Storage Server, rebase the `feature` branch onto `master` to incorporate the latest master changes into feature — without a merge commit and without losing any feature branch work.

---

## 🧠 Concept — `git rebase` vs `git merge`

### The Core Difference

Both `git rebase` and `git merge` integrate changes from one branch into another. The difference is entirely about **history shape**.

```
Starting point:
master:  A ── B ── C
feature: A ── B ── D ── E   (D and E are feature-only commits)

─────────────────────────────────────────────────────
After git merge master (from feature branch):
master:  A ── B ── C
feature: A ── B ── D ── E ── M(merge commit)
                    \________/
History preserved but M is noisy

─────────────────────────────────────────────────────
After git rebase master (from feature branch):
master:  A ── B ── C
feature: A ── B ── C ── D' ── E'
                   ↑
            feature now starts from C
            D' and E' are same changes as D and E
            but with new hashes (new parent = C)
```

### What Rebase Actually Does

`git rebase master` while on `feature`:

1. Finds the common ancestor of `feature` and `master` (commit `B`)
2. Saves the feature-only commits (`D`, `E`) as patches
3. Resets `feature` to point at `master`'s tip (`C`)
4. Replays the saved patches one by one as new commits (`D'`, `E'`)

The changes in `D` and `E` are fully preserved — just replayed with `C` as the new base. That's why the task says "without losing any data."

### Why Rebase Creates New Commit Hashes

Commit hashes in Git are deterministic — they're based on content, author, timestamp, AND the parent commit hash. When rebase replays `D` with `C` as its parent instead of `B`, the hash changes. Same changes, different hash. This is why force push is required after rebasing a pushed branch.

### When to Use Each

| Situation | Tool | Reason |
|-----------|------|--------|
| Keeping feature branch up-to-date with master | `git rebase master` | Clean linear history |
| Merging completed feature into master | `git merge` or `git merge --no-ff` | Preserves feature context |
| Public/shared branch | `git merge` | Never rewrite shared history |
| Personal feature branch | `git rebase` | Clean history before PR |
| Open source contribution | `git rebase upstream/main` | Standard expectation |

> **Real-world context:** Most professional teams require feature branches to be rebased on main before submitting a PR — it ensures the feature is tested against the latest code and keeps the history linear and readable. GitHub, GitLab, and Gitea all offer "Rebase and Merge" as a PR merge strategy. CI/CD pipelines benefit from linear history because bisecting bugs (`git bisect`) works more reliably without merge commits cluttering the log.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | Storage Server (`ststor01`) |
| User | natasha |
| Repository | `/usr/src/kodekloudrepos/beta` |
| Branch to rebase | `feature` |
| Rebase onto | `master` |

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

### Step 3: Inspect current branch state

```bash
git log --oneline --all --graph
```

**Example output before rebase:**
```
* def5678 (feature) feature commit 2
* abc1234 feature commit 1
| * ghi9012 (HEAD -> master, origin/master) new master commit
|/
* xyz0001 initial commit
```

This confirms master has moved ahead of where feature branched off.

### Step 4: Switch to feature branch

```bash
git checkout feature
```

### Step 5: Rebase feature onto master

```bash
git rebase master
```

**Expected output:**
```
Successfully rebased and updated refs/heads/feature.
```

If there are no conflicts, rebase completes automatically.

### Step 6: Verify clean linear history

```bash
git log --oneline --all --graph
```

**Expected output after rebase:**
```
* def9999 (HEAD -> feature) feature commit 2
* abc8888 feature commit 1
* ghi9012 (master, origin/master) new master commit
* xyz0001 initial commit
```

Key observations:
- No merge commit ✅
- Feature commits now sit on top of master's latest commit ✅
- Feature branch commits have new hashes (`def9999`, `abc8888`) — expected ✅

### Step 7: Force push the feature branch

```bash
git push -f origin feature
```

Force push is **required** because rebase rewrote the feature branch's commit history. The remote still has the old unrebased commits.

**Expected:**
```
+ abc1234...def9999 feature -> feature (forced update)
```

### Step 8: Push master if needed

```bash
git push origin master
```

### Step 9: Final verification

```bash
git log --oneline --all --graph
```

Both branches visible with clean linear history. ✅

---

## 📌 Commands Reference

```bash
# ─── Navigate ────────────────────────────────────────────
cd /usr/src/kodekloudrepos/beta

# ─── Inspect state ───────────────────────────────────────
git log --oneline --all --graph      # Visual branch diagram
git branch -a                        # All branches
git status                           # Current branch state

# ─── Rebase ──────────────────────────────────────────────
git checkout feature                 # Switch to branch being rebased
git rebase master                    # Replay feature commits onto master

# ─── Push ────────────────────────────────────────────────
git push -f origin feature           # Force push required after rebase
git push origin master               # Push master if needed

# ─── Rebase conflict resolution ──────────────────────────
# If conflicts occur during rebase:
git status                           # See conflicting files
vi <conflicting-file>                # Resolve conflicts manually
git add <conflicting-file>           # Stage resolved file
git rebase --continue                # Continue replaying commits
# OR
git rebase --abort                   # Abort entire rebase

# ─── Other rebase variations ─────────────────────────────
git rebase -i HEAD~3                 # Interactive rebase last 3 commits
git rebase -i master                 # Interactive rebase onto master
git rebase --onto master feature~2   # Rebase only last 2 feature commits
```

---

## ⚠️ Common Mistakes to Avoid

1. **Rebasing a shared/public branch** — Rebase rewrites commit hashes. If anyone else has pulled `feature`, their history diverges. Only rebase branches that are yours alone or that the team has explicitly agreed to rebase.
2. **Forgetting force push after rebase** — Normal `git push` after rebase is rejected because local history diverged from remote. `git push -f origin feature` is required.
3. **Running `git rebase` on master** — `git rebase master` must be run **while on the feature branch**. Running it on master would rebase master onto feature — the opposite of what's needed.
4. **Aborting mid-conflict incorrectly** — If rebase pauses on a conflict and you get confused, `git rebase --abort` safely returns you to the pre-rebase state. Never commit conflict markers.
5. **Not verifying with `--graph` after rebase** — Always confirm the history is linear and both branches look correct before pushing.

---

## 🔍 Rebase vs Merge — Visual Comparison

```
git merge master (from feature):
──── A ── B ── C (master)
      \             \
       D ── E ── M (feature, with merge commit)

git rebase master (from feature):
──── A ── B ── C (master)
                \
                 D' ── E' (feature, clean linear)

Same data. Different history shape.
```

The key insight: `git rebase` doesn't lose work — it preserves every change from `D` and `E`. It just changes the commits' parent, giving them new hashes as a result.

---

## 🔗 References

- [`git rebase` documentation](https://git-scm.com/docs/git-rebase)
- [Atlassian — Merging vs Rebasing](https://www.atlassian.com/git/tutorials/merging-vs-rebasing)
- [Git — Rebasing](https://git-scm.com/book/en/v2/Git-Branching-Rebasing)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: Rebase paused mid-way with a conflict. You're now in "detached REBASE state" and don't know what to do. What's the recovery procedure?**

```bash
# Git is paused replaying commit D' and hit a conflict
git status
# interactive rebase in progress; onto ghi9012
# You are currently rebasing branch 'feature' on 'ghi9012'
#   (fix conflicts and then run "git rebase --continue")
#   (use "git rebase --skip" to skip this patch)
#   (use "git rebase --abort" to check out the original branch)

# Step 1: See which files are conflicting
git status
# both modified: src/app.py

# Step 2: Open and resolve conflicts
vi src/app.py  # remove <<<<, ====, >>>> markers, keep correct content

# Step 3: Stage resolved files
git add src/app.py

# Step 4: Continue — do NOT git commit here, let rebase do it
git rebase --continue
# If there are more commits in the rebase, this will replay the next one
# Each commit with conflicts requires this same resolve → add → continue cycle

# OR, if this commit's changes are no longer relevant:
git rebase --skip   # Skip this one commit entirely

# OR, abort everything and go back to pre-rebase state:
git rebase --abort  # Safe exit — restores feature branch exactly as before
```

> The critical mistake is running `git commit` during a rebase conflict instead of `git rebase --continue`. Committing manually creates an extra commit mid-rebase and produces a tangled history. Always use `--continue` to let rebase handle the commit after you resolve conflicts.

---

**Q2: Your team requires all PRs to be rebased on main before merging. What does the daily workflow look like for a developer with a week-old feature branch?**

```bash
# Morning routine before starting work:
git checkout main
git pull origin main          # Get latest main

git checkout feature/my-work
git rebase main               # Replay my commits on latest main

# If conflicts: resolve → git add → git rebase --continue

# Force push (required after rebase)
git push -f origin feature/my-work

# Now open/update the PR — it shows clean diff against latest main
# CI pipeline runs against current code, not week-old code
```

> This is the standard professional workflow. Rebasing before opening a PR ensures: (1) CI tests run against the latest code, catching integration problems early, (2) the reviewer sees a clean diff with no noise from other changes, (3) if the PR is merged, it fast-forwards cleanly with no merge commit. Most teams configure their CI to auto-rebase or require the PR branch to be up-to-date before merge is enabled.

---

**Q3: What's interactive rebase (`git rebase -i`) and when would a DevOps engineer use it?**

```bash
# Squash 5 messy WIP commits into 1 clean commit before PR
git rebase -i HEAD~5

# Editor opens with:
# pick abc1234 WIP
# pick def5678 fix typo
# pick ghi9012 actually fix it
# pick jkl3456 final fix
# pick mno7890 cleanup

# Change to:
# pick abc1234 WIP        ← keep this as the base commit
# squash def5678 fix typo ← squash into previous
# squash ghi9012 actually fix it
# squash jkl3456 final fix
# squash mno7890 cleanup

# Git then prompts for a single commit message for all 5
# Result: 1 clean commit instead of 5 messy ones

# Other useful interactive rebase operations:
# reword → change commit message
# edit   → pause and amend the commit
# drop   → delete this commit entirely
# fixup  → squash but discard this commit's message
```

> Interactive rebase is how DevOps engineers "clean up the sausage factory" before a code review. A feature developed in 15 messy commits becomes 3 logical, well-described commits. This makes `git bisect` more effective, code review clearer, and `git log` on main readable. It's a powerful but exclusively local/pre-push tool — never interactive rebase after pushing to a shared branch.

---

**Q4: When should you choose `git merge` over `git rebase` for integrating a feature branch into main?**

> The rule most teams use:
>
> **Use rebase when:**
> - You want linear history (no merge commits)
> - The branch is your own and hasn't been shared
> - You're updating a feature branch with latest main before a PR
> - The project/team explicitly requires "rebase and merge" as the merge strategy
>
> **Use merge when:**
> - The branch is shared (others have pulled it) — never rebase shared branches
> - You want an explicit merge commit to record when a feature landed (audit trail)
> - Using `--no-ff` to preserve feature branch topology in history
> - You're merging a long-lived release or develop branch where the merge commit IS meaningful
>
> ```bash
> # GitHub/GitLab/Gitea offer three merge strategies per-repository:
> # "Create a merge commit"  → git merge --no-ff
> # "Squash and merge"       → all feature commits become 1 commit
> # "Rebase and merge"       → git rebase, then fast-forward
> ```
>
> Most modern teams use "Squash and merge" for feature branches — it keeps main history clean and each PR is a single commit. Rebase is for pre-PR cleanup on personal branches.

---

**Q5: `git rebase` vs `git merge` produced different results for the same feature. Why do the final commits look different?**

```bash
# Scenario: master has commits A, B, C. Feature has D, E (branched from B).

# After git merge master (from feature):
git log --oneline --graph
# * M  (feature) Merge branch 'master' into feature
# |\
# | * C  (master)
# * | E
# * | D
# |/
# * B
# * A

# After git rebase master (from feature):
git log --oneline --graph
# * E' (feature)
# * D'
# * C  (master)
# * B
# * A
```

> Same changes, different shapes. With merge: D and E are original commits, M is a new merge commit, the graph forks and rejoins. With rebase: D' and E' have the same code as D and E but NEW commit hashes (because their parent changed from B to C). The feature branch appears to have been written starting from C — linear, clean, but with rewritten history. This is why `git push -f` is required after rebase: the remote's D and E differ from local D' and E'.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
