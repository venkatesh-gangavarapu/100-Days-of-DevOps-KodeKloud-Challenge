#!/bin/bash
# Day 65 — Redis on Kubernetes with ConfigMap
# Challenge: KodeKloud 100 Days of DevOps — Phase 5
# Task: ConfigMap with maxmemory 2mb + Redis deployment with 2 volumes

# STEP 1: Apply ConfigMap first
kubectl apply -f redis-configmap.yaml
# Expected: configmap/my-redis-config created

# STEP 2: Verify ConfigMap
kubectl get configmap my-redis-config
kubectl describe configmap my-redis-config
# Expected: redis-config key with "maxmemory 2mb"

# STEP 3: Deploy Redis
kubectl apply -f redis-deployment.yaml
# Expected: deployment.apps/redis-deployment created

# STEP 4: Verify deployment
kubectl get deployment redis-deployment
# Expected: READY 1/1

# STEP 5: Verify pod
kubectl get pods -l app=redis
# Expected: Running

# STEP 6: Verify volumes are mounted
kubectl exec <pod-name> -- ls /redis-master
# Expected: redis-config file

kubectl exec <pod-name> -- cat /redis-master/redis-config
# Expected: maxmemory 2mb

kubectl exec <pod-name> -- ls /redis-master-data
# Expected: empty data dir

# STEP 7: Verify Redis is running on 6379
kubectl exec <pod-name> -- redis-cli ping
# Expected: PONG ✅
