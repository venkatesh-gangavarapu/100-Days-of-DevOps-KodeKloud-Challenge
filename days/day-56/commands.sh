#!/bin/bash
# Day 56 — Kubernetes Deployment + NodePort Service
# Challenge: KodeKloud 100 Days of DevOps — Phase 4
# Task: 3-replica nginx Deployment + NodePort Service on port 30011

# STEP 1: Apply Deployment
kubectl apply -f nginx-deployment.yaml
# Expected: deployment.apps/nginx-deployment created

# STEP 2: Apply Service
kubectl apply -f nginx-service.yaml
# Expected: service/nginx-service created

# STEP 3: Verify Deployment (wait for 3/3)
kubectl get deployment nginx-deployment
# Expected: READY 3/3

# STEP 4: Verify all 3 Pods running
kubectl get pods -l app=nginx-deployment
# Expected: 3 pods Running

# STEP 5: Verify Service
kubectl get service nginx-service
# Expected: TYPE NodePort, PORT 80:30011/TCP

# STEP 6: Verify endpoints (Pods registered with Service)
kubectl get endpoints nginx-service
# Expected: 3 Pod IPs listed

# STEP 7: Test access via NodePort
curl http://localhost:30011
# Expected: nginx welcome page ✅
