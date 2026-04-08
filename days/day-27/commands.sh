#!/bin/bash
# Day 27 — Git Revert HEAD to Previous Commit
# Challenge: KodeKloud 100 Days of DevOps — Phase 2
# Task: Revert HEAD commit in /usr/src/kodekloudrepos/games
#       Use commit message: "revert games" (all lowercase)

# ─────────────────────────────────────────
# SSH into Storage Server
# ssh natasha@ststor01    (Password: Bl@kW)
# ─────────────────────────────────────────

# STEP 1: Navigate to the repository
cd /usr/src/kodekloudrepos/games

# STEP 2: Check commit log — identify HEAD and previous commit
git log --oneline
# Expected:
# abc1234 (HEAD -> master) <bad commit>
# def5678 initial commit

# STEP 3: See exactly what the bad commit changed
git show HEAD

# STEP 4: Stage the revert WITHOUT auto-committing
# (gives us control over the exact commit message)
git revert --no-commit HEAD

# STEP 5: Commit with the EXACT required message (all lowercase)
git commit -m "revert games"

# STEP 6: Verify commit log
git log --oneline
# Expected:
# xyz9999 (HEAD -> master) revert games
# abc1234 <bad commit>
# def5678 initial commit

# STEP 7: Verify working tree matches initial commit state
git diff HEAD~2 HEAD
# Expected: empty diff (revert cancels bad commit — net zero change)

# STEP 8: Push to origin
git push origin master

# ─────────────────────────────────────────
# WHY NOT git reset --hard?
# ─────────────────────────────────────────
# git reset rewrites history — safe only for local unpushed commits
# git revert creates a new commit — safe for pushed shared branches
# Never force-push to a shared branch — breaks team clones
