# Day 49 — Kubernetes Deployment: Running nginx with Auto-Management

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Deployments  
**Difficulty:** Beginner  
**Phase:** Phase 4 — AWS Core Services  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create a Kubernetes Deployment on the cluster from the jump host:

- Deployment name: `nginx`
- Image: `nginx:latest`

---

## 🧠 Concept — Deployment vs Bare Pod

### Why Deployments Over Bare Pods

Yesterday (Day 48) we created a bare Pod. Today we create a Deployment — the production-grade wrapper.

| Feature | Bare Pod | Deployment |
|---------|----------|-----------|
| Auto-restart on crash | ❌ | ✅ ReplicaSet manages it |
| Reschedule on node failure | ❌ | ✅ |
| Rolling updates | ❌ | ✅ Zero downtime |
| Rollback | ❌ | ✅ `kubectl rollout undo` |
| Scaling | ❌ Manual | ✅ `kubectl scale` |
| Self-healing | ❌ | ✅ |

### The Deployment → ReplicaSet → Pod Chain

```
Deployment (nginx)
  └── ReplicaSet (nginx-abc123)        ← manages desired replica count
        └── Pod (nginx-abc123-xyz789)  ← actual running container
```

The Deployment manages ReplicaSets. ReplicaSets manage Pods. You interact with the Deployment — K8s handles the rest.

### Deployment YAML Structure

```yaml
apiVersion: apps/v1          # Deployments use apps/v1
kind: Deployment
metadata:
  name: nginx                # Deployment name
spec:
  replicas: 1                # How many Pod copies
  selector:
    matchLabels:
      app: nginx             # Which Pods this Deployment owns
  template:                  # Pod template — same as a Pod spec
    metadata:
      labels:
        app: nginx           # Must match selector.matchLabels
    spec:
      containers:
        - name: nginx
          image: nginx:latest
```

**Critical:** `selector.matchLabels` MUST match `template.metadata.labels`. This is how the Deployment identifies which Pods belong to it. A mismatch causes the Deployment to be rejected.

> **Real-world context:** Deployments are the most common Kubernetes workload resource. Every stateless application — web servers, APIs, microservices — runs as a Deployment. StatefulSets are for stateful apps (databases). DaemonSets run one Pod per node (monitoring agents). But for a standard nginx web server, Deployment is always the answer.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Access | Jump Host (kubectl pre-configured) |
| Deployment name | `nginx` |
| Image | `nginx:latest` |
| Replicas | 1 (default) |

---

## 🔧 Solution — Step by Step

### Option A: Imperative (fastest)

```bash
kubectl create deployment nginx --image=nginx:latest
```

### Option B: Declarative YAML (preferred for production)

```bash
kubectl apply -f nginx-deployment.yaml
```

### Verify the Deployment

```bash
kubectl get deployment nginx
```

**Expected:**
```
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   1/1     1            1           30s
```

### Verify the Pod was created

```bash
kubectl get pods -l app=nginx
```

**Expected:**
```
NAME                     READY   STATUS    RESTARTS   AGE
nginx-6d4cf56db6-abc12   1/1     Running   0          30s
```

### Inspect the full Deployment

```bash
kubectl describe deployment nginx
```

---

## 📌 Commands Reference

```bash
# ─── Create ──────────────────────────────────────────────
# Imperative
kubectl create deployment nginx --image=nginx:latest

# Declarative
kubectl apply -f nginx-deployment.yaml

# ─── Verify ──────────────────────────────────────────────
kubectl get deployment nginx
kubectl get pods -l app=nginx
kubectl describe deployment nginx
kubectl get replicaset                        # See the ReplicaSet

# ─── Scale ───────────────────────────────────────────────
kubectl scale deployment nginx --replicas=3
kubectl get pods -l app=nginx                 # Now 3 Pods

# ─── Update image ────────────────────────────────────────
kubectl set image deployment/nginx nginx=nginx:1.25
kubectl rollout status deployment/nginx       # Watch rollout

# ─── Rollback ────────────────────────────────────────────
kubectl rollout undo deployment/nginx
kubectl rollout history deployment/nginx      # See history

# ─── Cleanup ─────────────────────────────────────────────
kubectl delete deployment nginx
```

---

## ⚠️ Common Mistakes to Avoid

1. **`selector.matchLabels` not matching `template.metadata.labels`** — Kubernetes rejects the Deployment. They must be identical.
2. **Using `v1` instead of `apps/v1`** — Pods use `apiVersion: v1`. Deployments use `apiVersion: apps/v1`. Wrong API version causes a validation error.
3. **Forgetting the `template` section** — The Pod spec lives under `spec.template`. Putting containers directly under `spec` fails.
4. **Skipping `nginx:latest` tag** — Task requires explicit tag. Always specify tags in production to avoid unexpected image updates.

---

## 🔍 What Happens When You `kubectl apply` a Deployment

```
kubectl apply -f nginx-deployment.yaml
        │
        ▼
Kubernetes API Server validates the manifest
        │
        ▼
Deployment Controller creates a ReplicaSet
        │
        ▼
ReplicaSet Controller creates 1 Pod (replicas: 1)
        │
        ▼
Scheduler assigns Pod to a node
        │
        ▼
Kubelet on the node pulls nginx:latest and starts the container
        │
        ▼
Pod status → Running ✅
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between a Deployment and a ReplicaSet?**

A ReplicaSet ensures a specified number of identical Pod replicas are running at any time — if a Pod dies, the ReplicaSet creates a new one. A Deployment is a higher-level abstraction that manages ReplicaSets. When you update a Deployment (e.g., change the image version), it creates a new ReplicaSet with the new configuration and gradually scales it up while scaling down the old one — this is a rolling update. The old ReplicaSet is kept (scaled to 0) to enable rollbacks. You should almost never create a ReplicaSet directly — always use a Deployment which gives you rolling updates and rollback on top of replica management.

---

**Q2: How does a Kubernetes rolling update work?**

When you update a Deployment's Pod template (e.g., `kubectl set image`), Kubernetes creates a new ReplicaSet with the new image. It then gradually terminates old Pods and creates new ones according to two parameters: `maxSurge` (how many extra Pods can exist during the update — default 25%) and `maxUnavailable` (how many Pods can be unavailable during the update — default 25%). For a 4-replica Deployment, it might bring up 1 new Pod, then terminate 1 old Pod, repeatedly until all Pods are updated. The application stays available throughout — zero downtime. `kubectl rollout status deployment/nginx` watches the progress in real time.

---

**Q3: How do you roll back a Kubernetes Deployment?**

`kubectl rollout undo deployment/nginx` reverts to the previous ReplicaSet — the one that was scaled to 0 but kept for exactly this purpose. `kubectl rollout undo deployment/nginx --to-revision=2` rolls back to a specific revision. `kubectl rollout history deployment/nginx` shows all revisions with their change-cause annotations. The rollback itself is another rolling update — Kubernetes scales up the old ReplicaSet and scales down the current one. This makes rollbacks safe and zero-downtime, identical to a forward update.

---

**Q4: What is the significance of `selector.matchLabels` in a Deployment?**

`selector.matchLabels` defines which Pods the Deployment considers its own. When the Deployment needs to scale up, it creates new Pods with the labels defined in `template.metadata.labels`. When it needs to scale down or during rolling updates, it identifies Pods to terminate using `matchLabels`. If `matchLabels` doesn't match `template.metadata.labels`, Kubernetes rejects the Deployment with a validation error — the Deployment would be unable to manage any Pods. This selector is also immutable after creation — you cannot change it without deleting and recreating the Deployment.

---

**Q5: How would you expose a Deployment to external traffic?**

A Deployment manages Pods but doesn't expose them externally. You need a Service resource. `kubectl expose deployment nginx --port=80 --type=NodePort` creates a Service that routes traffic from a random port on each node to the Deployment's Pods. For production, `--type=LoadBalancer` creates a cloud load balancer (on AWS, this provisions an ELB). `--type=ClusterIP` (default) makes the service reachable only within the cluster. The Service uses the same label selector as the Deployment to find its target Pods — this is why labels are operational infrastructure, not just metadata.

---

**Q6: What is the difference between `kubectl apply` and `kubectl create deployment`?**

`kubectl create deployment nginx --image=nginx:latest` is imperative — it creates the Deployment with minimal configuration and doesn't support complex specs like resource limits, environment variables, or volume mounts without additional flags. It fails if the Deployment already exists. `kubectl apply -f deployment.yaml` is declarative — you define the full desired state in YAML (all containers, resources, env vars, strategy) and Kubernetes reconciles reality to match it. If the Deployment already exists, `apply` updates it. For anything beyond the simplest deployments, YAML with `apply` is the correct approach — it's reviewable, version-controlled, and repeatable.

---

## 🔗 References

- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Rolling Updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
