#!/bin/bash
# Day 45 — Debug & Fix Broken Dockerfile
# Challenge: KodeKloud 100 Days of DevOps — Phase 3 Finale
# Task: Find and fix errors in /opt/docker/Dockerfile on App Server 2

# ─────────────────────────────────────────
# SSH into App Server 2
# ssh steve@stapp02    (Password: Am3ric@)
# ─────────────────────────────────────────

# STEP 1: Read the existing Dockerfile
cat /opt/docker/Dockerfile

# STEP 2: Check build context files
ls -la /opt/docker/

# STEP 3: Attempt build to see the exact error
cd /opt/docker
sudo docker build -t test-build . 2>&1
# Read the output carefully — Docker identifies the exact failing step

# STEP 4: Fix the Dockerfile
# Only fix broken instructions — do NOT change:
# - Base image (FROM line)
# - Valid working instructions
# - Data files (index.html etc.)
sudo vi /opt/docker/Dockerfile

# STEP 5: Rebuild to confirm fix
sudo docker build -t fixed-image .
# Expected: Successfully built ✅

# STEP 6: Verify image exists
sudo docker images | grep fixed-image

# ─────────────────────────────────────────
# COMMON FIXES REFERENCE
# ─────────────────────────────────────────
# Wrong case:    form → FROM, copY → COPY, rUn → RUN
# Typo:          apche2 → apache2, ngnix → nginx
# Missing update: RUN apt-get install → RUN apt-get update && apt-get install
# Wrong CMD:     CMD apache2ctl start → CMD ["apache2ctl", "-D", "FOREGROUND"]
# Missing file:  Check ls -la /opt/docker/ for available files
