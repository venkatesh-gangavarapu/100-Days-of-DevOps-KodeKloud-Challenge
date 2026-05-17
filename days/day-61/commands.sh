#!/bin/bash
# Day 61 — Kubernetes Init Containers
# Challenge: KodeKloud 100 Days of DevOps — Phase 5
# Task: Deployment with init container writing to shared emptyDir,
#       main container reads it in a loop

# STEP 1: Apply the Deployment
kubectl apply -f ic-deploy-xfusion.yaml
# Expected: deployment.apps/ic-deploy-xfusion created

# STEP 2: Watch pod startup — init runs first
kubectl get pods -w
# Expected sequence:
# ic-deploy-xfusion-xxx   0/1   Init:0/1    ← init running
# ic-deploy-xfusion-xxx   0/1   PodInitializing ← init done
# ic-deploy-xfusion-xxx   1/1   Running     ← main container up ✅

# STEP 3: Verify Deployment
kubectl get deployment ic-deploy-xfusion
# Expected: READY 1/1

# STEP 4: Verify init container ran successfully
kubectl describe pod <pod-name> | grep -A 5 "Init Containers"

# STEP 5: Check main container output
kubectl logs <pod-name> -c ic-main-xfusion
# Expected: Init Done - Welcome to xFusionCorp Industries
# (repeated every 5 seconds)

# STEP 6: Follow live output
kubectl logs <pod-name> -c ic-main-xfusion -f
# Expected: "Init Done - Welcome to xFusionCorp Industries" printing every 5s ✅
