#!/bin/bash
# Day 53 — K8s Troubleshooting: nginx + PHP-FPM Pod Fix
# Challenge: KodeKloud 100 Days of DevOps — Phase 4
# Task: Fix nginx-phpfpm pod, copy index.php to nginx document root

# ─────────────────────────────────────────
# STEP 1: Check pod status
# ─────────────────────────────────────────
kubectl get pod nginx-phpfpm
kubectl describe pod nginx-phpfpm
# Look for: container states, restart counts, Events section

# ─────────────────────────────────────────
# STEP 2: Check logs in both containers
# ─────────────────────────────────────────
kubectl logs nginx-phpfpm -c nginx-container
kubectl logs nginx-phpfpm -c php-fpm-container

# ─────────────────────────────────────────
# STEP 3: Inspect the ConfigMap
# ─────────────────────────────────────────
kubectl get configmap nginx-config -o yaml
# Look for fastcgi_pass — should be 127.0.0.1:9000
# In multi-container Pod, nginx and phpfpm share localhost

# ─────────────────────────────────────────
# STEP 4: Fix the ConfigMap
# ─────────────────────────────────────────
kubectl edit configmap nginx-config
# Change fastcgi_pass to: 127.0.0.1:9000
# Save and exit

# ─────────────────────────────────────────
# STEP 5: Restart pod to pick up ConfigMap changes
# ─────────────────────────────────────────
kubectl delete pod nginx-phpfpm
# Wait for pod to be recreated
kubectl get pod nginx-phpfpm -w
# Wait for STATUS: Running

# ─────────────────────────────────────────
# STEP 6: Copy index.php to nginx document root
# ─────────────────────────────────────────
kubectl cp /home/thor/index.php \
  nginx-phpfpm:/var/www/html/index.php -c nginx-container
# -c nginx-container: required for multi-container pods

# ─────────────────────────────────────────
# STEP 7: Verify
# ─────────────────────────────────────────
kubectl get pod nginx-phpfpm
kubectl exec nginx-phpfpm -c nginx-container -- ls -la /var/www/html/
# Expected: index.php visible ✅

# Click Website button to confirm PHP page loads
