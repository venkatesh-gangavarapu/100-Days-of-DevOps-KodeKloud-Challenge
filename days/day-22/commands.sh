#!/bin/bash
# Day 22 — Clone Git Repository to Working Directory
# Challenge: KodeKloud 100 Days of DevOps — Phase 2
# Task: Clone /opt/beta.git to /usr/src/kodekloudrepos as natasha
# Constraint: No permission changes, no modifications to existing dirs

# ─────────────────────────────────────────
# SSH as natasha (task requires this user)
# ssh natasha@ststor01    (Password: Bl@kW)
# ─────────────────────────────────────────

# STEP 1: Confirm running as natasha
whoami
# Expected: natasha

# STEP 2: Verify source repo exists
ls -la /opt/beta.git
# Expected: bare repository structure

# STEP 3: Verify destination directory exists (DO NOT modify it)
ls -la /usr/src/kodekloudrepos
# Expected: directory exists

# STEP 4: Clone the repository
git clone /opt/beta.git /usr/src/kodekloudrepos/beta
# Expected: Cloning into '/usr/src/kodekloudrepos/beta'... done.
# Note: "empty repository" warning is expected if no commits exist — still valid

# STEP 5: Verify clone was successful
ls -la /usr/src/kodekloudrepos/beta/
# Expected: .git/ directory + any working files

# STEP 6: Verify git status and remote
cd /usr/src/kodekloudrepos/beta/
git status
# Expected: On branch main, nothing to commit

git remote -v
# Expected:
# origin  /opt/beta.git (fetch)
# origin  /opt/beta.git (push)

git log --oneline
# Expected: commit history or empty if no commits
