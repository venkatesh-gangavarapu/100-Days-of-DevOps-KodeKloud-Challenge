# Day 64 — Kubernetes Troubleshooting: Fixing a Misconfigured Flask App

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Troubleshooting / Services  
**Difficulty:** Intermediate  
**Phase:** Phase 5 — Advanced Kubernetes & CI/CD  
**Status:** ✅ Completed

---

## 📋 Task Summary

The `python-deployment-datacenter` using `poroko/flask-demo-app` is deployed but not accessible. Diagnose and fix the misconfiguration. The app must be reachable on nodePort `32345`, and `targetPort` must be Flask's default port (`5000`).

---

## 🧠 Concept — Flask Default Port & Service Port Mapping

### Flask Default Port

Python Flask runs on **port 5000** by default:
```python
app.run(host='0.0.0.0', port=5000)
```

If `targetPort` in the Service points to any other port, traffic is forwarded to a port where nothing is listening — connection refused or timeout.

### The Misconfiguration Pattern

```
User → nodePort:32345 → Service → targetPort:WRONG → Pod:5000 (nothing listening on WRONG)
                                                              ↑ connection fails
Fix:
User → nodePort:32345 → Service → targetPort:5000 → Pod:5000 ✅
```

### Diagnostic Approach

```
kubectl describe svc  → wrong targetPort?
kubectl describe pod  → pod state, events
kubectl logs <pod>    → what port is Flask actually on?
```

---

## 🔧 Solution — Step by Step

### Step 1: Check deployment and image

```bash
kubectl get deployment python-deployment-datacenter
kubectl describe deployment python-deployment-datacenter | grep -i image
# Verify: poroko/flask-demo-app
```

### Step 2: Check pod status

```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
# Look for: "Running on http://0.0.0.0:5000"
```

### Step 3: Check service configuration

```bash
kubectl get svc
kubectl describe svc <service-name>
# Look for targetPort and nodePort values
```

### Step 4: Fix the service

```bash
kubectl edit svc <service-name>
```

Set the correct ports:
```yaml
ports:
  - port: 5000
    targetPort: 5000      # Flask default port
    nodePort: 32345       # required nodePort
    protocol: TCP
```

### Step 5: Fix deployment containerPort if wrong

```bash
kubectl edit deployment python-deployment-datacenter
```

Set:
```yaml
ports:
  - containerPort: 5000
```

### Step 6: Verify

```bash
kubectl get pods          # Running ✅
kubectl get svc           # 5000:32345/TCP ✅
curl http://localhost:32345
```

---

## ⚠️ Common Issues and Fixes

| Symptom | Cause | Fix |
|---------|-------|-----|
| Connection refused on 32345 | Wrong targetPort | Set targetPort: 5000 |
| Pod in ImagePullBackOff | Wrong image | Fix image: poroko/flask-demo-app |
| Pod CrashLoopBackOff | App error | Check kubectl logs |
| NodePort not 32345 | Wrong nodePort | Set nodePort: 32345 |

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: How do you determine what port a containerized application listens on?**

Three sources of truth: (1) `kubectl logs <pod>` — the application startup message usually prints the port. Flask prints `Running on http://0.0.0.0:5000`. Django prints `Starting development server at http://0.0.0.0:8000/`. (2) The image documentation on Docker Hub — `poroko/flask-demo-app` documentation should specify the exposed port. (3) `EXPOSE` in the Dockerfile — `kubectl exec <pod> -- cat /path/to/Dockerfile` if accessible, or `docker inspect` the image locally. Always verify rather than assuming. A targetPort pointed at the wrong port produces a working Service that silently drops all traffic.

---

**Q2: What is the difference between `port`, `targetPort`, and `nodePort` in a Service?**

`nodePort` (32345) is the port exposed on every cluster node — external traffic entry. `port` is the Service's virtual cluster-internal port — other services inside the cluster use this. `targetPort` (5000) is the actual port on the container where the application listens — this must match the application's listening port exactly. Traffic flows: external:32345 → Service:port → Pod:targetPort:5000. A wrong `targetPort` means traffic reaches the right Pod but connects to a port where nothing is listening.

---

**Q3: How would you troubleshoot "connection refused" when curl-ing a NodePort?**

Systematic check: (1) `kubectl get pods` — is the pod Running? (2) `kubectl get endpoints <svc>` — does the service have pod IPs registered? Empty endpoints = label selector mismatch. (3) `kubectl describe svc <name>` — check targetPort matches container port. (4) `kubectl logs <pod>` — what port is the app actually listening on? (5) `kubectl exec <pod> -- netstat -tlnp` or `ss -tlnp` — confirm which ports have active listeners inside the container. Connection refused specifically means the port is reachable but nothing is listening — targetPort mismatch is the most common cause.

---

**Q4: Why does the Service `port` field matter if NodePort is used for external access?**

`port` is used for cluster-internal service discovery. Other pods in the cluster connect to `<service-name>:<port>` using Kubernetes DNS. Even if external access uses NodePort 32345, an internal backend service might call `http://python-deployment-service:5000`. If `port` is set incorrectly, internal service-to-service communication fails even when external access works. Both must be correct for a fully functional service in a microservices architecture.

---

**Q5: What is the fastest way to check if a service is correctly forwarding traffic to its pods?**

`kubectl get endpoints <service-name>` is the single most informative command. If endpoints are empty: label selector mismatch between Service and Pods. If endpoints list pod IPs on the correct port: traffic should flow. Then `kubectl port-forward pod/<pod-name> 5000:5000` bypasses the Service entirely and connects directly to the pod — if port-forward works but NodePort doesn't, the issue is in the Service configuration. If port-forward also fails, the issue is in the pod itself (wrong port, app crash).

---

**Q6: How would you prevent port misconfiguration in a team environment?**

Three approaches: (1) **Document default ports** — maintain a service catalog that lists each application's default port. Flask=5000, Django=8000, Spring Boot=8080, etc. (2) **Define `containerPort` in the Deployment** — while `containerPort` is informational for Kubernetes, it documents intent and tools can validate that Service `targetPort` matches. (3) **Linting tools** — `kubeval`, `kube-score`, and `datree` can validate that Service targetPorts match declared container ports. (4) **GitOps review** — PR reviews catch port mismatches before they reach the cluster. The root cause of most port misconfigurations is copy-paste from another app's YAML without updating the ports.

---

## 🔗 References

- [Kubernetes Service Ports](https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service)
- [Flask Default Port](https://flask.palletsprojects.com/en/3.0.x/api/#flask.Flask.run)
- [Debugging Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*

---

## 🔍 Actual Root Cause Found (Real Lab Output)

### What `kubectl describe pod` Revealed

```
Image:    poroko/flask-app-demo   ← wrong (words swapped)
Events:
  Warning  Failed  Failed to pull image "poroko/flask-app-demo":
           pull access denied, repository does not exist
```

### The Bug — Transposed Image Name

```
Wrong:   poroko/flask-app-demo    ← "app" before "demo"
Correct: poroko/flask-demo-app    ← "demo" before "app"
```

Two words swapped. The image doesn't exist on Docker Hub. Classic copy-paste/typo error.

The container port was already correct (`5000/TCP`) — only the image name needed fixing.

### The Fix

```bash
kubectl edit deployment python-deployment-datacenter
# Change: image: poroko/flask-app-demo
# To:     image: poroko/flask-demo-app

kubectl rollout status deployment/python-deployment-datacenter
# deployment "python-deployment-datacenter" successfully rolled out ✅

kubectl get pods
# Running ✅

curl http://localhost:32345
# Flask app accessible ✅
```

### Key Lesson

`ImagePullBackOff` with "repository does not exist" = wrong image name. The error message is explicit. No need to look further — fix the image tag immediately. The container port (5000) was already correct in this case, so only the deployment needed editing, not the service.
