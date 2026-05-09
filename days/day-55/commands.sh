#!/bin/bash
# Day 55 — Kubernetes Sidecar Pattern: Log Shipping with emptyDir
# Challenge: KodeKloud 100 Days of DevOps — Phase 4
# Task: nginx + sidecar container sharing logs via emptyDir

# ─────────────────────────────────────────
# From Jump Host (kubectl pre-configured)
# ─────────────────────────────────────────

# STEP 1: Create the Pod manifest
cat << 'EOF' > webserver.yaml
apiVersion: v1
kind: Pod
metadata:
  name: webserver
spec:
  volumes:
    - name: shared-logs
      emptyDir: {}

  initContainers:
    - name: sidecar-container
      image: ubuntu:latest
      command:
        - "sh"
        - "-c"
        - "while true; do cat /var/log/nginx/access.log /var/log/nginx/error.log; sleep 30; done"
      restartPolicy: Always
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log/nginx

  containers:
    - name: nginx-container
      image: nginx:latest
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log/nginx
EOF

# STEP 2: Apply
kubectl apply -f webserver.yaml

# STEP 3: Verify pod is running
kubectl get pod webserver
# Expected: 1/1 Running

# STEP 4: Check sidecar output — confirms it's reading nginx logs
kubectl logs webserver -c sidecar-container

# STEP 5: Follow sidecar logs live
kubectl logs webserver -c sidecar-container -f

# STEP 6: Verify volume mount on both containers
kubectl describe pod webserver | grep -A 3 "Mounts"

# STEP 7: Generate traffic to see logs flowing
kubectl exec webserver -c nginx-container -- curl -s http://localhost/
# Then check sidecar logs again
kubectl logs webserver -c sidecar-container
