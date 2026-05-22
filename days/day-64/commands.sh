#!/bin/bash
# Day 64 — Kubernetes Troubleshooting: Fix Flask Python App
# Challenge: KodeKloud 100 Days of DevOps — Phase 5
# Task: Fix python-deployment-datacenter — wrong port config
#       Flask default port = 5000, nodePort should = 32345

# ─────────────────────────────────────────
# STEP 1: Check deployment state
# ─────────────────────────────────────────
kubectl get deployment python-deployment-datacenter
kubectl describe deployment python-deployment-datacenter | grep -i image

# ─────────────────────────────────────────
# STEP 2: Check pod state
# ─────────────────────────────────────────
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# ─────────────────────────────────────────
# STEP 3: Check service config
# ─────────────────────────────────────────
kubectl get svc
kubectl describe svc <service-name>
# Look for: targetPort (should be 5000) and nodePort (should be 32345)

# ─────────────────────────────────────────
# STEP 4: Fix deployment if needed
# (wrong image or wrong containerPort)
# ─────────────────────────────────────────
kubectl edit deployment python-deployment-datacenter
# Fix containerPort to 5000 if wrong

# ─────────────────────────────────────────
# STEP 5: Fix service ports
# ─────────────────────────────────────────
kubectl edit svc <service-name>
# Set:
#   targetPort: 5000   (Flask default port)
#   nodePort: 32345    (required)

# ─────────────────────────────────────────
# STEP 6: Verify fix
# ─────────────────────────────────────────
kubectl get pods        # Running ✅
kubectl get svc         # 5000:32345/TCP ✅
curl http://localhost:32345
