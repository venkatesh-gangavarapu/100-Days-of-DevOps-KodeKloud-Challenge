# Day 48 — First Kubernetes Pod: Deploying nginx with Labels & Container Config

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Pod Management  
**Difficulty:** Beginner  
**Phase:** Phase 4 — AWS Core Services  
**Status:** ✅ Completed

---

## 📋 Task Summary

First Kubernetes task! Create a pod on the cluster from the jump host:

- Pod name: `pod-nginx`
- Image: `nginx:latest`
- Label: `app=nginx_app`
- Container name: `nginx-container`

---

## 🧠 Concept — Kubernetes Pods

### What is a Pod?

A Pod is the **smallest deployable unit in Kubernetes**. It's a wrapper around one or more containers that share:
- The same **network namespace** (same IP address, same ports)
- The same **storage volumes**
- The same **lifecycle** (start together, stop together)

```
Kubernetes Node
  └── Pod: pod-nginx
        ├── IP: 10.244.x.x (shared by all containers in pod)
        └── Container: nginx-container
              └── Image: nginx:latest
```

In most cases, a Pod runs a single container. Multi-container pods are used for sidecar patterns (log shippers, proxies, init containers).

### Pod Manifest Structure

```yaml
apiVersion: v1          # Kubernetes API version for core resources
kind: Pod               # Resource type
metadata:
  name: pod-nginx       # Pod name — unique within namespace
  labels:               # Key-value pairs for selection and organization
    app: nginx_app
spec:                   # Desired state
  containers:           # List of containers in the pod
    - name: nginx-container   # Container name
      image: nginx:latest     # Image:tag
```

### Why Labels Matter

Labels are key-value pairs attached to Kubernetes objects. They enable:
- **Selection** — Services use label selectors to find which pods to route traffic to
- **Filtering** — `kubectl get pods -l app=nginx_app`
- **Organization** — Group related resources across a cluster

Without labels, Services can't find your Pods. This is why labels are defined at creation time — they're not just metadata, they're the glue that connects Kubernetes resources.

### Imperative vs Declarative

| Approach | Command | Best for |
|----------|---------|---------|
| Imperative | `kubectl run pod-nginx --image=nginx:latest` | Quick testing |
| Declarative | `kubectl apply -f pod.yaml` | Production, version control |

The YAML approach is always preferred in production because it's reproducible, reviewable, and version-controllable. The imperative approach is useful for quick tests and generating YAML templates.

> **Real-world context:** Kubernetes is the standard platform for running containerized applications at scale. While individual Pods are rarely used directly in production (Deployments manage pods instead), understanding Pod structure is the foundation for everything in Kubernetes — Deployments, StatefulSets, DaemonSets all define pod templates with the same spec format. Every Kubernetes engineer starts here.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Access | Jump host → kubectl |
| Pod name | `pod-nginx` |
| Label | `app=nginx_app` |
| Container | `nginx-container` |
| Image | `nginx:latest` |

---

## 🔧 Solution — Step by Step

### Step 1: Verify cluster access from jump host

```bash
kubectl get nodes
```

**Expected:**
```
NAME      STATUS   ROLES           AGE   VERSION
node01    Ready    control-plane   Xd    v1.xx.x
```

### Step 2: Create the pod manifest

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pod-nginx
  labels:
    app: nginx_app
spec:
  containers:
    - name: nginx-container
      image: nginx:latest
EOF
```

**Or save to file and apply:**
```bash
kubectl apply -f pod-nginx.yaml
```

**Expected:**
```
pod/pod-nginx created
```

### Step 3: Verify pod is running

```bash
kubectl get pod pod-nginx
```

**Expected:**
```
NAME        READY   STATUS    RESTARTS   AGE
pod-nginx   1/1     Running   0          30s
```

`1/1` — 1 container ready out of 1 total. ✅

### Step 4: Full pod description

```bash
kubectl describe pod pod-nginx
```

Key fields to verify:
```
Name:         pod-nginx
Labels:       app=nginx_app
Containers:
  nginx-container:
    Image:    nginx:latest
    State:    Running
```

### Step 5: Filter pods by label

```bash
kubectl get pods -l app=nginx_app
```

**Expected:** `pod-nginx` listed — confirms label is applied correctly. ✅

---

## 📌 Commands Reference

```bash
# ─── Cluster verification ────────────────────────────────
kubectl get nodes
kubectl cluster-info

# ─── Create pod ──────────────────────────────────────────
kubectl apply -f pod-nginx.yaml
# OR imperative:
kubectl run pod-nginx \
  --image=nginx:latest \
  --labels="app=nginx_app" \
  --restart=Never

# ─── Inspect pod ─────────────────────────────────────────
kubectl get pods
kubectl get pod pod-nginx
kubectl get pod pod-nginx -o yaml        # Full YAML output
kubectl get pod pod-nginx -o wide        # With node and IP
kubectl describe pod pod-nginx           # Human-readable details

# ─── Filter by label ─────────────────────────────────────
kubectl get pods -l app=nginx_app

# ─── Logs and exec ───────────────────────────────────────
kubectl logs pod-nginx
kubectl logs pod-nginx -c nginx-container  # Specific container
kubectl exec -it pod-nginx -- /bin/bash    # Shell into pod
kubectl exec -it pod-nginx -c nginx-container -- /bin/bash

# ─── Cleanup ─────────────────────────────────────────────
kubectl delete pod pod-nginx
kubectl delete -f pod-nginx.yaml
```

---

## ⚠️ Common Mistakes to Avoid

1. **Forgetting `nginx:latest` tag** — The task specifies the tag must be explicit: `nginx:latest` not just `nginx`. Always specify tags in production to avoid ambiguity.
2. **Label key-value syntax** — Labels use `app: nginx_app` (with space in YAML), not `app=nginx_app` (= is for kubectl selectors on the command line).
3. **Container name vs pod name** — `metadata.name` is the pod name (`pod-nginx`). `spec.containers[].name` is the container name (`nginx-container`). These are different fields.
4. **`kubectl run` for complex pods** — The imperative `kubectl run` is fine for simple pods but doesn't easily support labels on the container, resource limits, or multiple containers. YAML is always cleaner.
5. **Not verifying STATUS is Running** — `Pending` means the image is being pulled or no node can schedule it. `CrashLoopBackOff` means the container is starting and crashing repeatedly. Always confirm `Running` before finishing.

---

## 🔍 Kubernetes Resource Hierarchy

```
Cluster
  └── Namespace (default)
        └── Pod: pod-nginx
              ├── Metadata
              │   ├── name: pod-nginx
              │   └── labels: app=nginx_app
              └── Spec
                    └── Container: nginx-container
                          └── Image: nginx:latest
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is a Kubernetes Pod and how does it differ from a Docker container?**

A Docker container is a single isolated process with its own filesystem and network namespace. A Kubernetes Pod is a higher-level abstraction that wraps one or more containers that share a network namespace (same IP, same ports) and can share storage volumes. In practice, most Pods run a single container — the multi-container pattern is used for sidecars (a log shipper alongside the app), init containers (setup tasks before the main container starts), or ambassador patterns (a proxy container). The Pod is Kubernetes' atom — the smallest schedulable unit. You can't run a container in Kubernetes without it being inside a Pod.

---

**Q2: Why are labels important in Kubernetes and how are they used?**

Labels are key-value pairs attached to Kubernetes objects that serve as the primary mechanism for object selection and grouping. A Service uses a label selector to decide which Pods to route traffic to — without matching labels, Services send traffic nowhere. A Deployment uses label selectors to identify which Pods it manages. `kubectl` commands use `-l app=nginx_app` to filter resources. In production, standard labeling conventions include `app`, `version`, `environment`, and `tier` — making it possible to query "all production pods for the web tier of the payments app" with a single selector. Labels are metadata that drive behavior, not just documentation.

---

**Q3: What is the difference between `kubectl apply` and `kubectl create`?**

`kubectl create` creates a resource but fails if it already exists. `kubectl apply` creates the resource if it doesn't exist, or updates it if it does — making it idempotent. In practice, always use `kubectl apply` — it's safe to run multiple times and supports the declarative GitOps workflow where manifests are reapplied whenever they change. `kubectl create` is useful for one-time resource creation where you explicitly want it to fail if the resource exists (to prevent accidental overwrites). In CI/CD pipelines, `kubectl apply` is the standard.

---

**Q4: What happens to a Pod when the node it's running on fails?**

A bare Pod (created directly, not managed by a controller) is **not rescheduled** if its node fails — it's gone. This is why bare Pods are almost never used in production. A Deployment (which creates a ReplicaSet that manages Pods) will automatically create a replacement Pod on a healthy node when the original Pod is lost. This is the key reason production workloads use Deployments: they provide self-healing. StatefulSets provide the same for stateful applications. The Pod spec you write is the same in both cases — the Deployment just wraps it with management logic.

---

**Q5: How do you check why a Pod is not in Running state?**

`kubectl describe pod pod-name` is the first command — it shows events at the bottom of the output that explain what happened: image pull errors, node scheduling failures, OOM kills, liveness probe failures. For a Pod in `CrashLoopBackOff`, `kubectl logs pod-name` (or `kubectl logs pod-name --previous` for the previous crash) shows the application's output before it crashed. For `Pending` state, the events section shows whether it's waiting for image pull, resource constraints, or no schedulable node. These three commands — `get`, `describe`, `logs` — cover 95% of pod debugging scenarios.

---

**Q6: What is the difference between a Pod, ReplicaSet, and Deployment in Kubernetes?**

A **Pod** is a single instance of running containers — no self-healing, no scaling. A **ReplicaSet** ensures a specified number of identical Pod replicas are always running — if one Pod dies, the ReplicaSet creates a replacement. But ReplicaSets don't support rolling updates. A **Deployment** manages ReplicaSets and adds rolling update capability — when you update the image, it creates a new ReplicaSet with the new version, scales it up while scaling down the old one, enabling zero-downtime deployments. In practice: never create bare Pods or ReplicaSets for production workloads — always use Deployments (stateless apps) or StatefulSets (stateful apps like databases).

---

## 🔗 References

- [Kubernetes — Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- [kubectl apply vs create](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
