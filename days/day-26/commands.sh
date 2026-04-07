#!/bin/bash
# Day 26 — Git Remote Management: Add Remote & Push to It
# Challenge: KodeKloud 100 Days of DevOps — Phase 2
# Task: Add dev_news remote, commit index.html, push master to dev_news

# ─────────────────────────────────────────
# SSH into Storage Server
# ssh natasha@ststor01    (Password: Bl@kW)
# ─────────────────────────────────────────

# STEP 1: Navigate to the repository
cd /usr/src/kodekloudrepos/news

# STEP 2: Check existing remotes (baseline)
git remote -v
# Expected: origin -> /opt/news.git

# STEP 3: Add the new remote
git remote add dev_news /opt/xfusioncorp_news.git

# STEP 4: Verify both remotes are configured
git remote -v
# Expected:
# dev_news  /opt/xfusioncorp_news.git (fetch)
# dev_news  /opt/xfusioncorp_news.git (push)
# origin    /opt/news.git (fetch)
# origin    /opt/news.git (push)

# STEP 5: Ensure on master
git checkout master
git status

# STEP 6: Copy index.html into the repo
cp /tmp/index.html .

# STEP 7: Verify untracked
git status
# Expected: index.html listed as untracked

# STEP 8: Stage and commit
git add index.html
git commit -m "Add index.html to master branch"

# STEP 9: Push master to dev_news remote (NOT origin)
git push dev_news master
# Expected: * [new branch] master -> master on /opt/xfusioncorp_news.git

# STEP 10: Verify
git remote -v
git log --oneline -3
