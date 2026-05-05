# Day 51 — Kubernetes Rolling Update: nginx-deployment to nginx:1.17

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Rolling Updates  
**Difficulty:** Beginner–Intermediate  
**Phase:** Phase 4 — AWS Core Services  
**Status:** ✅ Completed

---

## 📋 Task Summary

Execute a rolling update on `nginx-deployment` to upgrade from the current image to `nginx:1.17`. All Pods must be operational post-update.

---

## 🧠 Concept — Kubernetes Rolling Updates

### What is a Rolling Update?

A rolling update gradually replaces old Pods with new ones — at no point does the entire application go down. Kubernetes creates new Pods with the updated image while simultaneously terminating old ones, maintaining availability throughout.

```
Before update:
Pod-1 (nginx:latest) ✅
Pod-2 (nginx:latest) ✅
Pod-3 (nginx:latest) ✅

During rolling update:
Pod-1 (nginx:1.17)   ✅  ← new
Pod-2 (nginx:latest) ✅  ← old, still running
Pod-3 (nginx:latest) ✅  ← old, still running

After update:
Pod-1 (nginx:1.17) ✅
Pod-2 (nginx:1.17) ✅
Pod-3 (nginx:1.17) ✅
```

### Rolling Update Strategy Parameters

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 25%        # Max extra Pods allowed during update
    maxUnavailable: 25%  # Max Pods that can be unavailable during update
```

For a 4-replica Deployment with defaults (25%/25%):
- Can have up to 5 Pods during update (4 + 1 surge)
- Can have as few as 3 running at any time (4 - 1 unavailable)

### How `kubectl set image` Works

```bash
kubectl set image deployment/<deployment-name> <container-name>=<new-image>
```

This updates the Pod template's container image, which triggers the Deployment controller to start a rolling update automatically.

### Rollout Commands

| Command | Purpose |
|---------|---------|
| `kubectl set image` | Trigger the update |
| `kubectl rollout status` | Watch progress in real time |
| `kubectl rollout history` | See revision history |
| `kubectl rollout undo` | Rollback to previous version |
| `kubectl rollout pause` | Pause mid-rollout |
| `kubectl rollout resume` | Resume paused rollout |

> **Real-world context:** Rolling updates are the standard zero-downtime deployment strategy in Kubernetes. Every CI/CD pipeline that deploys to Kubernetes ends with either `kubectl set image` or `kubectl apply` on an updated manifest — both trigger the same rolling update mechanism. Understanding rollout status, pause/resume, and rollback is essential for any engineer operating Kubernetes in production.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Access | Jump Host (kubectl pre-configured) |
| Deployment | `nginx-deployment` |
| New image | `nginx:1.17` |

---

## 🔧 Solution — Step by Step

### Step 1: Inspect the current deployment

```bash
kubectl get deployment nginx-deployment
kubectl describe deployment nginx-deployment | grep -i image
```

Note the current image and the **container name** — needed for `kubectl set image`.

### Step 2: Check current pods

```bash
kubectl get pods
```

### Step 3: Execute the rolling update

```bash
kubectl set image deployment/nginx-deployment \
  nginx-container=nginx:1.17
```

Replace `nginx-container` with the actual container name from `kubectl describe`.

**Expected:**
```
deployment.apps/nginx-deployment image updated
```

### Step 4: Watch the rollout in real time

```bash
kubectl rollout status deployment/nginx-deployment
```

**Expected:**
```
Waiting for deployment "nginx-deployment" rollout to finish: 1 out of X new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: X old replicas are pending termination...
deployment "nginx-deployment" successfully rolled out
```

### Step 5: Verify all pods are running and healthy

```bash
kubectl get pods
```

**Expected:** All pods in `Running` state — no `Terminating` or `Pending`.

### Step 6: Confirm new image is deployed

```bash
kubectl describe deployment nginx-deployment | grep Image
# Expected: Image: nginx:1.17
```

### Step 7: Check rollout history

```bash
kubectl rollout history deployment/nginx-deployment
```

Shows revision history — useful for rollback if needed.

✅ Rolling update complete. All pods running nginx:1.17.

---

## 📌 Commands Reference

```bash
# ─── Inspect before update ───────────────────────────────
kubectl get deployment nginx-deployment
kubectl describe deployment nginx-deployment | grep -i image
kubectl get pods

# ─── Execute rolling update ──────────────────────────────
kubectl set image deployment/nginx-deployment \
  nginx-container=nginx:1.17

# ─── Monitor rollout ─────────────────────────────────────
kubectl rollout status deployment/nginx-deployment
kubectl get pods -w                           # Watch pods change

# ─── Verify ──────────────────────────────────────────────
kubectl get pods
kubectl describe deployment nginx-deployment | grep Image
kubectl rollout history deployment/nginx-deployment

# ─── Rollback if needed ──────────────────────────────────
kubectl rollout undo deployment/nginx-deployment
kubectl rollout undo deployment/nginx-deployment --to-revision=1

# ─── Annotate rollout (best practice) ────────────────────
kubectl annotate deployment nginx-deployment \
  kubernetes.io/change-cause="Update to nginx:1.17"
```

---

## ⚠️ Common Mistakes to Avoid

1. **Wrong container name in `kubectl set image`** — The format is `container-name=image:tag`. If you use the Pod name or Deployment name instead of the container name, the command appears to succeed but doesn't actually update the image. Always check the container name with `kubectl describe deployment` first.
2. **Not watching `kubectl rollout status`** — The update command returns immediately. Without checking rollout status, you don't know if Pods are actually running with the new image or stuck in `ImagePullBackOff`.
3. **Skipping verification** — Always confirm with `kubectl describe deployment | grep Image` after the rollout. A successful status message doesn't guarantee the right image is running.
4. **No rollout annotation** — In production, always annotate with `kubernetes.io/change-cause` so `kubectl rollout history` shows meaningful descriptions instead of just revision numbers.

---

## 🔍 Rolling Update Under the Hood

```
kubectl set image → Deployment controller detects template change
        │
        ▼
Creates new ReplicaSet (nginx:1.17) with 0 replicas
        │
        ▼
Scales new ReplicaSet up (1 Pod → 2 Pods → ...)
Scales old ReplicaSet down (N Pods → N-1 → ...)
simultaneously, respecting maxSurge and maxUnavailable
        │
        ▼
Old ReplicaSet reaches 0 (kept for rollback)
New ReplicaSet reaches desired count
        │
        ▼
Rollout complete ✅
```

Old ReplicaSet is kept at 0 replicas — this is what `kubectl rollout undo` uses.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is a Kubernetes rolling update and how does it achieve zero downtime?**

A rolling update gradually replaces old Pods with new ones rather than terminating everything at once. The Deployment controller creates a new ReplicaSet with the updated Pod template and incrementally scales it up while scaling down the old ReplicaSet. At no point are all Pods unavailable — `maxUnavailable` (default 25%) controls the minimum that must stay running, and `maxSurge` (default 25%) controls how many extra Pods can exist during the transition. Traffic continues flowing to available Pods throughout. Zero downtime is achieved because the service's load balancer (Service resource) routes only to Ready pods — it automatically stops sending to Pods that are being terminated.

---

**Q2: What is the difference between `kubectl set image` and updating the image in the YAML manifest?**

`kubectl set image` is an imperative command that directly patches the Deployment's container image field — it's fast and doesn't require editing a file. Updating the YAML manifest and running `kubectl apply` is the declarative approach — the manifest remains the source of truth, the change is version-controlled, and reviewable in a PR. Both trigger the same rolling update mechanism. In production CI/CD pipelines, the declarative approach is preferred: the pipeline updates the image tag in the manifest file, commits it, and applies it — giving you a full audit trail of exactly what was deployed when and by whom. `kubectl set image` is useful for quick hotfixes or testing but doesn't update your stored manifest.

---

**Q3: How do you roll back a failed deployment in Kubernetes?**

`kubectl rollout undo deployment/nginx-deployment` reverts to the previous revision — Kubernetes scales up the previous ReplicaSet and scales down the current one, using the same rolling update mechanism in reverse. `kubectl rollout undo deployment/nginx-deployment --to-revision=2` rolls back to a specific revision from `kubectl rollout history`. The rollback itself is another rolling update — zero downtime. The number of revisions kept is controlled by `revisionHistoryLimit` in the Deployment spec (default: 10). In production, setting meaningful `kubernetes.io/change-cause` annotations makes the history readable: `kubectl rollout history` shows "Deploy v2.1.0" instead of just "CHANGE-CAUSE: <none>".

---

**Q4: What is `maxSurge` and `maxUnavailable` in a rolling update strategy?**

`maxSurge` defines how many extra Pods can exist above the desired replica count during an update. With `replicas: 4` and `maxSurge: 1`, up to 5 Pods can exist simultaneously. `maxUnavailable` defines how many Pods can be unavailable (not Ready) during the update. With `replicas: 4` and `maxUnavailable: 1`, at least 3 Pods must be Ready at all times. Setting `maxUnavailable: 0` and `maxSurge: 1` gives a fully non-disruptive update — always maintain full capacity, add new before removing old. This is the safest strategy for user-facing services but requires more node capacity. Setting `maxSurge: 0` and `maxUnavailable: 1` does the opposite — terminate one old before creating one new, conserving capacity but briefly reducing it.

---

**Q5: How do you pause and resume a Kubernetes rolling update?**

`kubectl rollout pause deployment/nginx-deployment` stops the rolling update mid-way. Pods that have already been updated remain on the new image; Pods that haven't been updated remain on the old image. This lets you verify the behavior of the new version on a subset of traffic before completing the rollout — a manual canary approach. `kubectl rollout resume deployment/nginx-deployment` continues the update. If you pause and `kubectl set image` again (changing the image a second time), both changes are applied when you resume — the Deployment batches the updates. `kubectl rollout status` after pausing shows it's paused and waits.

---

**Q6: What is `kubectl rollout history` and how should you use it in production?**

`kubectl rollout history deployment/nginx-deployment` shows all stored revisions of a Deployment with their change causes. By default, `CHANGE-CAUSE` shows `<none>` — making the history useless for understanding what changed when. The fix: annotate before or after each update: `kubectl annotate deployment nginx-deployment kubernetes.io/change-cause="Deploy nginx:1.17 - security patch"`. In CI/CD pipelines, always include the change cause annotation in the deployment step, using the commit SHA, ticket number, or release version. `kubectl rollout history deployment/nginx-deployment --revision=3` shows the full spec of a specific revision — useful for comparing what exactly changed between versions.

---

## 🔗 References

- [Kubernetes Rolling Updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
- [`kubectl rollout` documentation](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#rollout)
- [Deployment Update Strategy](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
