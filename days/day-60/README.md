# Day 60 — Kubernetes Persistent Storage: PV + PVC + Pod + Service

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Persistent Storage / Full Stack  
**Difficulty:** Intermediate  
**Phase:** 🏁 Phase 4 Complete — AWS Core Services  
**Status:** ✅ Completed

---

## 📋 Task Summary

Deploy a complete stateful web application stack with persistent storage:

| Resource | Name | Details |
|----------|------|---------|
| PersistentVolume | `pv-nautilus` | 3Gi, manual, RWO, hostPath `/mnt/devops` |
| PersistentVolumeClaim | `pvc-nautilus` | 1Gi, manual, RWO |
| Pod | `pod-nautilus` | `httpd:latest`, PVC mounted at doc root |
| Service | `web-nautilus` | NodePort, port 30008 |

---

## 🧠 Concept — Kubernetes Persistent Storage

### The PV → PVC → Pod Chain

```
Node filesystem: /mnt/devops
        │
        ▼
PersistentVolume (pv-nautilus) — cluster-level storage resource
        │  Kubernetes binds matching PV to PVC
        ▼
PersistentVolumeClaim (pvc-nautilus) — namespace-level storage request
        │  Pod references PVC by claimName
        ▼
Pod (pod-nautilus) — mounts PVC at /usr/local/apache2/htdocs
        │
        ▼
Service (web-nautilus) — exposes pod on nodePort 30008
```

### PersistentVolume vs PersistentVolumeClaim

| Resource | Level | Who creates it | Purpose |
|----------|-------|---------------|---------|
| PV | Cluster | Admin / storage provisioner | Represents actual storage |
| PVC | Namespace | Developer / application team | Request for storage |

**Separation of concerns:** Admins provision PVs (or configure dynamic provisioning). Developers claim storage via PVCs without knowing where or how it's provisioned. This decoupling is intentional — applications declare "I need 1Gi of ReadWriteOnce storage" and Kubernetes finds a suitable PV.

### Static vs Dynamic Provisioning

```
Static (today's task):
  Admin creates PV manually → Developer creates PVC → K8s binds them

Dynamic:
  StorageClass + provisioner → PVC triggers automatic PV creation
  (AWS EBS, GCP PD, Azure Disk — cloud storage provisioned on demand)
```

`storageClassName: manual` signals static provisioning — no automated provisioner involved.

### Access Modes

| Mode | Short | Meaning |
|------|-------|---------|
| `ReadWriteOnce` | RWO | One node can mount read-write |
| `ReadOnlyMany` | ROX | Many nodes can mount read-only |
| `ReadWriteMany` | RWX | Many nodes can mount read-write |

`ReadWriteOnce` is correct for a single-pod web server. `ReadWriteMany` would be needed for multiple replicas sharing the same volume (requires NFS or distributed storage).

### httpd Document Root

Apache httpd's document root is `/usr/local/apache2/htdocs` — this is where the PVC must be mounted for the web server to serve content from persistent storage.

> **Real-world context:** This PV+PVC pattern is the foundation for every stateful application on Kubernetes — databases (PostgreSQL, MySQL, MongoDB), message queues, content management systems. In production cloud environments, dynamic provisioning via StorageClasses (AWS EBS, EFS, GCP PD) eliminates the need for manual PV creation. The PVC remains identical — only the StorageClass changes. Understanding static provisioning is essential for understanding dynamic provisioning.

---

## 🔧 The Manifests

### pv-nautilus.yaml

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nautilus
spec:
  storageClassName: manual
  capacity:
    storage: 3Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/devops
```

### pvc-nautilus.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nautilus
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

### pod-nautilus.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-nautilus
  labels:
    app: web-nautilus
spec:
  containers:
    - name: container-nautilus
      image: httpd:latest
      volumeMounts:
        - name: web-storage
          mountPath: /usr/local/apache2/htdocs
  volumes:
    - name: web-storage
      persistentVolumeClaim:
        claimName: pvc-nautilus
```

### web-nautilus-service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-nautilus
spec:
  type: NodePort
  selector:
    app: web-nautilus
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30008
```

---

## 🔧 Solution — Step by Step

### Step 1: Create PV and verify Available

```bash
kubectl apply -f pv-nautilus.yaml
kubectl get pv pv-nautilus
# STATUS: Available ✅
```

### Step 2: Create PVC and verify Bound

```bash
kubectl apply -f pvc-nautilus.yaml
kubectl get pvc pvc-nautilus
# STATUS: Bound, VOLUME: pv-nautilus ✅
```

### Step 3: Create Pod and verify Running

```bash
kubectl apply -f pod-nautilus.yaml
kubectl get pod pod-nautilus
# STATUS: Running ✅
```

### Step 4: Create Service and verify

```bash
kubectl apply -f web-nautilus-service.yaml
kubectl get service web-nautilus
kubectl get endpoints web-nautilus    # Pod IP listed ✅
```

### Step 5: Test

```bash
curl http://localhost:30008
# httpd default page ✅
```

### Quick verification of all resources

```bash
kubectl get pv,pvc,pod,svc
```

---

## 📌 Commands Reference

```bash
# Apply in order (PV before PVC before Pod)
kubectl apply -f pv-nautilus.yaml
kubectl apply -f pvc-nautilus.yaml
kubectl apply -f pod-nautilus.yaml
kubectl apply -f web-nautilus-service.yaml

# Verify all at once
kubectl get pv,pvc,pod,svc

# Detailed checks
kubectl describe pv pv-nautilus
kubectl describe pvc pvc-nautilus
kubectl describe pod pod-nautilus | grep -A 5 "Volumes"
kubectl get endpoints web-nautilus
curl http://localhost:30008
```

---

## ⚠️ Common Mistakes to Avoid

1. **Wrong mount path for httpd** — httpd document root is `/usr/local/apache2/htdocs`. Mounting at `/var/www/html` (nginx path) or `/usr/share/nginx/html` means the web server serves from the wrong directory.
2. **StorageClass mismatch** — PV and PVC must have the same `storageClassName: manual`. If they differ, the PVC never binds — stays `Pending` indefinitely.
3. **Access mode mismatch** — PV and PVC must share at least one access mode. `ReadWriteOnce` in both is correct.
4. **PVC capacity exceeding PV capacity** — PVC requests `1Gi` from a `3Gi` PV — this binds correctly (PVC request ≤ PV capacity). Requesting `4Gi` from a `3Gi` PV stays `Pending`.
5. **Missing Pod label for Service** — The Service `selector: app: web-nautilus` must match the Pod's `labels: app: web-nautilus`. No match = no endpoints = no traffic.
6. **Creating Pod before PVC is Bound** — If the PVC is still `Pending` when the Pod starts, the Pod stays `Pending` too. Always verify PVC is `Bound` before applying the Pod manifest.

---

## 🔍 PV Binding Logic

```
Kubernetes matches PV to PVC using:
  ✓ storageClassName matches
  ✓ accessModes compatible (PV has RWO, PVC requests RWO ✅)
  ✓ capacity sufficient (PV has 3Gi, PVC needs 1Gi ✅)
  ✓ volumeMode compatible (both Filesystem by default)

Result: pvc-nautilus → BOUND → pv-nautilus
PV status: Available → Bound (reserved for this PVC)
```

Once a PV is bound to a PVC, no other PVC can claim it — even if the PV has unused capacity (3Gi PV, 1Gi PVC — the remaining 2Gi is not available to other PVCs in static provisioning).

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between a PersistentVolume and a PersistentVolumeClaim?**

A PersistentVolume (PV) is a cluster-level resource representing actual storage — an NFS share, an AWS EBS volume, a GCP Persistent Disk, or a local path. It's provisioned by an administrator or dynamically by a StorageClass provisioner. A PersistentVolumeClaim (PVC) is a namespace-level resource representing a storage request by an application — "I need 1Gi of ReadWriteOnce storage." Kubernetes matches PVCs to suitable PVs based on storageClass, access modes, and capacity. This separation decouples how storage is provisioned (admin concern) from how it's consumed (developer concern). The PVC is what Pods reference — they never reference PVs directly.

---

**Q2: What happens when a PVC is deleted — does the underlying data get deleted?**

It depends on the PV's `reclaimPolicy`. `Retain` (default for manually created PVs): the PV and its data survive PVC deletion — the PV moves to `Released` state and must be manually cleaned up before another PVC can bind to it. `Delete`: the PV and the underlying storage (e.g., AWS EBS volume) are automatically deleted when the PVC is deleted — used by dynamically provisioned volumes. `Recycle` (deprecated): data is scrubbed and the PV is made Available again. In production, `Retain` is safer for critical data — `Delete` is convenient for ephemeral workloads. The `hostPath` PV in this task uses the node's filesystem; the data at `/mnt/devops` persists independently of PV/PVC lifecycle.

---

**Q3: What is dynamic provisioning and how does it differ from what we did today?**

Static provisioning (today): an admin manually creates PV resources beforehand. PVCs bind to pre-existing PVs. This requires predicting storage needs and creating PVs in advance — doesn't scale well. Dynamic provisioning: a StorageClass with a provisioner automatically creates a PV when a PVC is submitted. No pre-created PVs needed. On AWS EKS, `storageClassName: gp2` or `gp3` triggers the EBS CSI driver to provision an EBS volume on demand. The PVC spec looks identical — only the `storageClassName` changes. Dynamic provisioning is the standard in cloud Kubernetes environments because it scales automatically and eliminates storage administration overhead.

---

**Q4: Why does a 1Gi PVC bind to a 3Gi PV — and what happens to the unused 2Gi?**

Kubernetes finds the smallest PV that satisfies the PVC's requirements. A 3Gi PV satisfies a 1Gi request because 3 ≥ 1. In static provisioning, the entire PV is bound exclusively to that PVC — the "unused" 2Gi cannot be claimed by another PVC. Once bound, the PV is reserved. This is storage inefficiency inherent to static provisioning — if you have a 3Gi PV and a 1Gi PVC, you "waste" 2Gi. Dynamic provisioning avoids this: the provisioner creates exactly the requested amount (1Gi EBS volume for a 1Gi PVC). This is one of the strongest arguments for dynamic over static provisioning at scale.

---

**Q5: How would this setup change if the web server needed multiple replicas sharing the same storage?**

`ReadWriteOnce` (RWO) only allows one node to mount the volume read-write. With multiple replicas potentially scheduled on different nodes, all replicas after the first would fail to mount the volume. For shared storage across multiple pods/nodes, you need `ReadWriteMany` (RWX). In cloud environments, AWS EFS (Elastic File System) supports RWX — multiple pods across multiple nodes can mount the same EFS volume simultaneously. GCP has Filestore, Azure has Azure Files. The PVC simply changes `accessModes` to `ReadWriteMany` and uses a StorageClass backed by the RWX-capable provisioner. For a single-replica stateless web server, RWO is perfectly correct.

---

**Q6: How would you deploy this in production on AWS EKS?**

Replace the `hostPath` PV with dynamic EBS or EFS provisioning. For a single web server with RWO storage: use the EBS CSI driver StorageClass (`storageClassName: gp3`). The PVC remains unchanged except for the storageClassName. Delete the manual PV — it's no longer needed. For multiple replicas sharing storage: use EFS CSI driver (`storageClassName: efs-sc`) which supports RWX. Upgrade the Pod to a Deployment with 3+ replicas. Add a LoadBalancer Service instead of NodePort. Add resource requests/limits, readiness/liveness probes, and a PodDisruptionBudget. The resulting architecture is genuinely production-ready on EKS.

---

## 🔗 References

- [Kubernetes Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [PersistentVolumeClaims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Dynamic Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
