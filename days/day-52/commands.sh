#!/bin/bash
# Day 52 — Kubernetes Rollback: nginx-deployment to Previous Revision
# Challenge: KodeKloud 100 Days of DevOps — Phase 4
# Task: Bug in latest deployment — rollback nginx-deployment to previous revision

# ─────────────────────────────────────────
# From Jump Host (kubectl pre-configured)
# ─────────────────────────────────────────

# STEP 1: Check current deployment state
kubectl get deployment nginx-deployment
kubectl describe deployment nginx-deployment | grep Image
# Note the current (buggy) image

# STEP 2: Review rollout history
kubectl rollout history deployment/nginx-deployment
# Shows all revisions — rollback targets the previous one

# STEP 3: Execute rollback to previous revision
kubectl rollout undo deployment/nginx-deployment
# Expected: deployment.apps/nginx-deployment rolled back

# STEP 4: Watch rollback in real time
kubectl rollout status deployment/nginx-deployment
# Expected: deployment "nginx-deployment" successfully rolled out

# STEP 5: Verify all pods are healthy
kubectl get pods
# Expected: all pods Running

# STEP 6: Confirm previous image is restored
kubectl describe deployment nginx-deployment | grep Image

# STEP 7: Check updated history (new revision added)
kubectl rollout history deployment/nginx-deployment
# Rollback creates a new revision, not a decrement

# ─────────────────────────────────────────
# ROLLBACK TO SPECIFIC REVISION (if needed)
# ─────────────────────────────────────────
# kubectl rollout undo deployment/nginx-deployment --to-revision=1
