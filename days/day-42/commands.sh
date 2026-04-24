#!/bin/bash
# Day 42 — Create Custom Docker Bridge Network
# Challenge: KodeKloud 100 Days of DevOps — Phase 3
# Task: Create 'ecommerce' bridge network with subnet/ip-range 172.28.0.0/24

# ─────────────────────────────────────────
# SSH into App Server 2
# ssh steve@stapp02    (Password: Am3ric@)
# ─────────────────────────────────────────

# STEP 1: Create the custom bridge network
sudo docker network create \
  --driver bridge \
  --subnet 172.28.0.0/24 \
  --ip-range 172.28.0.0/24 \
  ecommerce
# Expected: network ID hash

# STEP 2: Verify network created with correct config
sudo docker network inspect ecommerce
# Confirm: Name=ecommerce, Driver=bridge,
#          Subnet=172.28.0.0/24, IPRange=172.28.0.0/24

# STEP 3: List all networks
sudo docker network ls
# Expected: ecommerce listed with bridge driver

# ─────────────────────────────────────────
# BONUS: Test the network with containers
# ─────────────────────────────────────────
# sudo docker run -d --network ecommerce --name web nginx:alpine
# sudo docker run -d --network ecommerce --name db alpine sleep 3600
# sudo docker exec db ping web   # DNS name resolution ✅
