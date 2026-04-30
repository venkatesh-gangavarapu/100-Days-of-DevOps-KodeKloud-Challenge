#!/bin/bash
# Day 47 — Dockerize Python App: Build & Deploy
# Challenge: KodeKloud 100 Days of DevOps — Phase 4
# Task: Create Dockerfile, build nautilus/python-app, run pythonapp_nautilus

# ─────────────────────────────────────────
# SSH into App Server 2
# ssh steve@stapp02    (Password: Am3ric@)
# ─────────────────────────────────────────

# STEP 1: Inspect source files
ls -la /python_app/src/
cat /python_app/src/requirements.txt

# STEP 2: Create Dockerfile at /python_app/Dockerfile
sudo tee /python_app/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ .

EXPOSE 8085

CMD ["python", "server.py"]
EOF

# STEP 3: Verify Dockerfile
cat /python_app/Dockerfile

# STEP 4: Build the image
cd /python_app
sudo docker build -t nautilus/python-app .
# Expected: Successfully built + Successfully tagged nautilus/python-app:latest

# STEP 5: Verify image exists
sudo docker images | grep nautilus
# Expected: nautilus/python-app   latest

# STEP 6: Run container with port mapping
sudo docker run -d \
  --name pythonapp_nautilus \
  -p 8097:8085 \
  nautilus/python-app
# host:8097 → container:8085

# STEP 7: Verify container is running
sudo docker ps | grep pythonapp_nautilus
# Expected: 0.0.0.0:8097->8085/tcp

# STEP 8: Test the app
curl http://localhost:8097/
# Expected: Python app response ✅

# ─────────────────────────────────────────
# DEBUG IF NEEDED
# ─────────────────────────────────────────
# sudo docker logs pythonapp_nautilus
# sudo docker exec -it pythonapp_nautilus /bin/bash
