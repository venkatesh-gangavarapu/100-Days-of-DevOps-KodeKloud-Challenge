#!/bin/bash
# Day 48 — First Kubernetes Pod: pod-nginx
# Challenge: KodeKloud 100 Days of DevOps — Phase 4
# Task: Create pod-nginx with nginx:latest, label app=nginx_app, container nginx-container

# ─────────────────────────────────────────
# From jump host — kubectl pre-configured
# ─────────────────────────────────────────

# STEP 1: Verify cluster access
kubectl get nodes
# Expected: node(s) in Ready state

# STEP 2: Apply pod manifest (declarative - preferred)
kubectl apply -f pod-nginx.yaml
# Expected: pod/pod-nginx created

# ALTERNATIVE: Inline apply
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-nginx
  labels:
    app: nginx_app
spec:
  containers:
    - name: nginx-container
      image: nginx:latest
EOF

# STEP 3: Verify pod is running
kubectl get pod pod-nginx
# Expected: pod-nginx   1/1   Running   0   Xs

# STEP 4: Describe for full verification
kubectl describe pod pod-nginx
# Confirm: Labels=app=nginx_app, Container=nginx-container, Image=nginx:latest

# STEP 5: Filter by label
kubectl get pods -l app=nginx_app
# Expected: pod-nginx listed ✅

# ─────────────────────────────────────────
# USEFUL kubectl REFERENCE
# ─────────────────────────────────────────
# Full YAML output
# kubectl get pod pod-nginx -o yaml

# With node and IP
# kubectl get pod pod-nginx -o wide

# View logs
# kubectl logs pod-nginx

# Shell into pod
# kubectl exec -it pod-nginx -- /bin/bash

# Delete pod
# kubectl delete pod pod-nginx
