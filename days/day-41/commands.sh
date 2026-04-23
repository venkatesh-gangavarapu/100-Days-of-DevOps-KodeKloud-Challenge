#!/bin/bash
# Day 41 — Write a Dockerfile: Apache on Ubuntu 24.04 with Port 6400
# Challenge: KodeKloud 100 Days of DevOps — Phase 3
# Task: Create /opt/docker/Dockerfile on App Server 3

# ─────────────────────────────────────────
# SSH into App Server 3
# ssh banner@stapp03    (Password: BigGr33n)
# ─────────────────────────────────────────

# STEP 1: Create directory
sudo mkdir -p /opt/docker

# STEP 2: Write the Dockerfile (capital D)
sudo tee /opt/docker/Dockerfile << 'EOF'
FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y apache2 && \
    sed -i 's/^Listen 80/Listen 6400/' /etc/apache2/ports.conf && \
    sed -i 's/<VirtualHost \*:80>/<VirtualHost *:6400>/' \
      /etc/apache2/sites-enabled/000-default.conf

EXPOSE 6400

CMD ["apache2ctl", "-D", "FOREGROUND"]
EOF

# STEP 3: Verify Dockerfile content
cat /opt/docker/Dockerfile

# STEP 4: Build the image
cd /opt/docker
sudo docker build -t apache-custom:6400 .
# Expected: Successfully built + Successfully tagged

# STEP 5: Run a test container
sudo docker run -d -p 6400:6400 --name apache-test apache-custom:6400

# STEP 6: Verify container is running
sudo docker ps | grep apache-test

# STEP 7: Test Apache responds on port 6400
curl http://localhost:6400
# Expected: Apache2 Ubuntu Default Page ✅

# STEP 8: Inspect image layers
sudo docker history apache-custom:6400
