#!/bin/bash
# Day 50 — Kubernetes Resource Requests & Limits
# Challenge: KodeKloud 100 Days of DevOps — Phase 4
# Task: Create httpd-pod with memory/CPU requests and limits

# ─────────────────────────────────────────
# From Jump Host (kubectl pre-configured)
# ─────────────────────────────────────────

# STEP 1: Create Pod manifest
cat << 'EOF' > httpd-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: httpd-pod
spec:
  containers:
    - name: httpd-container
      image: httpd:latest
      resources:
        requests:
          memory: "15Mi"
          cpu: "100m"
        limits:
          memory: "20Mi"
          cpu: "100m"
EOF

# STEP 2: Apply manifest
kubectl apply -f httpd-pod.yaml
# Expected: pod/httpd-pod created

# STEP 3: Verify pod is running
kubectl get pod httpd-pod
# Expected: STATUS Running

# STEP 4: Verify resource limits applied correctly
kubectl describe pod httpd-pod | grep -A 6 "Limits\|Requests"
# Expected:
#     Limits:
#       cpu:     100m
#       memory:  20Mi
#     Requests:
#       cpu:     100m
#       memory:  15Mi

# STEP 5: Check QoS class
kubectl get pod httpd-pod -o jsonpath='{.status.qosClass}'
# Expected: Burstable (requests != limits)

# STEP 6: Full pod details
kubectl describe pod httpd-pod
