#!/bin/bash
# Day 30 — Git Reset Hard: Clean Commit History to 2 Commits
# Challenge: KodeKloud 100 Days of DevOps — Phase 2 Finale
# Task: Reset to "add data.txt file" commit — only 2 commits in history
#       Force push to origin

# ─────────────────────────────────────────
# SSH into Storage Server
# ssh natasha@ststor01    (Password: Bl@kW)
# ─────────────────────────────────────────

# STEP 1: Navigate to repository
cd /usr/src/kodekloudrepos/media

# STEP 2: View full commit history — identify target
git log --oneline
# Look for: <hash> add data.txt file
# Everything after this commit will be removed

# OPTIONAL: Search by message
git log --oneline --grep="add data.txt"

# STEP 3: Hard reset to "add data.txt file" commit
git reset --hard <hash>
# Replace <hash> with actual commit hash
# Expected: HEAD is now at <hash> add data.txt file

# STEP 4: Verify exactly 2 commits remain
git log --oneline
# Expected:
# <hash> (HEAD -> master) add data.txt file
# <hash> initial commit

# STEP 5: Confirm working tree is clean
git status
# Expected: nothing to commit, working tree clean

# STEP 6: Force push to origin (required after history rewrite)
git push -f origin master
# Expected: + <old>..<new> master -> master (forced update)

# STEP 7: Verify remote matches local
git log --oneline origin/master
# Expected: same 2 commits only

# ─────────────────────────────────────────
# KEY DISTINCTION (Days 27 vs 30)
# ─────────────────────────────────────────
# Day 27: git revert   → adds new undo commit, preserves history
#                        safe for shared production branches
# Day 30: git reset    → removes commits from history permanently
#         --hard         only appropriate for test/cleanup repos
#         force push     required after history rewrite
