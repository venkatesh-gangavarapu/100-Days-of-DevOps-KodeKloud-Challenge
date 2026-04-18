#!/bin/bash
# Day 36 — Deploy nginx Container with Alpine Tag
# Challenge: KodeKloud 100 Days of DevOps — Phase 3
# Task: Run nginx:alpine container named nginx_1 on App Server 1

# ─────────────────────────────────────────
# SSH into App Server 1
# ssh tony@stapp01    (Password: Ir0nM@n)
# ─────────────────────────────────────────

# STEP 1: Pull the image
sudo docker pull nginx:alpine

# STEP 2: Run container in detached mode with name
sudo docker run -d --name nginx_1 nginx:alpine
# -d          → detached (background)
# --name      → assign name nginx_1
# nginx:alpine → image with alpine tag

# STEP 3: Verify container is running
sudo docker ps
# Expected: nginx_1 with STATUS "Up X seconds"

# STEP 4: Detailed state check
sudo docker inspect nginx_1 --format '{{.State.Status}}'
# Expected: running

# STEP 5: Check container logs
sudo docker logs nginx_1

# ─────────────────────────────────────────
# USEFUL DOCKER REFERENCE COMMANDS
# ─────────────────────────────────────────
# Shell into the container
# sudo docker exec -it nginx_1 sh

# Stop the container
# sudo docker stop nginx_1

# Remove the container
# sudo docker rm nginx_1

# List all images
# docker images | grep nginx
