#!/bin/bash
# Day 49 — Kubernetes Deployment: nginx
# Challenge: KodeKloud 100 Days of DevOps — Phase 4
# Task: Create nginx Deployment with nginx:latest image

# ─────────────────────────────────────────
# From Jump Host (kubectl pre-configured)
# ─────────────────────────────────────────

# STEP 1: Verify cluster
kubectl get nodes

# STEP 2A: Imperative (fastest)
kubectl create deployment nginx --image=nginx:latest

# STEP 2B: Declarative YAML (preferred — version-controllable)
cat << 'EOF' > nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:latest
EOF

kubectl apply -f nginx-deployment.yaml

# STEP 3: Verify Deployment
kubectl get deployment nginx
# Expected:
# NAME    READY   UP-TO-DATE   AVAILABLE   AGE
# nginx   1/1     1            1           Xs

# STEP 4: Verify Pod was created
kubectl get pods -l app=nginx
# Expected: nginx-xxxxx-xxxxx Running

# STEP 5: Inspect full details
kubectl describe deployment nginx

# ─────────────────────────────────────────
# USEFUL DEPLOYMENT OPERATIONS
# ─────────────────────────────────────────
# Scale up
# kubectl scale deployment nginx --replicas=3

# Update image (triggers rolling update)
# kubectl set image deployment/nginx nginx=nginx:1.25

# Watch rollout status
# kubectl rollout status deployment/nginx

# Rollback
# kubectl rollout undo deployment/nginx
