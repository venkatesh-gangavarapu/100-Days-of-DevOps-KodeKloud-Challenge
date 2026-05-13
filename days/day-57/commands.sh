#!/bin/bash
# Day 57 — Kubernetes Environment Variables in Pods
# Challenge: KodeKloud 100 Days of DevOps — Phase 4
# Task: Pod with 3 env vars, echo them using shell command, restartPolicy: Never

# STEP 1: Apply manifest
kubectl apply -f print-envars-greeting.yaml
# Expected: pod/print-envars-greeting created

# STEP 2: Wait for pod to complete
kubectl get pod print-envars-greeting
# Expected: STATUS Completed (restartPolicy: Never — runs once and exits)

# STEP 3: View the output
kubectl logs -f print-envars-greeting
# Expected: Welcome to DevOps Industries ✅

# STEP 4: Verify env vars are set correctly
kubectl exec print-envars-greeting -- env | grep -E "GREETING|COMPANY|GROUP"
# Only works while pod is still Running
