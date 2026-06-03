#!/bin/bash
# Day 66 — MySQL on Kubernetes: PV + PVC + Secrets + Deployment + Service
# Challenge: KodeKloud 100 Days of DevOps — Phase 5
# Task: Full MySQL stack with secretKeyRef env vars

# ─────────────────────────────────────────
# STEP 1: Apply entire stack
# ─────────────────────────────────────────
kubectl apply -f mysql-stack.yaml
# Expected (7 resources created):
# persistentvolume/mysql-pv created
# persistentvolumeclaim/mysql-pv-claim created
# secret/mysql-root-pass created
# secret/mysql-user-pass created
# secret/mysql-db-url created
# deployment.apps/mysql-deployment created
# service/mysql created

# ─────────────────────────────────────────
# STEP 2: Verify PV and PVC binding
# ─────────────────────────────────────────
kubectl get pv mysql-pv
# Expected: STATUS Bound, CAPACITY 250Mi

kubectl get pvc mysql-pv-claim
# Expected: STATUS Bound, VOLUME mysql-pv ✅

# ─────────────────────────────────────────
# STEP 3: Verify secrets
# ─────────────────────────────────────────
kubectl get secrets | grep mysql
# Expected: mysql-root-pass, mysql-user-pass, mysql-db-url

# ─────────────────────────────────────────
# STEP 4: Verify deployment and pod
# ─────────────────────────────────────────
kubectl get deployment mysql-deployment
# Expected: READY 1/1

kubectl get pods -l app=mysql
# Expected: Running ✅

# ─────────────────────────────────────────
# STEP 5: Verify service
# ─────────────────────────────────────────
kubectl get svc mysql
# Expected: NodePort 3306:30007/TCP ✅

# ─────────────────────────────────────────
# STEP 6: Verify env vars from secrets
# ─────────────────────────────────────────
POD=$(kubectl get pod -l app=mysql -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- env | grep MYSQL
# Expected: all 4 MYSQL_* variables set ✅

# ─────────────────────────────────────────
# STEP 7: Test MySQL connectivity
# ─────────────────────────────────────────
kubectl exec $POD -- mysql -u kodekloud_roy -pksH85UJjhb -e "SHOW DATABASES;"
# Expected: kodekloud_db7 listed ✅
