#!/bin/bash
# Day 62 — Kubernetes Secrets: Create from file, mount in Pod
# Challenge: KodeKloud 100 Days of DevOps — Phase 5
# Task: Create secret 'news' from /opt/news.txt, mount at /opt/apps in pod

# ─────────────────────────────────────────
# STEP 1: Read the secret file
# ─────────────────────────────────────────
cat /opt/news.txt

# ─────────────────────────────────────────
# STEP 2: Create generic secret from file
# ─────────────────────────────────────────
kubectl create secret generic news --from-file=/opt/news.txt
# Expected: secret/news created

# ─────────────────────────────────────────
# STEP 3: Verify secret was created
# ─────────────────────────────────────────
kubectl get secret news
# Expected: TYPE generic, DATA 1

kubectl describe secret news
# Shows key name (news.txt) without revealing the value

# Decode the secret value (base64)
kubectl get secret news -o jsonpath='{.data.news\.txt}' | base64 -d

# ─────────────────────────────────────────
# STEP 4: Deploy the Pod
# ─────────────────────────────────────────
kubectl apply -f secret-xfusion.yaml
# Expected: pod/secret-xfusion created

# ─────────────────────────────────────────
# STEP 5: Wait for Pod Running
# ─────────────────────────────────────────
kubectl get pod secret-xfusion
# Expected: STATUS Running, READY 1/1

# ─────────────────────────────────────────
# STEP 6: Verify secret is mounted at /opt/apps
# ─────────────────────────────────────────
kubectl exec secret-xfusion -c secret-container-xfusion -- ls /opt/apps/
# Expected: news.txt

kubectl exec secret-xfusion -c secret-container-xfusion -- cat /opt/apps/news.txt
# Expected: the licence/password from news.txt ✅
