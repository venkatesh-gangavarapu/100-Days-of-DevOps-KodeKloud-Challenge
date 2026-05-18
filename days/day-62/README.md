# Day 62 — Kubernetes Secrets: Storing & Mounting Sensitive Data

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Secrets / Configuration  
**Difficulty:** Intermediate  
**Phase:** Phase 5 — Advanced Kubernetes & CI/CD  
**Status:** ✅ Completed

---

## 📋 Task Summary

1. Create a generic Secret `news` from `/opt/news.txt`
2. Create Pod `secret-xfusion` with container `secret-container-xfusion` (debian:latest)
3. Mount the secret at `/opt/apps` inside the container
4. Verify the secret is accessible inside the container

---

## 🧠 Concept — Kubernetes Secrets

### What is a Kubernetes Secret?

A Secret stores sensitive data (passwords, tokens, keys, certificates) separately from Pod specs and container images. Secrets are base64-encoded and stored in etcd. Pods consume them as environment variables or mounted files.

```
Secret: news
  └── news.txt: <base64-encoded licence key>
          │
          ▼ mounted as file
Pod: secret-xfusion
  └── Container: secret-container-xfusion
        └── /opt/apps/news.txt  ← secret file accessible here
```

### Why Secrets Instead of ConfigMaps?

| Aspect | ConfigMap | Secret |
|--------|-----------|--------|
| Data type | Non-sensitive config | Sensitive data |
| Encoding | Plain text | Base64 encoded |
| etcd storage | Plain | Encrypted at rest (if configured) |
| RBAC control | Standard | Can be separately restricted |
| Use case | App config, flags | Passwords, tokens, certs |

### Ways to Create a Secret

```bash
# From a file (today's task)
kubectl create secret generic news --from-file=/opt/news.txt

# From literal value
kubectl create secret generic news --from-literal=password=MySecret123

# From multiple files
kubectl create secret generic tls-certs \
  --from-file=tls.crt --from-file=tls.key

# From a YAML manifest (values must be base64-encoded)
kubectl apply -f secret.yaml
```

### Ways to Consume a Secret in a Pod

```yaml
# Method 1: Volume mount (today's task)
# Secret keys become files at the mount path
volumes:
  - name: secret-volume
    secret:
      secretName: news
containers:
  - volumeMounts:
      - name: secret-volume
        mountPath: /opt/apps
# Result: /opt/apps/news.txt contains the secret value

# Method 2: Environment variable
env:
  - name: LICENCE_KEY
    valueFrom:
      secretKeyRef:
        name: news
        key: news.txt
# Result: $LICENCE_KEY = secret value
```

### What the Volume Mount Creates

When a Secret is mounted as a volume, each key in the Secret becomes a **file** in the mount directory:

```
Secret: news
  key: news.txt → value: <licence content>

Mounted at /opt/apps:
  /opt/apps/news.txt   ← file containing the secret value
```

> **Real-world context:** Kubernetes Secrets are how every production application handles sensitive configuration. Database passwords, API tokens, TLS certificates, OAuth client secrets — all stored as Secrets and consumed by Pods without ever appearing in Docker images or Kubernetes YAML files committed to Git. For higher security, organizations integrate with external secret managers (HashiCorp Vault, AWS Secrets Manager) using the Secrets Store CSI Driver or Vault Agent — but the Pod-level consumption mechanism remains identical.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Source file | `/opt/news.txt` |
| Secret name | `news` |
| Secret type | `generic` |
| Pod name | `secret-xfusion` |
| Container | `secret-container-xfusion` (debian:latest) |
| Mount path | `/opt/apps` |

---

## 🔧 Solution — Step by Step

### Step 1: Read the source file

```bash
cat /opt/news.txt
```

### Step 2: Create the Secret from the file

```bash
kubectl create secret generic news --from-file=/opt/news.txt
```

**Expected:**
```
secret/news created
```

### Step 3: Verify Secret

```bash
kubectl get secret news
# TYPE: Opaque, DATA: 1

[Okubectl describe secret news
# Shows key name (news.txt) but NOT the value — intentionally hidden
```

### Step 4: The Pod manifest — `secret-xfusion.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-xfusion
spec:
  containers:
    - name: secret-container-xfusion
      image: debian:latest
      command: ["sleep", "3600"]
      volumeMounts:
        - name: secret-volume
          mountPath: /opt/apps
  volumes:
    - name: secret-volume
      secret:
        secretName: news
```

### Step 5: Apply the Pod

```bash
kubectl apply -f secret-xfusion.yaml
```

### Step 6: Verify Pod is Running

```bash
kubectl get pod secret-xfusion
# STATUS: Running, READY: 1/1 ✅
```

### Step 7: Verify secret is accessible inside the container

```bash
kubectl exec secret-xfusion -c secret-container-xfusion -- ls /opt/apps/
# Expected: news.txt

kubectl exec secret-xfusion -c secret-container-xfusion -- cat /opt/apps/news.txt
# Expected: the licence/password content ✅
```

---

## 📌 Commands Reference

```bash
# ─── Create secret ───────────────────────────────────────
kubectl create secret generic news --from-file=/opt/news.txt

# ─── Inspect secret ──────────────────────────────────────
kubectl get secret news
kubectl describe secret news               # shows keys, not values
kubectl get secret news -o yaml            # shows base64-encoded values
kubectl get secret news -o jsonpath='{.data.news\.txt}' | base64 -d  # decode

# ─── Deploy pod ──────────────────────────────────────────
kubectl apply -f secret-xfusion.yaml
kubectl get pod secret-xfusion

# ─── Verify mount ────────────────────────────────────────
kubectl exec secret-xfusion -c secret-container-xfusion -- ls /opt/apps/
kubectl exec secret-xfusion -c secret-container-xfusion -- cat /opt/apps/news.txt

# ─── Cleanup ─────────────────────────────────────────────
kubectl delete pod secret-xfusion
kubectl delete secret news
```

---

## ⚠️ Common Mistakes to Avoid

1. **Using `--from-literal` vs `--from-file`** — `--from-file=/opt/news.txt` creates a key named `news.txt` with the file content as the value. `--from-literal=news.txt=content` also works but the key name must be specified manually. For this task, `--from-file` is correct.
2. **Wrong `secretName` in Pod volume** — The volume references `secretName: news` — this must exactly match the Secret name. A typo causes `CreateContainerConfigError`.
3. **Not specifying `command: ["sleep", "3600"]`** — Debian has no default long-running command. Without a keep-alive command, the container exits immediately and enters `CrashLoopBackOff`.
4. **Forgetting `-c container-name` in exec** — Always specify `-c secret-container-xfusion` when exec-ing into the pod.
5. **Confusing volume name vs Secret name** — `volumes[].name` is an internal reference name (can be anything). `volumes[].secret.secretName` must match the actual Kubernetes Secret name (`news`).

---

## 🔍 Secret Storage — Under the Hood

```
kubectl create secret → API server → etcd (base64 + encrypted at rest)

kubectl get secret -o yaml shows:
  data:
    news.txt: dGhpcyBpcyBhIHNlY3JldAo=  ← base64 encoded

Decode: echo "dGhpcyBpcyBhIHNlY3JldAo=" | base64 -d
        → this is a secret

Pod mounts the Secret:
  kubelet fetches from API server → writes to tmpfs on node
  Mounted as /opt/apps/news.txt inside container
  tmpfs = RAM, never written to node disk ← security benefit
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is a Kubernetes Secret and how does it differ from a ConfigMap?**

A ConfigMap stores non-sensitive configuration data — feature flags, service URLs, config files. It's stored as plain text in etcd and readable by anyone with `kubectl get configmap` access. A Secret stores sensitive data — passwords, tokens, private keys, certificates. Secrets are base64-encoded (not encrypted by default, but encryption at rest can be configured) and stored in etcd with tighter RBAC controls. When mounted as volumes, Secret files are stored in `tmpfs` (RAM) on the node, never written to node disk. The primary operational difference is access control — Secrets should have more restrictive RBAC policies than ConfigMaps.

---

**Q2: Is base64 encoding in Kubernetes Secrets actually secure?**

Base64 is encoding, not encryption — it's trivially reversible. By itself, it provides no security. What makes Secrets more secure than ConfigMaps is: (1) RBAC — you can grant read access to ConfigMaps while denying Secret access to developers. (2) Encryption at rest — Kubernetes supports encrypting Secret data in etcd using a KMS provider (AWS KMS, GCP KMS, Azure Key Vault). With this enabled, Secrets are genuinely encrypted on disk. (3) `tmpfs` mounting — Secret volumes are mounted in RAM on the node, not written to disk. (4) Audit logging — Secret access can be separately audited. Without encryption at rest, a Secret is only as secure as etcd access control. Best practice: always enable encryption at rest for Secrets in production.

---

**Q3: What is the difference between consuming a Secret as a volume vs as an environment variable?**

As a volume: Secret keys become files at the mount path. Changes to the Secret are eventually reflected in the mounted files (without Pod restart) — Kubernetes syncs updates within ~1 minute. Files in `/opt/apps/` are readable by the container process. As environment variables: Secret values are injected at Pod creation time and are immutable for the Pod's lifetime — a Secret update doesn't propagate to running Pods. Env vars are visible in `kubectl describe pod` output, process listings, and crash dumps — a security concern. Volume mounts are generally preferred for sensitive data because they update live, aren't exposed in process environment dumps, and are written to `tmpfs`.

---
[I
**Q4: How do you rotate a Kubernetes Secret without downtime?**

Update the Secret: `kubectl apply -f updated-secret.yaml` or `kubectl edit secret news`. For volume-mounted Secrets, Kubernetes automatically syncs the updated values to running Pods within the kubelet's sync period (default ~1 minute) — no Pod restart required. The application must re-read the file to pick up the new value; most applications that read config files at startup need a restart. For env var-based Secrets, the Pod must be restarted to pick up new values. For zero-downtime rotation: update the Secret, trigger a rolling restart (`kubectl rollout restart deployment/myapp`), which replaces Pods one at a time using the new Secret value.

---

**Q5: What is the Secrets Store CSI Driver and when would you use it?**

The Secrets Store CSI Driver integrates external secret managers (AWS Secrets Manager, HashiCorp Vault, Azure Key Vault, GCP Secret Manager) directly with Kubernetes. Instead of manually creating Kubernetes Secrets, the CSI driver fetches secrets from the external manager at Pod mount time and presents them as volume files. Benefits: secrets live in a purpose-built secret manager (audit logs, access control, rotation), never stored in etcd, automatically rotated. The Pod YAML references a `SecretProviderClass` resource instead of a Kubernetes Secret. This is the recommended approach for production Kubernetes in organizations that use AWS Secrets Manager or HashiCorp Vault — it eliminates the need to sync external secrets into Kubernetes manually.

---

**Q6: How would you prevent a Secret from being accidentally committed to Git?**

Multiple approaches: (1) Never put Secret YAML with values in Git — use `--from-file` or `--from-literal` commands in scripts instead. (2) Encrypt Secret YAML with Sealed Secrets (Bitnami) — the `SealedSecret` resource is safe to commit; the cluster's private key decrypts it at apply time. (3) Use External Secrets Operator — Secret values live in AWS Secrets Manager/Vault; the operator syncs them to Kubernetes Secrets automatically; Git only contains the `ExternalSecret` manifest with a reference, not the value. (4) Use SOPS (Mozilla) to encrypt YAML files with KMS before committing. The most common production pattern is External Secrets Operator with AWS Secrets Manager or HashiCorp Vault.

---

## 🔗 References

- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Using Secrets as Volumes](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-files-from-a-pod)
- [Encrypting Secret Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)
- [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
