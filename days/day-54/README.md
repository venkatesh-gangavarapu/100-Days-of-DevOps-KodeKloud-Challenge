# Day 54 — Kubernetes Shared Volumes: emptyDir Between Multi-Container Pod

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Volumes / Multi-Container Pods  
**Difficulty:** Intermediate  
**Phase:** Phase 4 — AWS Core Services  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create a Pod with two Debian containers sharing an `emptyDir` volume. Container 1 mounts it at `/tmp/official`, container 2 at `/tmp/apps`. Write a file in container 1 and verify it appears in container 2.

---

## 🧠 Concept — emptyDir Shared Volumes

### What is `emptyDir`?

`emptyDir` is a Kubernetes volume type that:
- Is **created empty** when the Pod is assigned to a node
- **Lives for the lifetime of the Pod** — deleted when Pod is removed
- Is **shared across all containers** in the same Pod
- Survives container restarts within the Pod (but not Pod deletion)

```
Pod: volume-share-xfusion
  │
  ├── Container 1 (/tmp/official)
  │         │
  │    write official.txt ──────►  emptyDir on node disk
  │                                      │
  └── Container 2 (/tmp/apps)            │
            │                            │
       cat /tmp/apps/official.txt ◄──────┘
```

Same volume, different mount paths — a write in one container is immediately visible in the other.

### `emptyDir` vs Other Volume Types

| Type | Lifetime | Shared across | Use case |
|------|---------|---------------|---------|
| `emptyDir` | Pod lifetime | Containers in same Pod | Temp files, cache, inter-container data |
| `hostPath` | Node lifetime | Pods on same node | Node-level data, logs |
| `persistentVolumeClaim` | Independent | Any Pod (with access) | Database data, persistent app data |
| `configMap` | API object | Any Pod (by ref) | Config files, env vars |

### `command: ["sleep", "3600"]` — Why Required

Debian's default CMD exits immediately. If the main process exits, Kubernetes considers the container done and restarts it — creating a `CrashLoopBackOff`. `sleep 3600` keeps the process running so the container stays alive for testing.

### Volume Mount Structure in YAML

```yaml
containers:
  - name: my-container
    volumeMounts:              # Per-container: where to mount
      - name: volume-share     # References volumes[].name below
        mountPath: /tmp/data   # Path inside the container

volumes:                       # Pod-level: volume definitions
  - name: volume-share         # Name referenced by volumeMounts
    emptyDir: {}               # Type and config
```

The `volumes` section defines what volumes exist. The `volumeMounts` section (per container) defines where each container mounts them.

> **Real-world context:** `emptyDir` shared volumes are used in sidecar patterns — a main application writes logs to a shared volume, and a logging sidecar reads from the same volume and ships to a log aggregation service. Init containers use `emptyDir` to pre-populate data that the main container reads at startup. Service mesh sidecars (Envoy in Istio) use shared memory volumes for high-performance communication with the main container.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Access | Jump Host (kubectl pre-configured) |
| Pod name | `volume-share-xfusion` |
| Container 1 | `volume-container-xfusion-1` — mounts at `/tmp/official` |
| Container 2 | `volume-container-xfusion-2` — mounts at `/tmp/apps` |
| Volume name | `volume-share` |
| Volume type | `emptyDir` |
| Test file | `/tmp/official/official.txt` |
| Test content | `Welcome to xFusionCorp Industries` |

---

## 🔧 Solution — Step by Step

### Step 1: Create the Pod manifest

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-share-xfusion
spec:
  containers:
    - name: volume-container-xfusion-1
      image: debian:latest
      command: ["sleep", "3600"]
      volumeMounts:
        - name: volume-share
          mountPath: /tmp/official

    - name: volume-container-xfusion-2
      image: debian:latest
      command: ["sleep", "3600"]
      volumeMounts:
        - name: volume-share
          mountPath: /tmp/apps

  volumes:
    - name: volume-share
      emptyDir: {}
```

### Step 2: Apply the manifest

```bash
kubectl apply -f volume-share-xfusion.yaml
```

### Step 3: Verify Pod is running

```bash
kubectl get pod volume-share-xfusion
```

**Expected:**
```
NAME                    READY   STATUS    RESTARTS   AGE
volume-share-xfusion    2/2     Running   0          30s
```

`2/2` confirms both containers are running.

### Step 4: Create the test file in container 1

```bash
kubectl exec volume-share-xfusion -c volume-container-xfusion-1 -- \
  sh -c 'echo "Welcome to xFusionCorp Industries" > /tmp/official/official.txt'
```

### Step 5: Verify file content from container 1

```bash
kubectl exec volume-share-xfusion -c volume-container-xfusion-1 -- \
  cat /tmp/official/official.txt
```

**Expected:**
```
Welcome to xFusionCorp Industries
```

### Step 6: Verify file is visible from container 2

```bash
kubectl exec volume-share-xfusion -c volume-container-xfusion-2 -- \
  cat /tmp/apps/official.txt
```

**Expected:**
```
Welcome to xFusionCorp Industries
```

Same content, different mount path, different container. ✅ Shared volume confirmed.

---

## 📌 Commands Reference

```bash
# ─── Deploy ──────────────────────────────────────────────
kubectl apply -f volume-share-xfusion.yaml

# ─── Verify pod ──────────────────────────────────────────
kubectl get pod volume-share-xfusion
kubectl describe pod volume-share-xfusion

# ─── Create file in container 1 ──────────────────────────
kubectl exec volume-share-xfusion \
  -c volume-container-xfusion-1 -- \
  sh -c 'echo "Welcome to xFusionCorp Industries" > /tmp/official/official.txt'

# ─── Verify from container 1 ─────────────────────────────
kubectl exec volume-share-xfusion \
  -c volume-container-xfusion-1 -- \
  cat /tmp/official/official.txt

# ─── Verify from container 2 ─────────────────────────────
kubectl exec volume-share-xfusion \
  -c volume-container-xfusion-2 -- \
  cat /tmp/apps/official.txt

# ─── List files in both mount paths ──────────────────────
kubectl exec volume-share-xfusion \
  -c volume-container-xfusion-1 -- ls -la /tmp/official/
kubectl exec volume-share-xfusion \
  -c volume-container-xfusion-2 -- ls -la /tmp/apps/
```

---

## ⚠️ Common Mistakes to Avoid

1. **Not specifying `command: ["sleep", "3600"]`** — Without a long-running command, Debian exits immediately and both containers enter `CrashLoopBackOff`. Always give containers without a default entrypoint a keep-alive command.
2. **Volume name mismatch** — `volumeMounts[].name` must exactly match `volumes[].name`. A typo means the mount silently fails — no error, just no shared data.
3. **Forgetting `-c container-name` in exec** — In a multi-container Pod, `kubectl exec` without `-c` uses the first container by default. Always specify which container when writing to or reading from specific mount paths.
4. **Wrong mount path in exec** — Container 1 writes to `/tmp/official/`, container 2 reads from `/tmp/apps/`. Using the wrong path in either exec returns "no such file" even when the volume is working correctly.
5. **Checking file existence before Pod is fully Ready** — Wait for `2/2 Running` before exec. If you exec while a container is still starting, it fails.

---

## 🔍 emptyDir Storage Locations

```
By default:
emptyDir stored in: /var/lib/kubelet/pods/<pod-uid>/volumes/kubernetes.io~empty-dir/volume-share/

With memory backing (emptyDir: {medium: Memory}):
Stored in: tmpfs (RAM) — faster but counts against container memory limit
```

```yaml
# RAM-backed emptyDir (for high-performance IPC):
volumes:
  - name: volume-share
    emptyDir:
      medium: Memory
      sizeLimit: 256Mi
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is an `emptyDir` volume and when would you use it over a PersistentVolumeClaim?**

An `emptyDir` volume is created fresh when a Pod starts and deleted when the Pod is removed — it has no persistence beyond the Pod's lifetime. Use `emptyDir` for temporary data that only needs to live as long as the Pod: scratch space for computations, shared cache between containers, inter-container communication files, or data generated by an init container that the main container consumes. Use a PersistentVolumeClaim when data must survive Pod restarts and rescheduling — database files, user uploads, application state. The key distinction is whether the data's value outlives the Pod.

---

**Q2: What is the sidecar pattern and how does `emptyDir` enable it?**

The sidecar pattern places a helper container alongside the main application container in the same Pod. The sidecar augments the main container's functionality without modifying it. Common examples: a log shipping sidecar reads from a shared `emptyDir` volume where the application writes log files, forwarding them to Elasticsearch or Splunk. A git sync sidecar periodically pulls code into a shared `emptyDir` that the web server container serves. An Envoy proxy sidecar intercepts and manages network traffic. `emptyDir` is the standard mechanism for the main container and sidecar to exchange data — the main container writes, the sidecar reads (or vice versa).

---

**Q3: What happens to an `emptyDir` volume when a container inside the Pod crashes and restarts?**

The `emptyDir` volume survives container restarts within the same Pod. If container 1 crashes and Kubernetes restarts it, the `emptyDir` contents remain intact — the restarted container mounts the same volume with the same data. The volume is only deleted when the entire Pod is deleted or evicted from the node. This makes `emptyDir` suitable for data that should survive container crashes but not Pod deletion. If you need data to survive Pod deletion, you need a PersistentVolumeClaim.

---

**Q4: How does `emptyDir` with `medium: Memory` differ from the default?**

By default, `emptyDir` stores data on the node's disk (in `/var/lib/kubelet/pods/`). With `medium: Memory`, the volume is backed by `tmpfs` — a RAM-based filesystem. This is significantly faster than disk I/O and useful for high-performance inter-container communication or large temporary computations. The trade-off: memory-backed `emptyDir` counts against the container's memory limit, and node memory is a more constrained resource than disk. If the Pod is evicted due to memory pressure, the data is lost. Use `medium: Memory` only when the performance benefit justifies the memory cost and the data is genuinely temporary.

---

**Q5: Can two Pods share an `emptyDir` volume?**

No. `emptyDir` is strictly scoped to a single Pod — it's created per-Pod and exists only on the node where the Pod runs. Two different Pods cannot share an `emptyDir`, even if they're on the same node. To share data between Pods, you need a PersistentVolumeClaim backed by a network storage provider (NFS, AWS EFS, Ceph, etc.) with `ReadWriteMany` access mode, which allows multiple Pods across multiple nodes to mount the same volume simultaneously. `emptyDir` is intentionally local and ephemeral — it's the wrong tool for cross-Pod data sharing.

---

**Q6: What is the difference between `volumeMounts` and `volumes` in a Pod spec?**

`volumes` is a Pod-level field that defines what volumes exist and their configuration — name, type, and source. It's a single declaration shared by all containers. `volumeMounts` is a container-level field that defines how and where each container mounts the Pod's volumes — specifying the volume name (matching `volumes[].name`) and the mount path inside that specific container. Two containers can mount the same volume at different paths, or one container can mount multiple volumes. This separation — "what exists" (volumes) vs "where I mount it" (volumeMounts) — allows flexible composition: define the volume once, customize the mount path per container.

---

## 🔗 References

- [Kubernetes Volumes — emptyDir](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)
- [Kubernetes — Multi-Container Pods](https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers)
- [Sidecar Pattern](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
