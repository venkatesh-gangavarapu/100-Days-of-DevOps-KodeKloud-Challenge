#!/bin/bash
# Day 39 — Create Docker Image from Running Container
# Challenge: KodeKloud 100 Days of DevOps — Phase 3
# Task: Commit ubuntu_latest container as beta:xfusion image on App Server 2

# ─────────────────────────────────────────
# SSH into App Server 2
# ssh steve@stapp02    (Password: Am3ric@)
# ─────────────────────────────────────────

# STEP 1: Verify container is running
sudo docker ps | grep ubuntu_latest
# Expected: ubuntu_latest STATUS "Up"

# STEP 2: Commit container as new image
sudo docker commit ubuntu_latest beta:xfusion
# Expected: sha256:<image_hash>

# STEP 3: Verify image was created
sudo docker images | grep beta
# Expected:
# beta   xfusion   <hash>   X seconds ago   77.9MB

# STEP 4: Inspect the image
sudo docker image inspect beta:xfusion

# ─────────────────────────────────────────
# BONUS: Check what changed in container
# ─────────────────────────────────────────
sudo docker diff ubuntu_latest
# A = Added, C = Changed, D = Deleted

# View layer history of new image
sudo docker history beta:xfusion

# Run a container from the committed image
# sudo docker run -it beta:xfusion /bin/bash
