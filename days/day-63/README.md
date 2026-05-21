# Day 63 — Multi-Tier Kubernetes App: Iron Gallery + MariaDB in Dedicated Namespace

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Multi-Tier Apps / Namespaces  
**Difficulty:** Advanced  
**Phase:** Phase 5 — Advanced Kubernetes & CI/CD  
**Status:** ✅ Completed

---

## 📋 Task Summary

Deploy a complete multi-tier application in namespace `iron-namespace-devops`:

| Resource | Name | Details |
|----------|------|---------|
| Namespace | `iron-namespace-devops` | Isolates all resources |
| Deployment | `iron-gallery-deployment-devops` | `kodekloud/irongallery:2.0`, 1 replica, 2 emptyDir volumes |
| Deployment | `iron-db-deployment-devops` | `kodekloud/irondb:2.0`, 1 replica, MariaDB env vars |
| Service | `iron-gallery-service-devops` | NodePort `32678` → port `80` |
| Service | `iron-db-service-devops` | ClusterIP port `3306` |

---

## 🧠 Concept — Namespaces & Multi-Tier Architecture

### What is a Kubernetes Namespace?

A namespace is a logical partition within a cluster — resources in different namespaces are isolated from each other, have separate RBAC, and can have separate resource quotas.

```
Cluster
  ├── default (namespace)           ← kubectl default target
  ├── kube-system (namespace)       ← Kubernetes components
  ├── kube-public (namespace)       ← public cluster info
  └── iron-namespace-devops         ← today's app isolation
        ├── iron-gallery-deployment-devops
        ├── iron-db-deployment-devops
        ├── iron-gallery-service-devops (NodePort 32678)
        └── iron-db-service-devops (ClusterIP 3306)
```

### Why Use Namespaces?

| Reason | Example |
|--------|---------|
| Environment separation | `dev`, `staging`, `production` namespaces |
| Team isolation | `team-frontend`, `team-backend` namespaces |
| App isolation | `iron-namespace-devops` today |
| Resource quotas | Limit CPU/memory per namespace |
| RBAC boundaries | Dev team can only access `dev` namespace |

### Multi-Tier Architecture Pattern

```
External User
      │
      ▼
NodePort:32678 → iron-gallery-service-devops
      │
      ▼
iron-gallery-deployment (nginx frontend)
      │ connects to DB via service DNS
      ▼
iron-db-service-devops (ClusterIP:3306) — internal only
      │
      ▼
iron-db-deployment (MariaDB)
```

**Key:** The DB service is `ClusterIP` — accessible only within the cluster. The gallery service is `NodePort` — accessible externally. This is the correct security model: expose only what needs to be public.

### DNS Between Services in Same Namespace

Within `iron-namespace-devops`, the gallery app connects to the DB using the service name:
```
Host: iron-db-service-devops
Port: 3306
```

Kubernetes DNS resolves `iron-db-service-devops` to its ClusterIP automatically within the same namespace.

### Resource Limits on the Gallery Container

```yaml
resources:
  limits:
    memory: "100Mi"
    cpu: "50m"
```

`50m` = 50 millicores = 0.05 CPU. Tight limit for a gallery app — but fine for a lab. In production, profile actual usage first.

> **Real-world context:** This architecture pattern — frontend Deployment with NodePort, backend Deployment with ClusterIP, all in a dedicated namespace — is how every production multi-tier application is structured on Kubernetes. The namespace provides isolation, the ClusterIP service provides internal-only database access, and the NodePort (or LoadBalancer/Ingress in production) provides external access to the frontend only.

---

## 🔧 Solution — Step by Step

### Apply entire stack

```bash
kubectl apply -f iron-stack.yaml
```

All 5 resources created in order: Namespace → Deployments → Services.

### Verify everything

```bash
kubectl get all -n iron-namespace-devops
```

**Expected:**
```
NAME                                                READY   STATUS    RESTARTS
pod/iron-gallery-deployment-devops-xxx-yyy          1/1     Running   0
pod/iron-db-deployment-devops-xxx-yyy               1/1     Running   0

NAME                                 TYPE        PORT(S)
iron-db-service-devops               ClusterIP   3306/TCP
iron-gallery-service-devops          NodePort    80:32678/TCP

NAME                                             READY   UP-TO-DATE
iron-gallery-deployment-devops                   1/1     1
iron-db-deployment-devops                        1/1     1
```

### Test

```bash
curl http://localhost:32678
# Iron Gallery page ✅
```

---

## 📌 Commands Reference

```bash
# Deploy everything
kubectl apply -f iron-stack.yaml

# Verify (note: -n flag required for non-default namespace)
kubectl get all -n iron-namespace-devops
kubectl get pods -n iron-namespace-devops
kubectl get svc -n iron-namespace-devops
kubectl get endpoints -n iron-namespace-devops

# Test app
curl http://localhost:32678

# Debug pods if needed
kubectl describe pod <pod-name> -n iron-namespace-devops
kubectl logs <pod-name> -n iron-namespace-devops

# Cleanup
kubectl delete namespace iron-namespace-devops
# This deletes ALL resources in the namespace in one command
```

---

## ⚠️ Common Mistakes to Avoid

1. **Forgetting `-n iron-namespace-devops` in every kubectl command** — Resources in non-default namespaces are invisible without the `-n` flag. `kubectl get pods` shows nothing; `kubectl get pods -n iron-namespace-devops` shows everything.
2. **Label key mismatch** — Gallery uses `run: iron-gallery`, DB uses `db: mariadb`. These are different label keys, not both `app:`. The Service selector must use the matching key-value pair.
3. **Missing namespace in manifest** — Every resource manifest must include `namespace: iron-namespace-devops` under `metadata`. Without it, resources are created in `default`.
4. **Wrong resource limit format** — `"50m"` for CPU (millicores) and `"100Mi"` for memory. `"50"` CPU means 50 full cores, not 50 millicores.
5. **Creating resources before namespace exists** — The namespace must be created first. In a single YAML with `---` separators, order matters — Namespace must be first.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is a Kubernetes namespace and when should you use separate namespaces?**

A namespace is a virtual cluster within a physical cluster — it provides scope for resource names, separate RBAC policies, and network policies. Use separate namespaces for: environment separation (dev/staging/prod in the same cluster), team isolation (frontend team, backend team, data team each with their own namespace), application isolation (each microservice team owns their namespace), and resource quota enforcement (limit how much CPU/memory a team can consume). The default namespace is fine for learning but always use named namespaces for anything beyond simple experimentation.

---

**Q2: Why use ClusterIP for the database service instead of NodePort?**

`ClusterIP` makes the service accessible only within the cluster — no external traffic can reach the database directly. `NodePort` would expose the database on a port on every node, making it potentially reachable from outside the cluster. Databases should never be directly exposed externally. The gallery app connects to the DB using the service's DNS name (`iron-db-service-devops`) within the cluster, which resolves to the ClusterIP. External users only reach the gallery frontend via NodePort 32678. This principle — expose only what must be public, keep everything else internal — is fundamental to secure application architecture.

---

**Q3: How does service DNS work within a Kubernetes namespace?**

Kubernetes creates DNS entries for every Service. Within the same namespace, a Service named `iron-db-service-devops` is reachable at just `iron-db-service-devops:3306`. From a different namespace, the full DNS name is `iron-db-service-devops.iron-namespace-devops.svc.cluster.local`. The pattern is `<service>.<namespace>.svc.<cluster-domain>`. This is how the gallery app's database connection string works — it references `iron-db-service-devops` as the hostname, and Kubernetes DNS resolves it to the database pod's ClusterIP. No hardcoded IP addresses, no external DNS — pure Kubernetes-native service discovery.

---

**Q4: What is the purpose of the two emptyDir volumes on the gallery deployment?**

`config` mounted at `/usr/share/nginx/html/data` and `images` mounted at `/usr/share/nginx/html/uploads` provide writable storage for the gallery application's runtime data. The base `kodekloud/irongallery:2.0` image's nginx document root is read-only (from the image layers). The app needs to write configuration and uploaded images at runtime — `emptyDir` provides writable temporary storage at these paths. Without these volumes, the app would fail when trying to write files to these directories. In production, these would be PersistentVolumeClaims to survive pod restarts — `emptyDir` means data is lost if the pod restarts.

---

**Q5: How would you scale only the gallery frontend without affecting the database?**

```bash
kubectl scale deployment iron-gallery-deployment-devops \
  --replicas=3 -n iron-namespace-devops
```

The gallery is stateless (files in emptyDir are per-pod, but for a gallery that's served from the DB), so it scales horizontally. The database stays at 1 replica — MariaDB with emptyDir doesn't support multi-replica horizontal scaling (that requires replication configuration and ReadWriteMany storage). The `iron-gallery-service-devops` automatically load-balances across all 3 gallery replicas using its label selector. This is the architecture advantage of separating stateless frontend (scales easily) from stateful backend (needs care to scale).

---

**Q6: How would you delete all resources in this namespace with one command?**

`kubectl delete namespace iron-namespace-devops` deletes the namespace and ALL resources within it — Deployments, Pods, Services, ConfigMaps, Secrets, everything. It's the Kubernetes equivalent of `rm -rf` for a namespace. This is both the power and the danger — it's clean and complete, but irreversible. In production, namespaces containing active data should never be deleted without backup verification. For safe cleanup: `kubectl delete all --all -n iron-namespace-devops` deletes all standard resources (Pods, Deployments, Services) without deleting the namespace itself or its PVCs and Secrets.

---

## 🔗 References

- [Kubernetes Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Kubernetes DNS for Services](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
