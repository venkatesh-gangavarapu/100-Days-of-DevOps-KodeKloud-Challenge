#!/bin/bash
# Day 38 — Docker Image Pull & Re-tag
# Challenge: KodeKloud 100 Days of DevOps — Phase 3
# Task: Pull busybox:musl, re-tag as busybox:blog on App Server 2

# ─────────────────────────────────────────
# SSH into App Server 2
# ssh steve@stapp02    (Password: Am3ric@)
# ─────────────────────────────────────────

# STEP 1: Pull the busybox:musl image
sudo docker pull busybox:musl
# Expected: Status: Downloaded newer image for busybox:musl

# STEP 2: Re-tag as busybox:blog
sudo docker tag busybox:musl busybox:blog
# No output on success — that's normal

# STEP 3: Verify both tags exist with same Image ID
sudo docker images | grep busybox
# Expected:
# busybox   musl   abc123def456   X days ago   1.41MB
# busybox   blog   abc123def456   X days ago   1.41MB
# Same Image ID = same underlying layers, no duplication

# STEP 4: Confirm IDs match
sudo docker image inspect busybox:musl --format '{{.Id}}'
sudo docker image inspect busybox:blog --format '{{.Id}}'
# Both must return the same hash ✅
