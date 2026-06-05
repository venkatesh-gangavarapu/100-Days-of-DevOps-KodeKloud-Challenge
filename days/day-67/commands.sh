#!/bin/bash
# Day 67 — Kubernetes Guestbook App: Redis Master/Slave + PHP Frontend
# Challenge: KodeKloud 100 Days of DevOps — Phase 5
# Task: Full multi-tier guestbook with Redis replication + NodePort frontend

# ─────────────────────────────────────────
# STEP 1: Deploy entire stack
# ─────────────────────────────────────────
kubectl apply -f guestbook-stack.yaml
# Expected (7 resources):
# deployment.apps/redis-master created
# service/redis-master created
# deployment.apps/redis-slave created
# service/redis-slave created
# service/redis-follower created
# deployment.apps/frontend created
# service/frontend created

# ─────────────────────────────────────────
# STEP 2: Wait for all pods to be Running
# ─────────────────────────────────────────
kubectl get pods -w
# Expected:
# redis-master-xxx      1/1 Running  (1 pod)
# redis-slave-xxx-yyy   1/1 Running  (2 pods)
# redis-slave-xxx-zzz   1/1 Running
# frontend-xxx-aaa      1/1 Running  (3 pods)
# frontend-xxx-bbb      1/1 Running
# frontend-xxx-ccc      1/1 Running

# ─────────────────────────────────────────
# STEP 3: Verify all deployments
# ─────────────────────────────────────────
kubectl get deployments
# redis-master   1/1
# redis-slave    2/2
# frontend       3/3  ← all ready ✅

# ─────────────────────────────────────────
# STEP 4: Verify all services
# ─────────────────────────────────────────
kubectl get svc
# redis-master    ClusterIP  6379/TCP
# redis-slave     ClusterIP  6379/TCP
# redis-follower  ClusterIP  6379/TCP
# frontend        NodePort   80:30009/TCP ✅

# ─────────────────────────────────────────
# STEP 5: Test the guestbook app
# ─────────────────────────────────────────
curl http://localhost:30009
# Expected: Guestbook HTML page ✅
# Or click the App button in KodeKloud
