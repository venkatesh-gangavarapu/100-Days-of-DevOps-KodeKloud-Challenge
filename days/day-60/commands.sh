#!/bin/bash
# Day 60 — Kubernetes PV + PVC + Pod + Service (Phase 4 Finale)
# Challenge: KodeKloud 100 Days of DevOps — Phase 4
# Task: Full storage stack — PV → PVC → Pod (httpd) → NodePort Service

# ─────────────────────────────────────────
# STEP 1: Create PersistentVolume
# ─────────────────────────────────────────
kubectl apply -f pv-nautilus.yaml
# Expected: persistentvolume/pv-nautilus created

# STEP 2: Verify PV is Available
kubectl get pv pv-nautilus
# Expected: STATUS Available, CAPACITY 3Gi, ACCESS ReadWriteOnce

# ─────────────────────────────────────────
# STEP 3: Create PersistentVolumeClaim
# ─────────────────────────────────────────
kubectl apply -f pvc-nautilus.yaml
# Expected: persistentvolumeclaim/pvc-nautilus created

# STEP 4: Verify PVC is Bound to PV
kubectl get pvc pvc-nautilus
# Expected: STATUS Bound, VOLUME pv-nautilus, CAPACITY 3Gi

# ─────────────────────────────────────────
# STEP 5: Create Pod
# ─────────────────────────────────────────
kubectl apply -f pod-nautilus.yaml
# Expected: pod/pod-nautilus created

# STEP 6: Verify Pod is Running
kubectl get pod pod-nautilus
# Expected: STATUS Running

# ─────────────────────────────────────────
# STEP 7: Create NodePort Service
# ─────────────────────────────────────────
kubectl apply -f web-nautilus-service.yaml
# Expected: service/web-nautilus created

# STEP 8: Verify Service
kubectl get service web-nautilus
# Expected: TYPE NodePort, PORT 80:30008/TCP

# ─────────────────────────────────────────
# STEP 9: Verify endpoints connected
# ─────────────────────────────────────────
kubectl get endpoints web-nautilus
# Expected: Pod IP listed

# STEP 10: Test
curl http://localhost:30008
# Expected: httpd default page ✅

# ─────────────────────────────────────────
# FULL VERIFICATION
# ─────────────────────────────────────────
kubectl get pv,pvc,pod,svc
# All resources in one view
