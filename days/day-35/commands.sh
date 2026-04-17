#!/bin/bash
# Day 35 — Docker CE & Docker Compose Installation
# Challenge: KodeKloud 100 Days of DevOps — Phase 3
# Task: Install docker-ce and docker compose on App Server 3, start service

# ─────────────────────────────────────────
# SSH into App Server 3
# ssh banner@stapp03    (Password: BigGr33n)
# ─────────────────────────────────────────

# STEP 1: Install dependencies
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# STEP 2: Add Docker's official repository
sudo yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

# STEP 3: Install Docker CE + Compose plugin
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# STEP 4: Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# STEP 5: Verify service is active and enabled
sudo systemctl status docker
sudo systemctl is-active docker    # Expected: active
sudo systemctl is-enabled docker   # Expected: enabled

# STEP 6: Verify versions
docker --version
# Expected: Docker version 24.x.x

docker compose version
# Expected: Docker Compose version v2.x.x

# STEP 7: End-to-end test
sudo docker run hello-world
# Expected: Hello from Docker! ✅

# ─────────────────────────────────────────
# OPTIONAL: Run docker without sudo
# ─────────────────────────────────────────
sudo usermod -aG docker banner
newgrp docker

# ─────────────────────────────────────────
# USEFUL VERIFICATION COMMANDS
# ─────────────────────────────────────────
sudo docker info          # Full system info
docker images             # List local images
docker ps -a              # All containers including stopped
