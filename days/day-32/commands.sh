#!/bin/bash
# Day 32 — Git Rebase: Feature Branch onto Master
# Challenge: KodeKloud 100 Days of DevOps — Phase 3
# Task: Rebase feature onto master — no merge commit, no data loss, push both

# ─────────────────────────────────────────
# SSH into Storage Server
# ssh natasha@ststor01    (Password: Bl@kW)
# ─────────────────────────────────────────

# STEP 1: Navigate to repository
cd /usr/src/kodekloudrepos/beta

# STEP 2: Inspect current state of both branches
git log --oneline --all --graph
# See where master and feature diverge

# STEP 3: Switch to feature branch
git checkout feature

# STEP 4: Rebase feature onto master
# This replays feature commits on top of master's latest commit
git rebase master
# Expected: Successfully rebased and updated refs/heads/feature.

# STEP 5: Verify clean linear history (no merge commit)
git log --oneline --all --graph
# Expected:
# * <new_hash> (HEAD -> feature) feature commit 2
# * <new_hash> feature commit 1
# * <hash> (master, origin/master) latest master commit
# * <hash> initial commit

# STEP 6: Force push feature branch
# Required because rebase rewrote commit hashes
git push -f origin feature
# Expected: (forced update) message

# STEP 7: Push master
git push origin master

# ─────────────────────────────────────────
# IF CONFLICTS OCCUR DURING REBASE:
# ─────────────────────────────────────────
# git status                      → identify conflicting files
# vi <file>                       → resolve conflicts manually
# git add <file>                  → stage resolved file
# git rebase --continue           → continue replaying next commit
# git rebase --abort              → cancel entire rebase safely

# ─────────────────────────────────────────
# KEY RULES:
# - Always rebase FROM feature branch, not from master
# - Force push required after rebase (hashes changed)
# - Never rebase a shared public branch
# ─────────────────────────────────────────
