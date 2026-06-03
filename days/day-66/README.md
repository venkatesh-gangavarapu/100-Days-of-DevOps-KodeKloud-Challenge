# Day 66 — MySQL on Kubernetes: PV + PVC + Secrets + Deployment + Service

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Storage / Secrets / Full Stack  
**Difficulty:** Advanced  
**Phase:** Phase 5 — Advanced Kubernetes & CI/CD  
**Status:** ✅ Completed

---

## 📋 Task Summary

Deploy a complete, production-pattern MySQL setup with 7 Kubernetes resources:

| Resource | Name | Details |
|----------|------|---------|
| PersistentVolume | `mysql-pv` | 250Mi, manual, RWO, hostPath |
| PersistentVolumeClaim | `mysql-pv-claim` | 250Mi, binds to mysql-pv |
| Secret | `mysql-root-pass` | key: `password` = `YUIidhb667` |
| Secret | `mysql-user-pass` | `username`=`kodekloud_roy`, `password`=`ksH85UJjhb` |
| Secret | `mysql-db-url` | key: `database` = `kodekloud_db7` |
| Deployment | `mysql-deployment` | `mysql:latest`, PVC mounted, all env from Secrets |
| Service | `mysql` | NodePort `30007` → `3306` |

---

## 🧠 Concept — secretKeyRef for Environment Variables

### Why secretKeyRef Over Literal Values

```yaml
# WRONG — secret in plain text in manifest → committed to Git → exposed
env:
  - name: MYSQL_ROOT_PASSWORD
    value: "YUIidhb667"

# CORRECT — value read from Secret at Pod start time
env:
  - name: MYSQL_ROOT_PASSWORD
    valueFrom:
      secretKeyRef:
        name: mysql-root-pass    # Secret object name
        key: password            # Key within the Secret
```

The manifest never contains the actual password. The Secret stores it. The Pod reads it at runtime. Three separate RBAC concerns: who can see the manifest, who can see the Secret, who can see the running container's env.

### secretKeyRef Anatomy

```yaml
valueFrom:
  secretKeyRef:
    name: mysql-user-pass    ← Kubernetes Secret object name
    key: username            ← Key within that Secret's data
```

One Secret can hold multiple keys — `mysql-user-pass` holds both `username` and `password`. Different environment variables reference different keys from the same Secret using separate `secretKeyRef` entries.

### stringData vs data in Secrets

```yaml
# stringData — plain text, Kubernetes base64-encodes automatically
stringData:
  password: "YUIidhb667"

# data — must be pre-encoded in base64
data:
  password: WVVJaWRoYjY2Nw==   # echo -n "YUIidhb667" | base64
```

`stringData` is more practical — you write plain text, Kubernetes handles encoding. `data` is used when you have pre-encoded values (e.g., from an existing secrets manager output).

### The Complete Resource Chain

```
mysql-pv (250Mi hostPath)
    │
    └── bound to ──► mysql-pv-claim (250Mi)
                          │
                          └── mounted in ──► mysql-deployment
                                                    │
                                                    ├── reads env from mysql-root-pass
                                                    ├── reads env from mysql-user-pass
                                                    └── reads env from mysql-db-url
                                                    │
                                          exposed via ──► mysql Service (NodePort 30007)
```

> **Real-world context:** This PV + PVC + Secrets + Deployment pattern is the production template for any stateful database on Kubernetes. Replace `hostPath` with an EBS-backed StorageClass for AWS. Replace literal Secret values with External Secrets Operator syncing from AWS Secrets Manager. The structural pattern — separate secrets per concern (root password, user credentials, DB name), secretKeyRef injection, PVC for persistence — is exactly how mature Kubernetes deployments handle databases.

---

## 🔧 The Manifest — mysql-stack.yaml

All 7 resources in a single file with `---` separators.

**Order matters:**
1. PV (cluster-level, no dependencies)
2. PVC (binds to PV)
3. Secrets (referenced by Deployment)
4. Deployment (references PVC + Secrets)
5. Service (references Deployment's labels)

---

## 🔧 Solution — Step by Step

### Step 1: Apply all resources

```bash
kubectl apply -f mysql-stack.yaml
```

### Step 2: Verify PV → PVC binding

```bash
kubectl get pv mysql-pv
# STATUS: Bound ✅

kubectl get pvc mysql-pv-claim
# STATUS: Bound, VOLUME: mysql-pv ✅
```

### Step 3: Verify Secrets exist

```bash
kubectl get secrets | grep mysql
# mysql-db-url      Opaque   1
# mysql-root-pass   Opaque   1
# mysql-user-pass   Opaque   2
```

### Step 4: Verify Deployment and Pod

```bash
kubectl get deployment mysql-deployment
# READY: 1/1 ✅

kubectl get pods -l app=mysql
# Running ✅
```

### Step 5: Verify Service

```bash
kubectl get svc mysql
# TYPE: NodePort, PORT: 3306:30007/TCP ✅
```

### Step 6: Verify env vars are injected

```bash
POD=$(kubectl get pod -l app=mysql -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- env | grep MYSQL
# MYSQL_ROOT_PASSWORD=YUIidhb667
# MYSQL_DATABASE=kodekloud_db7
# MYSQL_USER=kodekloud_roy
# MYSQL_PASSWORD=ksH85UJjhb ✅
```

### Step 7: Test MySQL is working

```bash
kubectl exec $POD -- mysql -u kodekloud_roy -pksH85UJjhb -e "SHOW DATABASES;"
# kodekloud_db7 visible ✅
```

---

## 📌 Commands Reference

```bash
# Deploy all 7 resources
kubectl apply -f mysql-stack.yaml

# Full verification
kubectl get pv,pvc,secret,deployment,svc,pod

# Check secret values (decode)
kubectl get secret mysql-root-pass -o jsonpath='{.data.password}' | base64 -d
kubectl get secret mysql-user-pass -o jsonpath='{.data.username}' | base64 -d

# Check env vars in pod
POD=$(kubectl get pod -l app=mysql -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- env | grep MYSQL

# Test MySQL
kubectl exec $POD -- mysql -u kodekloud_roy -pksH85UJjhb -e "SHOW DATABASES;"

# Cleanup (entire stack)
kubectl delete -f mysql-stack.yaml
```

---

## ⚠️ Common Mistakes to Avoid

1. **Secret name in secretKeyRef doesn't match actual Secret name** — `secretKeyRef.name: mysql-root-pass` must exactly match the Secret's `metadata.name`. Mismatch → `CreateContainerConfigError`.
2. **Wrong key name in secretKeyRef** — `key: password` must match the key in the Secret's `data`/`stringData`. Case-sensitive.
3. **PVC capacity exceeding PV capacity** — Both are `250Mi` here — matching exactly is fine. PVC capacity must be ≤ PV capacity.
4. **Applying deployment before secrets** — If Secrets don't exist when Pod starts, `CreateContainerConfigError`. Apply Secrets before (or at same time via single YAML file) as the Deployment.
5. **Forgetting `matchLabels` ↔ `template.labels` alignment** — Deployment selector and Pod labels must match, or the Deployment never manages any Pods.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: Why are the MySQL credentials split across three separate Secrets instead of one?**

Separation of concerns and least-privilege access. The root password (`mysql-root-pass`) is the most privileged credential — only the DBA or operations team should access it. The application user credentials (`mysql-user-pass`) are accessed by the application deployment. The database URL/name (`mysql-db-url`) is less sensitive. By splitting them into separate Secrets, you can grant RBAC access independently: the app deployment service account can read `mysql-user-pass` and `mysql-db-url` but not `mysql-root-pass`. In a shared cluster with multiple teams, this prevents one team's application from accessing another team's database credentials.

---

**Q2: What is the difference between `stringData` and `data` in a Kubernetes Secret manifest?**

`data` requires values to be base64-encoded — Kubernetes stores them as-is. `stringData` accepts plain text values — Kubernetes automatically base64-encodes them before storing. They can be used in the same Secret manifest. `stringData` is more convenient when writing manifests manually (no manual encoding) and more readable in code review. However, plain text secrets in YAML files are a security risk regardless — even with `stringData`, the file should never be committed to Git. In production, use `kubectl create secret` imperatively or External Secrets Operator to avoid secrets in files entirely.

---

**Q3: What happens if a Secret referenced by `secretKeyRef` is deleted while the Pod is running?**

The Pod continues running using the env vars that were injected at startup — env vars are immutable for the Pod's lifetime. Deleting the Secret doesn't affect running Pods. However, if the Pod restarts (crash, node eviction, rolling update), it will fail to start because the referenced Secret no longer exists — `CreateContainerConfigError`. This is why Secret management in production uses GitOps or External Secrets Operator to ensure Secrets always exist before Pods that depend on them are created.

---

**Q4: Why use MySQL's official image environment variables for initialization instead of a ConfigMap with SQL scripts?**

The MySQL official Docker image supports initialization via environment variables (`MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`) which it processes on first startup to create the database, user, and set passwords automatically. This is simpler than writing initialization SQL scripts for basic setup. For complex initialization (schema creation, seed data, stored procedures), you'd mount SQL scripts at `/docker-entrypoint-initdb.d/` — MySQL executes all `.sql` files in that directory on first startup. The env var approach handles the 90% case; SQL scripts handle complex initialization.

---

**Q5: How would you upgrade the MySQL version without losing data?**

The PVC (`mysql-pv-claim`) holds the data files at `/var/lib/mysql`. Updating the Deployment's image from `mysql:8.0` to `mysql:8.1` triggers a rolling update — but for a single-replica database with a `ReadWriteOnce` PVC, the new Pod can't start until the old Pod releases the PVC (since RWO only allows one node to mount it). The safest approach: `kubectl scale deployment mysql-deployment --replicas=0` (stops MySQL, releases PVC), then update the image in the Deployment, then scale back to 1. MySQL automatically runs upgrade procedures on the data directory when the new version starts. Always take a database dump backup before version upgrades.

---

**Q6: How would you add database backup to this Kubernetes deployment?**

Several approaches: (1) **CronJob** — a Kubernetes CronJob runs `mysqldump` on a schedule, mounting the same PVC or connecting via the mysql Service, and uploads the dump to S3 or another storage. (2) **Sidecar container** — an additional container in the same Pod runs mysqldump periodically and ships the output to backup storage. (3) **Velero** — Kubernetes backup tool that snapshots PVCs using the cloud provider's snapshot API (AWS EBS snapshots for EBS-backed PVCs). (4) **MySQL Operator** — Operators like Oracle MySQL Operator or Percona XtraDB Cluster Operator include automated backup/restore as a built-in feature. For production, option 3 or 4 is standard — they handle the complexity of consistent database snapshots.

---

## 🔗 References

- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [secretKeyRef](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/)
- [MySQL Docker Image](https://hub.docker.com/_/mysql)
- [PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
