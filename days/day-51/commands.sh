#!/bin/bash
# Day 51 — Kubernetes Rolling Update: nginx-deployment to nginx:1.17
# Challenge: KodeKloud 100 Days of DevOps — Phase 4
# Task: Rolling update nginx-deployment to nginx:1.17, verify all pods healthy

# ─────────────────────────────────────────
# From Jump Host (kubectl pre-configured)
# ─────────────────────────────────────────

# STEP 1: Inspect current deployment
kubectl get deployment nginx-deployment
kubectl describe deployment nginx-deployment | grep -i image
# Note the container name — needed for set image command

# STEP 2: Check current pods
kubectl get pods

# STEP 3: Execute rolling update
# Replace 'nginx-container' with actual container name from describe
kubectl set image deployment/nginx-deployment \
  nginx-container=nginx:1.17
# Expected: deployment.apps/nginx-deployment image updated

# STEP 4: Watch rollout in real time
kubectl rollout status deployment/nginx-deployment
# Expected: deployment "nginx-deployment" successfully rolled out

# STEP 5: Verify all pods running
kubectl get pods
# Expected: all pods Running, no Terminating/Pending

# STEP 6: Confirm new image is deployed
kubectl describe deployment nginx-deployment | grep Image
# Expected: Image: nginx:1.17

# STEP 7: Check rollout history
kubectl rollout history deployment/nginx-deployment

# ─────────────────────────────────────────
# ROLLBACK IF NEEDED
# ─────────────────────────────────────────
# kubectl rollout undo deployment/nginx-deployment
# kubectl rollout status deployment/nginx-deployment

# ─────────────────────────────────────────
# BEST PRACTICE: Annotate the rollout
# ─────────────────────────────────────────
# kubectl annotate deployment nginx-deployment \
#   kubernetes.io/change-cause="Update to nginx:1.17"
