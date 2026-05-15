# Day 59 — Kubernetes Troubleshooting: Fixing a Broken Redis Deployment

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Troubleshooting / Deployments  
**Difficulty:** Intermediate  
**Phase:** Phase 4 — AWS Core Services  
**Status:** ✅ Completed

---

## 📋 Task Summary

The `redis-deployment` went down after a team member made incorrect changes. Diagnose the root cause from pod events and logs, fix the deployment, and restore all pods to Running state.

---

## 🧠 Concept — Systematic Kubernetes Troubleshooting

### The Diagnostic Funnel

Never guess and edit. Always read what Kubernetes is already telling you.

```
Level 1: Deployment
  kubectl get deployment redis-deployment
  kubectl describe deployment redis-deployment

Level 2: Pods
  kubectl get pods
  kubectl get pods -l app=redis

Level 3: Pod details (Events = root cause)
  kubectl describe pod <pod-name>
  └── Events section at the bottom is the most important part

Level 4: Container logs
  kubectl logs <pod-name>
  kubectl logs <pod-name> --previous    ← crashed container logs
```

Work top-down. Most real issues surface in `kubectl describe pod` Events.

### Pod Status → What It Means

| Status | Meaning | Where to look |
|--------|---------|---------------|
| `Pending` | Can't be scheduled | Node resources, nodeSelector, PVC |
| `ImagePullBackOff` | Can't pull image | Wrong image name/tag, registry auth |
| `ErrImagePull` | Same as above, first attempt | Image name, registry access |
| `CrashLoopBackOff` | Container starts then crashes | `kubectl logs --previous`, CMD/args |
| `CreateContainerConfigError` | Bad config reference | Env vars, secrets, configmaps |
| `OOMKilled` | Memory limit exceeded | Increase memory limits |
| `RunContainerError` | Container runtime error | `kubectl describe pod` events |

### Common Redis Deployment Issues

```
1. Wrong image tag:
   image: redis:latest7  ← typo → ImagePullBackOff

2. Wrong command:
   command: ["redis"]    ← should be ["redis-server"] → CrashLoopBackOff

3. Wrong port:
   containerPort: 8080   ← redis listens on 6379 → app-level failure

4. Bad resource requests:
   requests: cpu: "100"  ← should be "100m" → CreateContainerConfigError

5. Wrong env var reference:
   secretKeyRef: name: wrong-secret  ← missing secret → CreateContainerConfigError
```

### The Fix Pattern

```bash
# 1. Identify the error
kubectl describe pod <name>   # Read Events carefully

# 2. Edit the deployment (change is applied as rolling update)
kubectl edit deployment redis-deployment

# 3. Monitor the fix
kubectl rollout status deployment/redis-deployment

# 4. Verify
kubectl get pods
```

> **Real-world context:** Deployment troubleshooting is a daily SRE responsibility. "Pods not running" is the most common alert any Kubernetes engineer responds to. The diagnostic pattern — get → describe → logs → edit — is muscle memory for experienced engineers. The ability to read `kubectl describe pod` Events and immediately identify the cause (wrong image, bad secret reference, insufficient resources) is what distinguishes engineers who can respond confidently to incidents from those who guess and experiment.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Access | Jump Host (kubectl pre-configured) |
| Deployment | `redis-deployment` |
| Issue | Pods not in Running state |

---

## 🔧 Solution — Step by Step

### Step 1: Check Deployment status

```bash
kubectl get deployment redis-deployment
```

Note READY count — if it shows `0/1` or `0/3`, pods are failing.

### Step 2: Check pod status and names

```bash
kubectl get pods
```

Note pod status — `ImagePullBackOff`, `CrashLoopBackOff`, `Pending`, etc.

### Step 3: Describe the failing pod — Events = root cause

```bash
kubectl describe pod <pod-name>
```

**Read the Events section at the bottom** — it contains the exact error message.

### Step 4: Check logs if container started

```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous    # for restarted containers
```

### Step 5: Edit the deployment to fix the issue

```bash
kubectl edit deployment redis-deployment
```

Fix the identified issue — wrong image tag, bad command, incorrect config reference.

### Step 6: Monitor the rollout

```bash
kubectl rollout status deployment/redis-deployment
# Expected: deployment "redis-deployment" successfully rolled out
```

### Step 7: Verify all pods running

```bash
kubectl get pods
# Expected: all pods STATUS Running ✅

kubectl describe deployment redis-deployment | grep -i image
# Confirm correct image is now running
```

---

## 📌 Full Diagnostic Commands Reference

```bash
# ─── Deployment level ────────────────────────────────────
kubectl get deployment redis-deployment
kubectl describe deployment redis-deployment
kubectl get deployment redis-deployment -o yaml   # Full spec

# ─── Pod level ───────────────────────────────────────────
kubectl get pods
kubectl get pods -l app=redis
kubectl describe pod <pod-name>                   # Events = root cause
kubectl get pod <pod-name> -o yaml                # Full pod spec

# ─── Container logs ──────────────────────────────────────
kubectl logs <pod-name>
kubectl logs <pod-name> --previous                # After crash
kubectl logs <pod-name> -c <container-name>       # Multi-container

# ─── Fix ─────────────────────────────────────────────────
kubectl edit deployment redis-deployment          # Interactive edit
kubectl set image deployment/redis-deployment \
  redis=redis:latest                              # Quick image fix

# ─── Monitor fix ─────────────────────────────────────────
kubectl rollout status deployment/redis-deployment
kubectl get pods -w                               # Watch pods update

# ─── Verify ──────────────────────────────────────────────
kubectl get pods
kubectl get deployment redis-deployment
```

---

## ⚠️ Troubleshooting Checklist

When a Deployment has pods not Running, check in order:

```
□ kubectl describe pod → Events → what exact error?
□ ImagePullBackOff → check image name and tag for typos
□ CrashLoopBackOff → kubectl logs --previous → what did container print?
□ Pending → kubectl describe pod → "Insufficient cpu/memory"? Node selector?
□ CreateContainerConfigError → ConfigMap/Secret referenced correctly?
□ Resource requests → valid format? (100m not 100, 128Mi not 128M)
□ Volume mounts → PVC exists? ConfigMap exists?
□ Port numbers → matches what the application actually listens on?
```

---

## 🔍 Reading `kubectl describe pod` Events

```
Events:
  Type     Reason     Age   From               Message
  ----     ------     ----  ----               -------
  Normal   Scheduled  2m    default-scheduler  Assigned to node01
  Normal   Pulling    2m    kubelet            Pulling image "redis:lates"
  Warning  Failed     2m    kubelet            Failed to pull image "redis:lates":
                                               rpc error: ... not found
  Warning  BackOff    1m    kubelet            Back-off pulling image "redis:lates"
```

This tells you exactly: wrong image tag `redis:lates` (typo, missing 't'). Fix: `redis:latest`.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the first thing you check when pods are not Running in Kubernetes?**

`kubectl describe pod <pod-name>` and read the Events section at the bottom. This is non-negotiable as the first step — not logs, not the deployment spec, not guessing. Events record exactly what Kubernetes attempted and what failed: image pull failures with the exact error, scheduling failures with the reason, container creation errors with the specific config issue. The Events section is Kubernetes telling you precisely what went wrong. `kubectl get pods` tells you there's a problem; `kubectl describe pod` tells you what the problem is.

---

**Q2: What is `ImagePullBackOff` and how do you fix it?**

`ImagePullBackOff` means Kubernetes cannot pull the container image. Common causes: (1) Typo in the image name or tag — `redis:lates` instead of `redis:latest`. Fix: `kubectl edit deployment` and correct the image field. (2) Private registry requiring authentication — the cluster doesn't have the pull secret. Fix: create an `imagePullSecret` and reference it in the Pod spec. (3) Registry unreachable — network issue or registry outage. Fix: check network connectivity and registry status. (4) Image doesn't exist at the specified tag — the tag was deleted from the registry. Fix: use an existing tag. `kubectl describe pod` Events show the exact pull error message.

---

**Q3: What is `CrashLoopBackOff` and what causes it?**

`CrashLoopBackOff` means the container starts and then exits (crashes) repeatedly. Kubernetes restarts it with exponential backoff — 10s, 20s, 40s, 80s — which is why "BackOff" is in the name. The container is not stuck; it's crashing and being restarted. Common causes: wrong startup command, application configuration error (bad env var, missing config file), the process requires a dependency that isn't available, or OOMKill (memory limit too low). Diagnosis: `kubectl logs <pod> --previous` shows the output from the last crashed container — this usually contains the actual application error message. Fix the root cause in the application config or Deployment spec.

---

**Q4: What is the difference between `kubectl edit` and `kubectl apply` for fixing a Deployment?**

`kubectl edit deployment redis-deployment` opens the live Deployment spec in your default editor. Changes are applied immediately when you save — no file required. It's the fastest way to make a targeted fix during an incident. `kubectl apply -f deployment.yaml` applies a full manifest file — the source of truth. After an `kubectl edit` fix, always update the corresponding YAML file in your repository to match, or the next `kubectl apply` will revert your fix. In production, incident hotfixes via `kubectl edit` are acceptable but must be followed by a proper Git commit updating the manifest. `kubectl edit` without a Git update creates configuration drift.

---

**Q5: How do you check why a Pod is stuck in `Pending` state?**

`kubectl describe pod <name>` Events — a Pending Pod hasn't been scheduled to a node yet. Common reasons: (1) Insufficient node resources — "0/N nodes are available: N Insufficient cpu". Fix: reduce resource requests or add nodes. (2) Node selector mismatch — `nodeSelector` labels don't match any nodes. Fix: correct labels or remove nodeSelector. (3) Taints and tolerations — all nodes have a taint the Pod doesn't tolerate. Fix: add the appropriate toleration. (4) PVC not bound — Pod requires a PersistentVolumeClaim that hasn't been provisioned. Fix: check `kubectl get pvc` for the claim status. The Events message is usually explicit about the reason.

---

**Q6: How would you prevent this kind of accidental breakage in a production environment?**

Several layers: (1) **GitOps** — all Kubernetes changes go through Git PRs with review, not direct `kubectl edit`. ArgoCD or Flux sync cluster state from Git, making unauthorized changes visible and reversible. (2) **Admission webhooks** — validate manifests before they're applied. OPA Gatekeeper or Kyverno can enforce policies like "image must be from approved registry" or "resources must be set". (3) **RBAC** — restrict who can edit Deployments in production namespaces. Developers edit in dev; only CI/CD pipelines apply to production. (4) **Deployment notifications** — alert on Deployment changes and pod failures immediately. (5) **Staging environments** — all changes tested in staging before production.

---

## 🔗 References

- [Kubernetes — Debugging Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/)
- [kubectl describe documentation](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#describe)
- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*

---

## 🔍 Actual Root Cause Found (Real Lab Output)

### What `kubectl describe pod` Revealed

```
Events:
  Warning  FailedMount  39s (x8 over 103s)  kubelet
    MountVolume.SetUp failed for volume "config": configmap "redis-conig" not found
```

### Two Bugs — Both Typos

**Bug 1 — ConfigMap name typo (primary blocker):**
```
Volume config references: redis-conig   ← missing 'f'
Correct name should be:   redis-config
```
The pod was stuck in `ContainerCreating` because Kubernetes couldn't mount the config volume — the ConfigMap name in the Deployment spec didn't match the actual ConfigMap that existed in the cluster.

**Bug 2 — Image tag typo:**
```
Image: redis:alpin    ← missing 'e'
Should be: redis:alpine
```

### The Fix

```bash
kubectl edit deployment redis-deployment
```

Changed in the spec:
```yaml
# Fix 1: Image tag
image: redis:alpine          # was: redis:alpin

# Fix 2: ConfigMap volume reference
volumes:
  - name: config
    configMap:
      name: redis-config     # was: redis-conig
```

### After the Fix

```bash
kubectl rollout status deployment/redis-deployment
# deployment "redis-deployment" successfully rolled out ✅

kubectl get pods
# redis-deployment-xxxxx   1/1   Running   0   30s ✅
```

### Key Lesson

The pod was `Pending` / `ContainerCreating` — NOT `ImagePullBackOff` or `CrashLoopBackOff`. This meant the image pull wasn't the first failure — the volume mount failed before the container even started. `kubectl describe pod` Events told the full story without needing `kubectl logs` at all. Logs were unavailable because the container never started — the mount failure happened first.
