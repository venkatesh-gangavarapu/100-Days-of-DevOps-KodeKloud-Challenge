#!/bin/bash
# Day 25 — Complete Git Workflow: Branch → Add → Commit → Merge → Push
# Challenge: KodeKloud 100 Days of DevOps — Phase 2
# Task: Create xfusion branch, add index.html, commit, merge to master, push both

# ─────────────────────────────────────────
# SSH into Storage Server
# ssh natasha@ststor01    (Password: Bl@kW)
# ─────────────────────────────────────────

# STEP 1: Navigate to repository
cd /usr/src/kodekloudrepos/media

# STEP 2: Verify current state (always check before changing anything)
git status
git branch
git log --oneline -3

# STEP 3: Ensure on master
git checkout master

# STEP 4: Create xfusion branch from master
git checkout -b xfusion
# Expected: Switched to a new branch 'xfusion'

# STEP 5: Copy index.html from /tmp into the repo
cp /tmp/index.html .

# STEP 6: Verify file is present and untracked
git status
# Expected: index.html as untracked file

# STEP 7: Stage the file
git add index.html

# Confirm staged
git status
# Expected: new file: index.html under "Changes to be committed"

# STEP 8: Commit
git commit -m "Add index.html to xfusion branch"
# Expected: [xfusion <hash>] Add index.html to xfusion branch

# STEP 9: Push xfusion to origin BEFORE merging
git push origin xfusion
# Expected: * [new branch] xfusion -> xfusion

# STEP 10: Switch back to master
git checkout master

# STEP 11: Merge xfusion into master
git merge xfusion
# Expected: Fast-forward merge, index.html added to master

# STEP 12: Push master to origin
git push origin master
# Expected: master -> master updated on remote

# STEP 13: Final verification
git log --oneline --all --graph
# Expected: both master and xfusion point to same commit on local + origin

git branch -a
# Expected: master, xfusion, origin/master, origin/xfusion all visible
