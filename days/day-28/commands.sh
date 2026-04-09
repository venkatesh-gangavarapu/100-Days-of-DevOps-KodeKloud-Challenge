#!/bin/bash
# Day 28 — Git Cherry-Pick: Apply Specific Commit from Feature to Master
# Challenge: KodeKloud 100 Days of DevOps — Phase 2
# Task: Cherry-pick "Update info.txt" commit from feature branch into master

# ─────────────────────────────────────────
# SSH into Storage Server
# ssh natasha@ststor01    (Password: Bl@kW)
# ─────────────────────────────────────────

# STEP 1: Navigate to repository
cd /usr/src/kodekloudrepos/demo

# STEP 2: Check available branches
git branch -a

# STEP 3: Find the hash of "Update info.txt" on feature branch
git log feature --oneline
# Look for: <hash> Update info.txt

# ALTERNATIVE: Search by commit message directly
git log --all --oneline --grep="Update info.txt"

# STEP 4: Switch to master
git checkout master

# STEP 5: Cherry-pick the specific commit (replace with actual hash)
git cherry-pick <hash>
# Expected: [master <new_hash>] Update info.txt

# STEP 6: Verify commit landed on master
git log --oneline
# Expected: "Update info.txt" at HEAD of master

# STEP 7: Verify feature branch is untouched
git log feature --oneline
# Feature still has all original commits

# STEP 8: Push master to origin
git push origin master

# ─────────────────────────────────────────
# IF CONFLICTS OCCUR:
# ─────────────────────────────────────────
# git status                    # See conflicting files
# vi <conflicting-file>         # Resolve manually
# git add <conflicting-file>    # Stage resolved file
# git cherry-pick --continue    # Complete the cherry-pick
# git cherry-pick --abort       # Or abort entirely
