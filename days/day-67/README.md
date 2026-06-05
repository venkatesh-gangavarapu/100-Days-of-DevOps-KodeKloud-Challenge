# Day 67 — Kubernetes Guestbook App: Multi-Tier Redis + PHP Frontend

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Multi-Tier / Redis Replication  
**Difficulty:** Advanced  
**Phase:** Phase 5 — Advanced Kubernetes & CI/CD  
**Status:** ✅ Completed

---

## 📋 Task Summary

Deploy the classic Kubernetes Guestbook application — 7 resources across 2 tiers:

### Back-End Tier
| Resource | Details |
|----------|---------|
| Deployment `redis-master` | 1 replica, `redis` image, 100m/100Mi |
| Service `redis-master` | ClusterIP, port 6379 |
| Deployment `redis-slave` | 2 replicas, `gb-redisslave:v3`, env `GET_HOSTS_FROM=dns` |
| Service `redis-slave` | ClusterIP, port 6379 |
| Service `redis-follower` | ClusterIP, port 6379, selector `app=redis-slave` |

### Front-End Tier
| Resource | Details |
|----------|---------|
| Deployment `frontend` | 3 replicas, `gb-frontend@sha256:...`, env `GET_HOSTS_FROM=dns` |
| Service `frontend` | NodePort, port 80, nodePort 30009 |

---

## 🧠 Concept — Redis Master-Slave Replication in Kubernetes

### The Architecture

```
User → NodePort:30009
           │
           ▼
  frontend (3 pods — PHP app)
       │          │
 reads-only   writes-only
       │          │
       ▼          ▼
 redis-slave  redis-master
  (2 pods)     (1 pod)
       │          │
       └──────────┘
         replication
```

**Redis Master** accepts all writes. **Redis Slaves** replicate from master and serve reads. The PHP frontend splits traffic: reads go to slaves for load distribution, writes go to master.

### Why Two Redis Services + redis-follower?

The PHP frontend uses `GET_HOSTS_FROM=dns` which means it uses service names as hostnames:
- Writes → `redis-master:6379`
- Reads → `redis-follower:6379` (aliased to redis-slave pods)

Both `redis-slave` and `redis-follower` services point to the same pods (`app=redis-slave`). The duplicate service provides a stable DNS name that the frontend's PHP code expects — the guestbook frontend is hardcoded to look for `redis-follower` for reads.

### `GET_HOSTS_FROM=dns`

Both Redis slave and PHP frontend use this environment variable:
- When set to `dns`, the app resolves Redis master/slave hostnames via Kubernetes DNS
- When set to `env`, it expects explicit host environment variables

`dns` mode is the modern Kubernetes-native approach — service names resolve automatically.

### Image Digest vs Tag

```yaml
image: gcr.io/google-samples/gb-frontend@sha256:a908df...
```

`@sha256:` is a digest — immutable reference to a specific image layer set. Unlike tags (which are mutable pointers that can change), a digest always refers to the exact same image. Using digests in production prevents unexpected image updates and ensures reproducible deployments.

> **Real-world context:** The Guestbook is the official Kubernetes sample application, documented in the Kubernetes tutorials. It demonstrates multi-tier architecture, service discovery via DNS, Redis master-slave replication patterns, and horizontal scaling of the stateless frontend. Every concept in this deployment — separated read/write paths, stateless frontend scaling, stateful backend replication — appears in production microservices architectures.

---

## 🔧 Solution — Step by Step

### Apply and verify

```bash
kubectl apply -f guestbook-stack.yaml

# All 6 pods running
kubectl get pods
# redis-master-xxx      1/1 Running
# redis-slave-xxx (x2)  1/1 Running
# frontend-xxx (x3)     1/1 Running ✅

# All services
kubectl get svc
# redis-master    ClusterIP  6379/TCP
# redis-slave     ClusterIP  6379/TCP
# redis-follower  ClusterIP  6379/TCP
# frontend        NodePort   80:30009/TCP ✅

# Test
curl http://localhost:30009
```

---

## 📌 Commands Reference

```bash
kubectl apply -f guestbook-stack.yaml
kubectl get pods
kubectl get deployments
kubectl get svc
kubectl get endpoints
curl http://localhost:30009

# Scale frontend
kubectl scale deployment frontend --replicas=5

# Cleanup
kubectl delete -f guestbook-stack.yaml
```

---

## ⚠️ Common Mistakes to Avoid

1. **redis-follower service selector** — Must use `app: redis-slave`, NOT `app: redis-follower`. It's an alias service for the slave pods.
2. **Exact image for frontend** — The `@sha256:` digest must be copied exactly. Any modification breaks the image reference.
3. **Both slave and frontend need `GET_HOSTS_FROM=dns`** — Forgetting this env var causes the apps to look for hosts in environment variables that don't exist.
4. **redis-slave replicas = 2** — The task specifies 2 slave replicas. `1` won't pass validation.
5. **frontend replicas = 3** — Same — must be exactly 3.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is Redis master-slave replication and why deploy it on Kubernetes?**

Redis master-slave (now called master-replica) replication continuously copies data from one master Redis instance to one or more slave instances. The master accepts writes; slaves replicate all write operations and serve read requests. Benefits: read scalability (distribute read load across slaves), high availability (promote a slave to master if master fails), and data redundancy. In Kubernetes, this pattern scales elegantly — add more slave replicas to increase read throughput. The stateless frontend pods are completely separate from the stateful Redis pods, allowing each tier to scale independently.

---

**Q2: Why does the frontend use `redis-follower` as the read hostname when `redis-slave` service also exists?**

The guestbook PHP application is specifically coded to connect to `redis-master` for writes and `redis-follower` for reads — these are hardcoded service names in the application source. The `redis-follower` service was created specifically to provide the DNS name the application expects. Both `redis-slave` and `redis-follower` Services use `selector: app: redis-slave`, so they route to the same pods. This demonstrates that Kubernetes service names are application-level DNS contracts — changing a service name is a breaking change for applications that depend on it.

---

**Q3: What is the benefit of using an image digest (`@sha256:`) instead of a tag (`latest` or `v1.0`)?**

Image tags are mutable — a registry maintainer can push a new image with the same tag. `nginx:latest` today might be a different image than `nginx:latest` next month. An image digest is a cryptographic hash of the image content — it's immutable. If you reference `nginx@sha256:abc123`, you always get exactly that image regardless of when or where you pull it. In production, using digests ensures reproducibility: the same image runs in staging and production, the same image that passed CI tests is deployed. Tags are convenient for development; digests are required for reliable production deployments.

---

**Q4: How does `GET_HOSTS_FROM=dns` work in the Guestbook application?**

The guestbook PHP application checks this environment variable to determine how to discover Redis service hostnames. When set to `dns`, it uses the service name directly as the hostname — `redis-master` and `redis-follower` — relying on Kubernetes DNS to resolve them to ClusterIPs. When set to `env`, it reads the hostname from other environment variables (like `REDIS_MASTER_SERVICE_HOST` which Kubernetes injects automatically for each service). The `dns` mode is simpler and more portable — it works in any Kubernetes cluster without depending on the auto-injected service environment variables that vary by naming convention.

---

**Q5: How would you make this guestbook production-ready?**

Several improvements: (1) Replace Redis `emptyDir` (implicit here — no PVC) with PersistentVolumeClaims so data survives pod restarts. (2) Add Redis AUTH password via Secret. (3) Use Redis Sentinel or Redis Cluster for automatic failover instead of simple master-slave. (4) Replace `NodePort` frontend service with an Ingress with TLS termination and a real domain name. (5) Add resource limits (not just requests) to prevent any pod from consuming unbounded memory. (6) Add liveness and readiness probes to all containers. (7) Use specific image versions/digests for redis and gb-redisslave. (8) Deploy in a dedicated namespace with RBAC.

---

**Q6: What happens to the guestbook data if the redis-master pod is deleted?**

With no PersistentVolumeClaim, the redis-master pod uses an `emptyDir` volume implicitly — data lives in the container's writable layer. If the pod is deleted, all stored guestbook entries are lost. When the Deployment recreates the pod, it starts with an empty Redis database. The slaves also lose their data when restarted. For a demo application this is acceptable; for production, mount a PVC at `/data` in the Redis container and configure Redis persistence (`save` or `appendonly yes`) to ensure data survives pod restarts.

---

## 🔗 References

- [Kubernetes Guestbook Tutorial](https://kubernetes.io/docs/tutorials/stateless-application/guestbook/)
- [Redis Replication](https://redis.io/docs/management/replication/)
- [Image Digests in Kubernetes](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
