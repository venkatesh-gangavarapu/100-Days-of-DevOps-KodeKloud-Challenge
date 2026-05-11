# Day 56 — Kubernetes Deployment + NodePort Service: Scalable nginx

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Deployments / Services  
**Difficulty:** Intermediate  
**Phase:** Phase 4 — AWS Core Services  
**Status:** ✅ Completed

---

## 📋 Task Summary

Deploy a highly available, scalable nginx setup:

1. **Deployment** `nginx-deployment` — 3 replicas, container `nginx-container`, image `nginx:latest`
2. **Service** `nginx-service` — NodePort type, nodePort `30011`

---

## 🧠 Concept — Services & How They Connect to Deployments

### The Problem Services Solve

Pods are ephemeral — they get new IP addresses every time they're recreated. With 3 replicas, you have 3 different IPs that change over time. Services provide a stable virtual IP and DNS name that load balances across matching Pods — regardless of how many exist or what their IPs are.

```
External traffic
      │
      ▼
NodePort (30011) on any node
      │
      ▼
Service: nginx-service (ClusterIP: 10.96.x.x:80)
      │  [label selector: app=nginx-deployment]
      ├──► Pod 1 (10.244.1.2:80)
      ├──► Pod 2 (10.244.1.3:80)
      └──► Pod 3 (10.244.2.1:80)
```

### Service Types

| Type | Accessible from | Use case |
|------|----------------|---------|
| `ClusterIP` | Within cluster only | Internal microservices |
| `NodePort` | Outside via node IP:port | Dev, labs, bare metal |
| `LoadBalancer` | External LB (cloud) | Production cloud |

### NodePort Port Mapping

```
nodePort: 30011    ← External port on every node
port: 80           ← Service's cluster-internal port
targetPort: 80     ← Container's listening port
```

### Label Selector — The Glue

The Service uses `spec.selector` to find Pods — NOT Deployment name, NOT Pod name.

```yaml
# Deployment gives Pods this label:
labels:
  app: nginx-deployment

# Service routes to Pods matching this:
selector:
  app: nginx-deployment   ← must match exactly
```

> **Real-world context:** Deployment + Service is the fundamental building block of Kubernetes application deployment. In production on cloud platforms, NodePort becomes LoadBalancer which provisions an AWS ELB, GCP LB, or Azure LB automatically.

---

## 🔧 The Manifests

### nginx-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-deployment
  template:
    metadata:
      labels:
        app: nginx-deployment
    spec:
      containers:
        - name: nginx-container
          image: nginx:latest
```

### nginx-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx-deployment
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30011
```

---

## 🔧 Solution — Step by Step

### Step 1: Apply both manifests

```bash
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml
```

### Step 2: Verify Deployment (3/3 ready)

```bash
kubectl get deployment nginx-deployment
# NAME               READY   UP-TO-DATE   AVAILABLE
# nginx-deployment   3/3     3            3         ✅
```

### Step 3: Verify 3 Pods running

```bash
kubectl get pods -l app=nginx-deployment
# 3 pods, all Running ✅
```

### Step 4: Verify Service

```bash
kubectl get service nginx-service
# TYPE: NodePort, PORT(S): 80:30011/TCP ✅
```

### Step 5: Verify endpoints (Pods registered)

```bash
kubectl get endpoints nginx-service
# 3 Pod IPs listed ✅
```

### Step 6: Test

```bash
curl http://localhost:30011
# nginx welcome page ✅
```

---

## 📌 Commands Reference

```bash
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml
kubectl get deployment nginx-deployment
kubectl get pods -l app=nginx-deployment
kubectl get service nginx-service
kubectl get endpoints nginx-service
curl http://localhost:30011
kubectl scale deployment nginx-deployment --replicas=5
kubectl delete deployment nginx-deployment
kubectl delete service nginx-service
```

---

## ⚠️ Common Mistakes to Avoid

1. **Label mismatch between Deployment and Service** — selector must match exactly or Service has no endpoints.
2. **NodePort outside 30000-32767 range** — rejected with validation error.
3. **Forgetting `replicas: 3`** — defaults to 1 without explicit value.
4. **Confusing port/targetPort/nodePort** — three different concepts, all required for correct traffic flow.
5. **Not checking `kubectl get endpoints`** — a Service with no endpoints means selector doesn't match any Pods.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between ClusterIP, NodePort, and LoadBalancer service types?**

`ClusterIP` (default) creates a virtual IP accessible only within the cluster — for internal service-to-service communication. `NodePort` exposes the service on a static port (30000-32767) on every node — accessible from outside but requires knowing a node IP. `LoadBalancer` extends NodePort by provisioning an external load balancer (AWS ELB, GCP LB) with a public IP. In production cloud environments, `LoadBalancer` handles external traffic; `ClusterIP` handles internal microservice communication. NodePort is mainly used in labs and bare-metal clusters.

---

**Q2: How does a Kubernetes Service know which Pods to route traffic to?**

Services use label selectors — not Pod names, Deployment names, or IPs. `spec.selector` defines which labels a Pod must have. Kubernetes continuously watches for matching Pods and updates the Endpoints object. When a Pod is created matching the selector, it's added to the routing pool automatically. When a Pod dies, it's removed. `kubectl get endpoints service-name` shows the current Pod IPs registered. This dynamic routing is why Pod IP changes don't break Services.

---

**Q3: What is the difference between `port`, `targetPort`, and `nodePort`?**

`nodePort` (30011) is the port on every node's IP — external traffic entry point. `port` (80) is the Service's cluster-internal port — used by other cluster services via ClusterIP. `targetPort` (80) is the port on the actual container receiving traffic. The chain: external → nodePort:30011 → Service:port:80 → Pod:targetPort:80. If `targetPort` is omitted, it defaults to `port`.

---

**Q4: How does kube-proxy implement Service routing?**

`kube-proxy` runs on every node and watches the Kubernetes API for Service and Endpoints changes. It programs iptables (or IPVS) rules that perform NAT — translating the Service's virtual ClusterIP to a backing Pod IP. For NodePort, additional rules redirect the node port to the ClusterIP. IPVS mode is preferred over iptables in large clusters (thousands of Services) for better performance. Service routing happens at the kernel level — extremely fast, minimal latency.

---

**Q5: What happens to traffic during a rolling update with some old and new Pods?**

The Service routes to all Ready Pods — both old and new versions simultaneously. For stateless apps (static websites), this is fine. For APIs where request/response format changes between versions, requests may get inconsistent responses depending on which Pod handles them. This is why backward-compatible changes are critical, and why blue-green or canary deployments are used for breaking changes.

---

**Q6: How would you make this production-ready beyond 3 replicas?**

Several additions: resource requests/limits (prevent OOMKill), liveness/readiness probes (removes unhealthy Pods from Service routing), PodDisruptionBudget (maintain minimum replicas during maintenance), HorizontalPodAutoscaler (auto-scale on CPU/memory), anti-affinity rules (spread Pods across nodes), switch to LoadBalancer type in cloud environments, and add nginx ConfigMap for proper configuration.

---

## 🔗 References

- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [NodePort Services](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
