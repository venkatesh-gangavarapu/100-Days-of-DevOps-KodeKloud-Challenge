#!/bin/bash
# Day 43 — Docker Port Mapping: nginx Container on App Server 2
# Challenge: KodeKloud 100 Days of DevOps — Phase 3
# Task: Pull nginx:alpine, run container 'beta', map host:3000 → container:80

# ─────────────────────────────────────────
# SSH into App Server 2
# ssh steve@stapp02    (Password: Am3ric@)
# ─────────────────────────────────────────

# STEP 1: Pull nginx:alpine image
sudo docker pull nginx:alpine

# STEP 2: Run container with port mapping
sudo docker run -d --name beta -p 3000:80 nginx:alpine
# -d         → detached (background)
# --name beta → container name
# -p 3000:80  → host port 3000 → container port 80

# STEP 3: Verify container is running with correct port
sudo docker ps | grep beta
# Expected PORTS column: 0.0.0.0:3000->80/tcp

# STEP 4: Verify port mapping explicitly
sudo docker port beta
# Expected: 80/tcp -> 0.0.0.0:3000

# STEP 5: Test nginx responds on host port 3000
curl http://localhost:3000
# Expected: nginx Welcome page HTML ✅
