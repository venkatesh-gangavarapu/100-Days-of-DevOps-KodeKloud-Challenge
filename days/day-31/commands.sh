#!/bin/bash
# Day 31 — Git Stash: Restore stash@{1} and Commit
# Challenge: KodeKloud 100 Days of DevOps — Phase 3
# Task: Apply stash@{1} from /usr/src/kodekloudrepos/official, commit, push

# ─────────────────────────────────────────
# SSH into Storage Server
# ssh natasha@ststor01    (Password: Bl@kW)
# ─────────────────────────────────────────

# STEP 1: Navigate to repository
cd /usr/src/kodekloudrepos/official

# STEP 2: List all stashes — confirm stash@{1} exists
git stash list
# Expected:
# stash@{0}: WIP on master: <hash> <message>
# stash@{1}: WIP on master: <hash> <message>  ← target

# STEP 3: Preview stash@{1} contents before applying
git stash show stash@{1}          # summary
git stash show -p stash@{1}       # full diff

# STEP 4: Apply stash@{1} (keeps stash in list as backup)
git stash apply stash@{1}
# Expected: Changes restored to working tree as unstaged modifications

# STEP 5: Verify changes are present
git status
# Expected: modified/added files from the stash

# STEP 6: Stage all changes
git add .

# STEP 7: Commit
git commit -m "Restore stash@{1} changes"

# STEP 8: Push to origin
git push origin master

# STEP 9: Verify
git log --oneline -3
git stash list            # stash@{1} still present (apply doesn't remove)

# ─────────────────────────────────────────
# STASH QUICK REFERENCE
# ─────────────────────────────────────────
# git stash apply stash@{1}  → restore, stash stays in list
# git stash pop stash@{1}    → restore, stash removed from list
# git stash drop stash@{1}   → delete stash without applying
# git stash clear            → delete ALL stashes
