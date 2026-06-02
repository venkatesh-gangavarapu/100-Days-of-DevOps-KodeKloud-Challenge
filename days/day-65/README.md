# Day 65 — Redis on Kubernetes: ConfigMap + Multi-Volume Deployment

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / ConfigMap / Redis / Volumes  
**Difficulty:** Intermediate  
**Phase:** Phase 5 — Advanced Kubernetes & CI/CD  
**Status:** ✅ Completed

---

## 📋 Task Summary

Deploy Redis (`redis:alpine`) on Kubernetes with:
- ConfigMap `my-redis-config` containing `maxmemory 2mb` in key `redis-config`
- Deployment `redis-deployment` with 1 replica, 1 CPU request
- Two volumes: `emptyDir` at `/redis-master-data`, ConfigMap at `/redis-master`
- Container port `6379`

---

## 🧠 Concept — ConfigMaps as Volume Mounts

### What is a ConfigMap?

A ConfigMap stores non-sensitive configuration data as key-value pairs. When mounted as a volume, each **key becomes a file** and the **value becomes the file content** at the mount path.

```
ConfigMap: my-redis-config
  key:   redis-config
  value: maxmemory 2mb

Mounted at /redis-master:
  /redis-master/redis-config   ← file
  Content: "maxmemory 2mb"
```

### ConfigMap Data Format — The `|` Block Scalar

```yaml
data:
  redis-config: |        ← pipe (|) preserves newlines
    maxmemory 2mb        ← file content with newline at end
```

The `|` (block scalar) in YAML preserves newlines — important for config files where line breaks are meaningful. Without it, `maxmemory 2mb` would be stored as a single-line string (fine here, but matters for multi-line configs).

### Two Volume Pattern

```
Pod: redis-deployment
  ├── Volume: data (emptyDir)
  │     └── mountPath: /redis-master-data  ← Redis data directory
  │
  └── Volume: redis-config (ConfigMap)
        └── mountPath: /redis-master        ← Redis config directory
              └── redis-config              ← file: "maxmemory 2mb"
```

This cleanly separates concerns:
- Data volume: Redis writes its RDB/AOF files here (ephemeral, pod-scoped)
- Config volume: Redis reads its configuration from here

### CPU Request of "1"

```yaml
resources:
  requests:
    cpu: "1"    ← 1 full CPU core (1000m)
```

Unlike `100m` (100 millicores), `"1"` requests a full CPU core. The scheduler ensures Redis is placed on a node with at least 1 unallocated CPU. This is appropriate for a caching service that handles high-frequency reads/writes.

> **Real-world context:** Redis is the most widely deployed in-memory caching solution. Every high-traffic application — e-commerce, social media, gaming — uses Redis for session caching, rate limiting, pub/sub, and leaderboards. In Kubernetes, Redis is typically deployed with a ConfigMap for tuning parameters (maxmemory, eviction policy, persistence settings) and a PersistentVolumeClaim if persistence is needed. The `maxmemory 2mb` here is a lab constraint — production Redis is configured for gigabytes.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| ConfigMap | `my-redis-config` |
| Config key | `redis-config` |
| Config value | `maxmemory 2mb` |
| Deployment | `redis-deployment` |
| Image | `redis:alpine` |
| Container | `redis-container` |
| CPU request | `1` |
| Data volume | `emptyDir` at `/redis-master-data` |
| Config volume | ConfigMap at `/redis-master` |
| Port | `6379` |

---

## 🔧 The Manifests

### redis-configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-redis-config
data:
  redis-config: |
    maxmemory 2mb
```

### redis-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis-container
          image: redis:alpine
          ports:
            - containerPort: 6379
          resources:
            requests:
              cpu: "1"
          volumeMounts:
            - name: data
              mountPath: /redis-master-data
            - name: redis-config
              mountPath: /redis-master
      volumes:
        - name: data
          emptyDir: {}
        - name: redis-config
          configMap:
            name: my-redis-config
```

---

## 🔧 Solution — Step by Step

### Step 1: Create ConfigMap first

```bash
kubectl apply -f redis-configmap.yaml
kubectl describe configmap my-redis-config
# Confirm: Data > redis-config: maxmemory 2mb ✅
```

### Step 2: Deploy Redis

```bash
kubectl apply -f redis-deployment.yaml
kubectl get deployment redis-deployment
# READY: 1/1 ✅
```

### Step 3: Verify volumes inside pod

```bash
POD=$(kubectl get pod -l app=redis -o jsonpath='{.items[0].metadata.name}')

kubectl exec $POD -- cat /redis-master/redis-config
# maxmemory 2mb ✅

kubectl exec $POD -- ls /redis-master-data
# (empty — Redis data dir) ✅
```

### Step 4: Confirm Redis is responding

```bash
kubectl exec $POD -- redis-cli ping
# PONG ✅
```

---

## 📌 Commands Reference

```bash
# Apply in order
kubectl apply -f redis-configmap.yaml
kubectl apply -f redis-deployment.yaml

# Verify
kubectl get configmap my-redis-config
kubectl describe configmap my-redis-config
kubectl get deployment redis-deployment
kubectl get pods -l app=redis

# Check config mounted correctly
POD=$(kubectl get pod -l app=redis -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- cat /redis-master/redis-config
kubectl exec $POD -- redis-cli ping
kubectl exec $POD -- redis-cli config get maxmemory
```

---

## ⚠️ Common Mistakes to Avoid

1. **ConfigMap volume name vs ConfigMap name** — `volumes[].name` (e.g., `redis-config`) is an internal reference used by `volumeMounts[].name`. `volumes[].configMap.name` (e.g., `my-redis-config`) is the actual Kubernetes ConfigMap object name. They can be different — don't confuse them.
2. **Applying deployment before ConfigMap** — If the deployment is applied first, the pod enters `CreateContainerConfigError` because the ConfigMap it references doesn't exist yet. Always create ConfigMaps before the Pods that consume them.
3. **CPU request format** — `"1"` is one full core. `"1m"` is 1 millicore (essentially nothing). Make sure the format matches the intent.
4. **Wrong key name in ConfigMap** — The ConfigMap key is `redis-config`. When mounted, the file at `/redis-master/redis-config` must contain the config. If the key is named differently, the file name changes.
5. **Not verifying with `redis-cli config get maxmemory`** — The config file is mounted but Redis must actually load it. If Redis wasn't started with `--include /redis-master/redis-config`, the maxmemory setting isn't applied. Verify with `redis-cli config get maxmemory`.

---

## 🔍 ConfigMap Volume Mount Structure

```
ConfigMap: my-redis-config
  data:
    redis-config: "maxmemory 2mb\n"
                  ↓ mounted as volume
Pod filesystem:
  /redis-master/           ← mountPath
    redis-config           ← filename = ConfigMap key
    (content: maxmemory 2mb)
```

Each key in the ConfigMap `data` section becomes a separate file. A ConfigMap with 3 keys mounted at `/config/` creates 3 files at `/config/key1`, `/config/key2`, `/config/key3`.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is a ConfigMap and how does it differ from a Secret?**

A ConfigMap stores non-sensitive configuration data as key-value pairs — feature flags, service URLs, config files, tuning parameters. It's stored as plain text in etcd and readable by anyone with `kubectl get configmap` access. A Secret stores sensitive data (passwords, tokens, certificates) with base64 encoding and tighter RBAC controls. The consumption mechanism is identical — both can be environment variables or volume mounts. The distinction is operational: ConfigMaps for anything you'd be comfortable committing to Git; Secrets for anything you wouldn't.

---

**Q2: What happens when you update a ConfigMap that is mounted as a volume?**

Kubernetes detects the ConfigMap update and syncs the new content to the pod's mounted volume — typically within 1-2 minutes (controlled by kubelet's sync frequency). The file at `/redis-master/redis-config` gets updated content without Pod restart. However, the application (Redis) must re-read the config file to pick up the change. Redis doesn't auto-reload config files — you'd need `redis-cli config rewrite` or a Pod restart. For applications that watch config files and reload automatically (nginx with `inotify`), volume-mounted ConfigMap updates provide live config updates without downtime.

---

**Q3: Why is Redis deployed on Kubernetes instead of using a managed service like ElastiCache?**

For testing and development, deploying Redis on Kubernetes is faster, cheaper, and portable — no cloud account required, no additional cost, consistent across environments. For production, the tradeoffs shift: managed services like AWS ElastiCache provide high availability (Multi-AZ replication), automated failover, backup, security patching, and monitoring out of the box without operational overhead. Running Redis on Kubernetes in production requires managing replication, persistence, and failover yourself — achievable with the Redis Operator or Helm charts like Bitnami Redis, but adds operational complexity. The right choice depends on scale, team expertise, and whether the extra cost of managed services is justified.

---

**Q4: What is `maxmemory` in Redis and what happens when it's exceeded?**

`maxmemory` sets the maximum amount of memory Redis can use. When Redis reaches this limit, it applies the `maxmemory-policy` eviction policy to free space. Common policies: `allkeys-lru` (evict least recently used keys from all keys), `volatile-lru` (evict LRU keys with TTL set), `allkeys-random` (evict random keys), `noeviction` (return errors when memory is full — the default). For caching use cases, `allkeys-lru` is standard — the cache automatically evicts old data to make room for new. `2mb` in this task is a lab constraint; production caches are typically configured in gigabytes.

---

**Q5: How would you make Redis persistent on Kubernetes?**

Replace the `emptyDir` data volume with a PersistentVolumeClaim. Add Redis persistence configuration to the ConfigMap: `appendonly yes` (AOF persistence) or `save 60 1000` (RDB snapshots). The pod mounts the PVC at `/redis-master-data` where Redis writes its data files. With a PVC, Redis data survives pod restarts and rescheduling. Without persistence (emptyDir), all cached data is lost on every pod restart — acceptable for pure caching use cases but not for Redis used as a primary data store. In production, the Bitnami Redis Helm chart or Redis Operator handles persistence, replication, and sentinel failover automatically.

---

**Q6: What is `redis:alpine` and why use it over `redis:latest`?**

`redis:alpine` is the Redis image built on Alpine Linux — approximately 30MB vs 110MB for `redis:latest` (Debian-based). Alpine's minimal footprint means faster pulls, less storage, and a smaller attack surface (fewer packages = fewer CVEs). The Redis functionality is identical — Alpine's musl libc doesn't affect Redis's C codebase in this case. `redis:alpine` is the standard choice for Redis in Kubernetes — every tutorial, Helm chart, and operator defaults to it. The only reason to use the full Debian image is if you need specific system libraries that Alpine doesn't include, which is rare for Redis.

---

## 🔗 References

- [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Redis Configuration](https://redis.io/docs/management/config/)
- [Redis Memory Management](https://redis.io/docs/management/optimization/memory-optimization/)
- [Docker Hub — redis](https://hub.docker.com/_/redis)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
