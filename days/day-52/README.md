# Day 52 — Kubernetes Rollback: Reverting nginx-deployment to Previous Revision

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Rollback  
**Difficulty:** Beginner  
**Phase:** Phase 4 — AWS Core Services  
**Status:** ✅ Completed

---

## 📋 Task Summary

A bug was introduced in the latest deployment of `nginx-deployment`. Roll back to the previous revision immediately.

---

## 🧠 Concept — Kubernetes Rollback

### How Rollback Works

Every time a Deployment is updated, Kubernetes creates a new ReplicaSet and keeps the old one at 0 replicas — exactly for rollback purposes. `kubectl rollout undo` simply reverses this: it scales the previous ReplicaSet back up and scales the current one down.

```
Current state (buggy release):
  ReplicaSet-v2 (nginx:1.17) → 3 replicas  ← active
  ReplicaSet-v1 (nginx:old)  → 0 replicas  ← kept for rollback

After kubectl rollout undo:
  ReplicaSet-v2 (nginx:1.17) → 0 replicas  ← scaled down
  ReplicaSet-v1 (nginx:old)  → 3 replicas  ← scaled back up ✅
```

The rollback itself is a rolling update in reverse — zero downtime, same `maxSurge`/`maxUnavailable` rules apply.

### Rollback Commands

| Command | Effect |
|---------|--------|
| `kubectl rollout undo deployment/name` | Rollback to previous revision |
| `kubectl rollout undo deployment/name --to-revision=N` | Rollback to specific revision |
| `kubectl rollout history deployment/name` | View all revisions |
| `kubectl rollout history deployment/name --revision=N` | View specific revision spec |

> **Real-world context:** Rollback is one of the most critical operational capabilities in production Kubernetes. When a bad deployment reaches production — performance regression, breaking change, security issue — the first response is rollback while the team investigates. The ability to execute `kubectl rollout undo` confidently and verify the result is a core SRE skill. Every deployment pipeline should have rollback as a documented, rehearsed procedure — not something you figure out under pressure during an incident.

---

## 🔧 Solution — Step by Step

### Step 1: Check current state

```bash
kubectl get deployment nginx-deployment
kubectl describe deployment nginx-deployment | grep Image
```

### Step 2: Review rollout history

```bash
kubectl rollout history deployment/nginx-deployment
```

**Expected:**
```
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

Current is revision 2 (buggy). Rollback targets revision 1.

### Step 3: Execute rollback to previous revision

```bash
kubectl rollout undo deployment/nginx-deployment
```

**Expected:**
```
deployment.apps/nginx-deployment rolled back
```

### Step 4: Watch the rollback

```bash
kubectl rollout status deployment/nginx-deployment
```

**Expected:**
```
deployment "nginx-deployment" successfully rolled out
```

### Step 5: Verify all pods running on previous image

```bash
kubectl get pods
kubectl describe deployment nginx-deployment | grep Image
```

✅ Deployment reverted, all pods healthy.

---

## 📌 Commands Reference

```bash
# ─── Check current state ─────────────────────────────────
kubectl get deployment nginx-deployment
kubectl describe deployment nginx-deployment | grep Image
kubectl rollout history deployment/nginx-deployment

# ─── Rollback ────────────────────────────────────────────
kubectl rollout undo deployment/nginx-deployment           # Previous revision
kubectl rollout undo deployment/nginx-deployment \
  --to-revision=1                                          # Specific revision

# ─── Monitor ─────────────────────────────────────────────
kubectl rollout status deployment/nginx-deployment
kubectl get pods -w                                        # Watch pods

# ─── Verify ──────────────────────────────────────────────
kubectl get pods
kubectl describe deployment nginx-deployment | grep Image
kubectl rollout history deployment/nginx-deployment        # New revision added
```

---

## ⚠️ Common Mistakes to Avoid

1. **Not checking rollout history first** — Always run `kubectl rollout history` before `undo` to understand what you're rolling back to. In a multi-revision history, `undo` goes to the immediately previous revision, not necessarily the last stable one.
2. **Not monitoring `rollout status` after undo** — `kubectl rollout undo` returns immediately but the rollback is still in progress. Always watch status to confirm completion.
3. **Confusing rollback with delete-and-recreate** — Rollback uses the same rolling update mechanism — zero downtime. You don't need to delete the Deployment.
4. **Forgetting to investigate root cause** — Rollback is an immediate fix, not the final fix. After stabilizing production, the team must investigate and fix the bug in the code before deploying again.

---

## 🔍 Rollback Creates a New Revision

```
Before rollback:
REVISION  IMAGE
1         nginx:old
2         nginx:1.17  ← current (buggy)

After kubectl rollout undo:
REVISION  IMAGE
1         nginx:old
2         nginx:1.17
3         nginx:old   ← new revision (same as 1, but incremented)
```

The rollback isn't literally "going back" — it creates a new revision with the old configuration. This keeps the history complete and auditable.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: How does `kubectl rollout undo` work under the hood?**

When you run `kubectl rollout undo`, Kubernetes retrieves the previous ReplicaSet's Pod template (stored as part of the Deployment's revision history) and sets it as the current desired state. The Deployment controller then treats this exactly like a new update — it scales up the old ReplicaSet and scales down the current one using the same rolling update mechanism (respecting `maxSurge` and `maxUnavailable`). Importantly, the rollback creates a new revision number rather than decrementing — so if you were at revision 3 and roll back, you end up at revision 4 with the same spec as revision 2. The history always moves forward.

---

**Q2: How do you roll back to a specific revision, not just the previous one?**

`kubectl rollout undo deployment/nginx-deployment --to-revision=1` rolls back to revision 1 specifically. First run `kubectl rollout history deployment/nginx-deployment` to see available revisions and their change causes (if annotated). Then use `kubectl rollout history deployment/nginx-deployment --revision=2` to inspect the full spec of a specific revision before rolling back to it. This is critical in scenarios where the bug was introduced several releases ago — you need to identify the last known-good revision, not just go one step back.

---

**Q3: What is `revisionHistoryLimit` and why does it matter for rollbacks?**

`revisionHistoryLimit` in the Deployment spec (default: 10) controls how many old ReplicaSets are kept. Old ReplicaSets are what enable rollback — if they're garbage collected, you can't roll back to them. Setting `revisionHistoryLimit: 0` would disable rollback entirely. Setting it too low in a high-frequency deployment environment means old revisions are pruned before you need them. In production, keep at least 3-5 revisions. The trade-off is that each kept ReplicaSet consumes a small amount of API server storage. Setting it to 0 for disk savings is almost never worth losing rollback capability.

---

**Q4: What is the difference between a rollback and a new deployment with the old image?**

Functionally the result is the same — Pods running the previous image. Mechanically they're different. `kubectl rollout undo` uses the stored ReplicaSet from revision history — it's instant, requires no knowledge of the previous image tag, and uses the complete previous Pod template including all environment variables, resource limits, and volumes. Deploying a new version with the old image (`kubectl set image deployment/name container=image:old`) creates a completely new revision with a new ReplicaSet and requires you to know the exact previous image tag. In an incident, rollback is faster and safer — it doesn't require anyone to remember or look up the previous configuration.

---

**Q5: How do you know a rollback was successful?**

Three verifications: (1) `kubectl rollout status deployment/nginx-deployment` completes with "successfully rolled out" — confirms the Deployment controller finished the rollback. (2) `kubectl get pods` shows all Pods in `Running` state with correct READY count — confirms the containers are healthy. (3) `kubectl describe deployment nginx-deployment | grep Image` shows the expected previous image — confirms the right version is running. In production, you'd also verify at the application level: check your monitoring dashboards, run smoke tests against the service endpoint, and confirm error rates have returned to baseline. Infrastructure healthy doesn't always mean application healthy.

---

**Q6: Should rollback be automated or manual in a production environment?**

This is a judgment call that experienced teams debate actively. Automated rollback on failed health checks (e.g., rolling update pods never become Ready) is generally safe and valuable — it prevents a bad release from completing. Many CI/CD tools (ArgoCD, Flux) support this. However, automatically rolling back a deployment that passes health checks but causes application-level issues (wrong behavior, data corruption) requires much more sophisticated checks and carries its own risks. The industry consensus: automate rollback for infrastructure-level failures (pod crashes, health check failures), keep manual decision-making for application-level issues. Automated rollback during rollout + human-initiated rollback post-deployment is the pragmatic split.

---

## 🔗 References

- [`kubectl rollout undo`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-undo-em-)
- [Kubernetes — Rolling Back a Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)
- [Deployment Revision History](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#revision-history-limit)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
