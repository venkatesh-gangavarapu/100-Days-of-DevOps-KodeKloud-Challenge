#!/bin/bash
# Day 63 — Multi-Tier Kubernetes Stack: Iron Gallery + Iron DB
# Challenge: KodeKloud 100 Days of DevOps — Phase 5
# Task: Full app stack in dedicated namespace — gallery + db + services

# ─────────────────────────────────────────
# STEP 1: Apply entire stack from single file
# ─────────────────────────────────────────
kubectl apply -f iron-stack.yaml
# Expected:
# namespace/iron-namespace-devops created
# deployment.apps/iron-gallery-deployment-devops created
# deployment.apps/iron-db-deployment-devops created
# service/iron-db-service-devops created
# service/iron-gallery-service-devops created

# ─────────────────────────────────────────
# STEP 2: Verify namespace
# ─────────────────────────────────────────
kubectl get namespace iron-namespace-devops

# ─────────────────────────────────────────
# STEP 3: Verify all resources in namespace
# ─────────────────────────────────────────
kubectl get all -n iron-namespace-devops

# ─────────────────────────────────────────
# STEP 4: Verify deployments
# ─────────────────────────────────────────
kubectl get deployment -n iron-namespace-devops
# Expected:
# iron-gallery-deployment-devops   1/1   Running
# iron-db-deployment-devops        1/1   Running

# ─────────────────────────────────────────
# STEP 5: Verify pods
# ─────────────────────────────────────────
kubectl get pods -n iron-namespace-devops
# Expected: both pods Running

# ─────────────────────────────────────────
# STEP 6: Verify services
# ─────────────────────────────────────────
kubectl get svc -n iron-namespace-devops
# Expected:
# iron-db-service-devops       ClusterIP   <ip>   3306/TCP
# iron-gallery-service-devops  NodePort    <ip>   80:32678/TCP

# ─────────────────────────────────────────
# STEP 7: Test gallery app
# ─────────────────────────────────────────
curl http://localhost:32678
# Expected: Iron Gallery installation/app page ✅

# ─────────────────────────────────────────
# STEP 8: Verify endpoints
# ─────────────────────────────────────────
kubectl get endpoints -n iron-namespace-devops
# Both services should have pod IPs listed
