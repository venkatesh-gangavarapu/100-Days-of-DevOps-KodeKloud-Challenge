# Day 50 — Kubernetes Resource Management: Requests & Limits

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Resource Management  
**Difficulty:** Beginner–Intermediate  
**Phase:** Phase 4 — AWS Core Services  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create a Pod with explicit resource constraints on the jump host:

- Pod name: `httpd-pod`
- Container name: `httpd-container`
- Image: `httpd:latest`
- Requests: Memory `15Mi`, CPU `100m`
- Limits: Memory `20Mi`, CPU `100m`

---

## 🧠 Concept — Resource Requests & Limits

### What are Requests and Limits?

```
resources:
  requests:          ← "I need at least this much"
    memory: "15Mi"   ← used by scheduler to find a suitable node
    cpu: "100m"
  limits:            ← "I am allowed at most this much"
    memory: "20Mi"   ← enforced at runtime by the kernel
    cpu: "100m"
```

| Field | Role | Enforcement |
|-------|------|-------------|
| `requests` | Scheduling hint — minimum guaranteed | Used by scheduler only |
| `limits` | Hard cap — maximum allowed | Enforced by kernel cgroups |

### CPU Units — Millicores

```
100m  = 0.1 CPU core (100 millicores)
500m  = 0.5 CPU core
1000m = 1 full CPU core
1     = 1 full CPU core (same as 1000m)
```

CPU is **compressible** — if a container exceeds its CPU limit, it gets throttled (slowed down) but not killed.

### Memory Units

```
15Mi  = 15 Mebibytes (1 Mi = 1,048,576 bytes)
15M   = 15 Megabytes  (1 M  = 1,000,000 bytes)
1Gi   = 1 Gibibyte
```

Memory is **incompressible** — if a container exceeds its memory limit, the kernel kills it with OOMKilled (Out Of Memory). This shows as `OOMKilled` in `kubectl describe pod`.

### Why Both Requests AND Limits Matter

```
Requests too low  → Pod scheduled on node that can't handle it → OOMKilled
Limits too low    → App legitimately needs more → OOMKilled
Limits too high   → Node can be overcommitted → other Pods affected
No limits at all  → One runaway container can starve the entire node
```

Setting both correctly is the key to stable, predictable cluster behavior.

### QoS Classes — What Kubernetes Assigns Based on Resources

| QoS Class | Condition | Eviction priority |
|-----------|-----------|------------------|
| `Guaranteed` | requests == limits for all containers | Last to be evicted |
| `Burstable` | requests set but != limits | Middle |
| `BestEffort` | No requests or limits | First to be evicted |

This Pod has requests ≠ limits → **Burstable** QoS class.

> **Real-world context:** Resource limits are mandatory in production Kubernetes clusters. Without them, a single poorly-written container can consume all node memory and cause cascading failures across every Pod on that node. SRE teams enforce resource quotas at the namespace level (`ResourceQuota`) to prevent any single team from consuming disproportionate cluster resources. Setting appropriate requests and limits — based on actual profiling — is one of the most impactful things you can do for cluster stability.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Access | Jump Host (kubectl pre-configured) |
| Pod name | `httpd-pod` |
| Container name | `httpd-container` |
| Image | `httpd:latest` |
| Memory request | `15Mi` |
| CPU request | `100m` |
| Memory limit | `20Mi` |
| CPU limit | `100m` |

---

## 🔧 Solution — Step by Step

### Step 1: Create the Pod manifest

```yaml
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
```

### Step 2: Apply the manifest

```bash
kubectl apply -f httpd-pod.yaml
```

### Step 3: Verify pod is running

```bash
kubectl get pod httpd-pod
```

**Expected:**
```
NAME        READY   STATUS    RESTARTS   AGE
httpd-pod   1/1     Running   0          30s
```

### Step 4: Verify resource limits are set correctly

```bash
kubectl describe pod httpd-pod | grep -A 6 "Limits\|Requests"
```

**Expected:**
```
    Limits:
      cpu:     100m
      memory:  20Mi
    Requests:
      cpu:     100m
      memory:  15Mi
```

### Step 5: Check QoS class

```bash
kubectl get pod httpd-pod -o jsonpath='{.status.qosClass}'
# Expected: Burstable
```

---

## 📌 Commands Reference

```bash
# ─── Apply ───────────────────────────────────────────────
kubectl apply -f httpd-pod.yaml

# ─── Verify ──────────────────────────────────────────────
kubectl get pod httpd-pod
kubectl describe pod httpd-pod
kubectl describe pod httpd-pod | grep -A 6 "Limits\|Requests"
kubectl get pod httpd-pod -o jsonpath='{.status.qosClass}'

# ─── Resource usage (metrics-server required) ────────────
kubectl top pod httpd-pod

# ─── Full spec output ────────────────────────────────────
kubectl get pod httpd-pod -o yaml

# ─── Cleanup ─────────────────────────────────────────────
kubectl delete pod httpd-pod
```

---

## ⚠️ Common Mistakes to Avoid

1. **Request > Limit** — Kubernetes rejects this. Requests must always be ≤ limits.
2. **Wrong memory unit** — `15Mi` (mebibytes) ≠ `15M` (megabytes). Use `Mi` and `Gi` for binary units as Kubernetes expects.
3. **Setting limits without requests** — Kubernetes defaults requests to equal limits if only limits are set. Intentional in some cases but understand the behavior.
4. **CPU limit too low** — The container gets throttled even when CPU is available on the node. Symptoms: slow response times, timeouts. Not immediately obvious from logs.
5. **No limits in production** — A container with no memory limit can grow unbounded and trigger OOMKill on other Pods sharing the node.

---

## 🔍 Resource Enforcement Diagram

```
Node has 2 CPU, 4Gi RAM

Pod A: requests 100m CPU, 15Mi RAM | limits 100m CPU, 20Mi RAM
Pod B: requests 500m CPU, 1Gi RAM  | limits 1000m CPU, 2Gi RAM

Scheduler sees:
  Available for scheduling: 2000m - 100m - 500m = 1400m CPU
                            4096Mi - 15Mi - 1Gi = ~3081Mi RAM

At runtime:
  Pod A uses 150m CPU → throttled to 100m (CPU limit enforced)
  Pod A uses 22Mi RAM → OOMKilled (memory limit exceeded)
  Pod B uses 800m CPU → throttled to 1000m limit (fine)
  Pod B uses 1.5Gi RAM → fine (within 2Gi limit)
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between resource requests and resource limits in Kubernetes?**

Requests define the minimum resources a container needs and are used by the Kubernetes scheduler to decide which node to place the Pod on — the node must have at least this much unallocated capacity. Limits define the maximum a container can use at runtime and are enforced by the Linux kernel's cgroups. If a container exceeds its CPU limit, it gets throttled. If it exceeds its memory limit, the process is killed with OOMKilled. Requests affect scheduling; limits affect runtime behavior. Setting requests without limits means the container can burst to consume all available node resources — dangerous in shared clusters.

---

**Q2: What happens when a container exceeds its memory limit in Kubernetes?**

The Linux kernel's Out Of Memory (OOM) killer terminates the container process. In Kubernetes, this appears as `OOMKilled` in `kubectl describe pod` under the container's `Last State` section, and the `Reason` field shows `OOMKilled`. The Pod's restart count increments. If `restartPolicy` is `Always` (default), Kubernetes restarts the container. If it keeps OOMKilling, it enters `CrashLoopBackOff`. The fix is either increasing the memory limit or profiling and fixing the memory leak/excess usage in the application.

---

**Q3: What are Kubernetes QoS classes and how are they determined?**

Kubernetes assigns one of three Quality of Service classes to each Pod based on its resource configuration. `Guaranteed`: every container in the Pod has both requests and limits set, and they're equal — these Pods are the last to be evicted under node pressure. `Burstable`: at least one container has requests or limits set, but they're not equal — evicted after BestEffort. `BestEffort`: no containers have any requests or limits — first to be evicted when a node runs out of resources. QoS class directly determines eviction order, making it a critical operational concept for cluster stability under resource pressure.

---

**Q4: What is `100m` CPU and how does Kubernetes enforce CPU limits?**

`100m` means 100 millicores, or 0.1 of a single CPU core. Kubernetes enforces CPU limits using the Linux kernel's CPU bandwidth controller (cgroups v2 `cpu.max`). When a container exceeds its CPU limit, it doesn't get killed — it gets throttled. The kernel limits how much CPU time the container's processes can consume per period. This is invisible to the application — it just runs slower. CPU throttling is a common performance issue that's hard to diagnose because the container stays running and appears healthy. `kubectl top pod` shows actual CPU usage; if it's consistently at the limit, the limit needs to be raised.

---

**Q5: What is a ResourceQuota and how does it relate to container resource limits?**

A ResourceQuota is a cluster-level or namespace-level policy that limits total resource consumption across all objects in a namespace. It can enforce things like "this namespace can use at most 4 CPU cores and 8Gi of RAM total" or "this namespace can have at most 10 Pods". If a namespace has a ResourceQuota with `limits.memory`, every Pod in that namespace must specify memory limits — otherwise the Pod creation is rejected. ResourceQuotas are how cluster administrators prevent any single team from monopolizing cluster resources. Container-level requests and limits feed into namespace-level quotas.

---

**Q6: How do you determine appropriate resource requests and limits for a new application?**

Start by running the application under realistic load without limits and measuring actual usage with `kubectl top pods` (requires metrics-server) or Prometheus. Observe peak and average CPU and memory over time. Set requests to the average usage (what the app needs to function normally) and limits to the peak plus a safety margin (typically 25-50% above peak for memory). For CPU, set limits more generously since throttling degrades performance silently. In production, use Vertical Pod Autoscaler (VPA) in recommendation mode — it analyzes actual usage over time and suggests optimal requests and limits. Never guess resource values; measure first.

---

## 🔗 References

- [Kubernetes — Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Kubernetes — QoS Classes](https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/)
- [Kubernetes — LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range/)
- [CPU Throttling in Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
