#!/bin/bash
# Day 54 — Kubernetes Shared emptyDir Volume Between Containers
# Challenge: KodeKloud 100 Days of DevOps — Phase 4
# Task: Create pod with 2 containers sharing emptyDir volume, verify shared data

# ─────────────────────────────────────────
# From Jump Host (kubectl pre-configured)
# ─────────────────────────────────────────

# STEP 1: Create the Pod manifest
cat << 'EOF' > volume-share-xfusion.yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-share-xfusion
spec:
  containers:
    - name: volume-container-xfusion-1
      image: debian:latest
      command: ["sleep", "3600"]
      volumeMounts:
        - name: volume-share
          mountPath: /tmp/official

    - name: volume-container-xfusion-2
      image: debian:latest
      command: ["sleep", "3600"]
      volumeMounts:
        - name: volume-share
          mountPath: /tmp/apps

  volumes:
    - name: volume-share
      emptyDir: {}
EOF

# STEP 2: Apply
kubectl apply -f volume-share-xfusion.yaml

# STEP 3: Verify pod running (wait for 2/2)
kubectl get pod volume-share-xfusion
# Expected: READY 2/2, STATUS Running

# STEP 4: Create file in container 1
kubectl exec volume-share-xfusion \
  -c volume-container-xfusion-1 -- \
  sh -c 'echo "Welcome to xFusionCorp Industries" > /tmp/official/official.txt'

# STEP 5: Verify from container 1
kubectl exec volume-share-xfusion \
  -c volume-container-xfusion-1 -- \
  cat /tmp/official/official.txt
# Expected: Welcome to xFusionCorp Industries

# STEP 6: Verify from container 2 (different path, same volume)
kubectl exec volume-share-xfusion \
  -c volume-container-xfusion-2 -- \
  cat /tmp/apps/official.txt
# Expected: Welcome to xFusionCorp Industries ✅
