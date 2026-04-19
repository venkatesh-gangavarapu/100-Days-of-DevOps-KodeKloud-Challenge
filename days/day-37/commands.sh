#!/bin/bash
# Day 37 — Copy Encrypted File from Host to Docker Container
# Challenge: KodeKloud 100 Days of DevOps — Phase 3
# Task: Copy /tmp/nautilus.txt.gpg into ubuntu_latest container at /opt/
#       File must not be modified during operation

# ─────────────────────────────────────────
# SSH into App Server 2
# ssh steve@stapp02    (Password: Am3ric@)
# ─────────────────────────────────────────

# STEP 1: Verify source file exists on host
ls -lh /tmp/nautilus.txt.gpg

# STEP 2: Verify container is running
sudo docker ps | grep ubuntu_latest
# Expected: ubuntu_latest with STATUS "Up"

# STEP 3: Copy file from host to container
sudo docker cp /tmp/nautilus.txt.gpg ubuntu_latest:/opt/
# No output on success — that's normal

# STEP 4: Verify file is inside container
sudo docker exec ubuntu_latest ls -lh /opt/nautilus.txt.gpg

# STEP 5: Verify file integrity — checksums must match
md5sum /tmp/nautilus.txt.gpg                                  # host
sudo docker exec ubuntu_latest md5sum /opt/nautilus.txt.gpg  # container
# Both hashes must be IDENTICAL ✅

# ─────────────────────────────────────────
# DOCKER CP REFERENCE
# ─────────────────────────────────────────
# Host → Container:
# docker cp /host/file container_name:/dest/path/

# Container → Host:
# docker cp container_name:/container/file /host/dest/

# Works on stopped containers too
# docker cp stopped_container:/path/file.txt /host/dest/
