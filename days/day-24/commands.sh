#!/bin/bash
# Day 24 — Create Feature Branch from Master
# Challenge: KodeKloud 100 Days of DevOps — Phase 2
# Task: Create branch xfusioncorp_beta from master in /usr/src/kodekloudrepos/beta
# Constraint: No code changes — branch creation only

# ─────────────────────────────────────────
# SSH into Storage Server
# ssh natasha@ststor01    (Password: Bl@kW)
# ─────────────────────────────────────────

# STEP 1: Navigate to the repository
cd /usr/src/kodekloudrepos/beta

# STEP 2: Check current state
git status                    # Confirm clean working tree
git branch                    # See current branches

# STEP 3: Ensure on master (branch must be created FROM master)
git checkout master

# STEP 4: Create new branch from master and switch to it
git checkout -b xfusioncorp_beta
# Expected: Switched to a new branch 'xfusioncorp_beta'

# STEP 5: Verify branch exists and is active
git branch
# Expected:
#   master
# * xfusioncorp_beta    ← * = currently active

# STEP 6: Confirm no code changes were made
git status
# Expected: nothing to commit, working tree clean
