#!/bin/bash
# Day 33 — Git Merge Conflict Resolution
# Challenge: KodeKloud 100 Days of DevOps — Phase 3
# Task: Resolve push rejection, fix conflict in story-index.txt,
#       fix Mooose typo, ensure 4 stories present, push to origin

# ─────────────────────────────────────────
# SSH as max
# ssh max@ststor01    (Password: Max_pass123)
# ─────────────────────────────────────────

# STEP 1: Navigate to repository
cd /home/max/story-blog

# STEP 2: Check current state
git status
git log --oneline

# STEP 3: Attempt push — see the rejection error
git push origin master
# Expected error: rejected — remote contains work you don't have

# STEP 4: Pull from origin
git pull origin master
# If conflict: CONFLICT in story-index.txt
# Automatic merge failed; fix conflicts and then commit the result.

# STEP 5: Check conflicted file
cat story-index.txt
# Look for <<<<<<, =======, >>>>>>> markers

# STEP 6: Resolve conflict in vi
vi story-index.txt
# - Remove ALL conflict markers (<<<<<<<, =======, >>>>>>>)
# - Keep all 4 story titles from both sides
# - Fix Mooose → Mouse while you're in the file
# - Save and exit (:wq)

# STEP 7: Verify no conflict markers remain
grep -n "<<<<<<\|=======\|>>>>>>>" story-index.txt
# Expected: no output (all markers removed)

# STEP 8: Verify typo is fixed
grep -i "mooose" story-index.txt   # Expected: empty
grep -i "mouse" story-index.txt    # Expected: The Lion and the Mouse

# STEP 9: Verify all 4 stories are present
cat story-index.txt
# Expected: 4 story titles

# STEP 10: Stage and commit
git add story-index.txt
git commit -m "Resolved merge conflict in story-index.txt, fix Mooose typo"

# STEP 11: Push to origin
git push origin master
# Expected: master -> master ✅

# ─────────────────────────────────────────
# IF TYPO STILL EXISTS AFTER PULL
# ─────────────────────────────────────────
# sed -i 's/Mooose/Mouse/g' story-index.txt
# git add story-index.txt
# git commit -m "Fix typo: Mooose -> Mouse in story-index.txt"
# git push origin master
