#!/bin/bash
# Day 59 — Kubernetes Troubleshooting: Fix Broken Redis Deployment
# Challenge: KodeKloud 100 Days of DevOps — Phase 4
# Task: Diagnose and fix redis-deployment — pods not running

# ─────────────────────────────────────────
# STEP 1: Deployment level check
# ─────────────────────────────────────────
kubectl get deployment redis-deployment
# Check READY column — 0/N means pods failing

kubectl describe deployment redis-deployment
# Check Conditions and Events

# ─────────────────────────────────────────
# STEP 2: Pod level check
# ─────────────────────────────────────────
kubectl get pods
# Note pod name(s) and STATUS:
# ImagePullBackOff → wrong image name/tag
# CrashLoopBackOff → container starts then crashes
# Pending          → scheduling issue
# CreateContainerConfigError → bad config reference

# ─────────────────────────────────────────
# STEP 3: Pod Events — ROOT CAUSE HERE
# ─────────────────────────────────────────
kubectl describe pod <pod-name>
# READ THE EVENTS SECTION AT THE BOTTOM
# This tells you exactly what failed and why

# ─────────────────────────────────────────
# STEP 4: Container logs (if container started)
# ─────────────────────────────────────────
kubectl logs <pod-name>
kubectl logs <pod-name> --previous    # After crash/restart

# ─────────────────────────────────────────
# STEP 5: Fix the deployment
# ─────────────────────────────────────────
kubectl edit deployment redis-deployment
# Fix the identified issue:
# - Wrong image: change image tag
# - Bad command: fix command/args
# - Config error: fix env/volume references
# Save and exit — rolling update begins automatically

# ─────────────────────────────────────────
# STEP 6: Monitor and verify
# ─────────────────────────────────────────
kubectl rollout status deployment/redis-deployment
# Expected: deployment "redis-deployment" successfully rolled out

kubectl get pods
# Expected: all pods Running ✅

kubectl describe deployment redis-deployment | grep Image
# Confirm correct image is running
