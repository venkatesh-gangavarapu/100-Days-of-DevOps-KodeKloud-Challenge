#!/bin/bash
# Day 58 — Grafana Deployment on Kubernetes
# Challenge: KodeKloud 100 Days of DevOps — Phase 4
# Task: Deploy Grafana + expose on NodePort 32000

# STEP 1: Apply Deployment
kubectl apply -f grafana-deployment.yaml
# Expected: deployment.apps/grafana-deployment-nautilus created

# STEP 2: Apply Service
kubectl apply -f grafana-service.yaml
# Expected: service/grafana-service-nautilus created

# STEP 3: Verify Deployment is running
kubectl get deployment grafana-deployment-nautilus
# Expected: READY 1/1

# STEP 4: Verify Pod is running
kubectl get pods -l app=grafana
# Expected: Running

# STEP 5: Verify Service
kubectl get service grafana-service-nautilus
# Expected: NodePort, 3000:32000/TCP

# STEP 6: Verify endpoints
kubectl get endpoints grafana-service-nautilus
# Expected: Pod IP listed

# STEP 7: Access Grafana login page
curl -s http://localhost:32000 | grep -i "grafana"
# Or open in browser: http://<node-ip>:32000
# Default credentials: admin / admin
