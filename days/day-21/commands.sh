#!/bin/bash
# Day 21 — Git Bare Repository Setup on Storage Server
# Challenge: KodeKloud 100 Days of DevOps — Phase 2
# Task: Install git, create bare repo /opt/official.git on ststor01

# ─────────────────────────────────────────
# SSH into Storage Server
# ssh natasha@ststor01    (Password: Bl@kW)
# ─────────────────────────────────────────

# STEP 1: Install git
sudo yum install -y git

# Verify
git --version
# Expected: git version 2.x.x

# STEP 2: Create bare repository at /opt/official.git
sudo git init --bare /opt/official.git
# Expected: Initialized empty Git repository in /opt/official.git/

# STEP 3: Verify structure
ls -la /opt/official.git/
# Expected: HEAD, branches/, config, description, hooks/, info/, objects/, refs/

# STEP 4: Confirm bare = true
cat /opt/official.git/config
# Expected:
# [core]
#     repositoryformatversion = 0
#     filemode = true
#     bare = true

# ─────────────────────────────────────────
# OPTIONAL: Test clone from jump host
# ─────────────────────────────────────────
# git clone natasha@ststor01:/opt/official.git /tmp/test-clone
# Expected: warning about empty repo — that's correct ✅

# ─────────────────────────────────────────
# USEFUL: Work with bare repo remotely
# ─────────────────────────────────────────
# View log (once commits exist)
# git --git-dir=/opt/official.git log --oneline

# List branches
# git --git-dir=/opt/official.git branch -a
