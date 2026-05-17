# Day 61 — Kubernetes Init Containers: Pre-Populating Shared Volume Data

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Init Containers / Volumes  
**Difficulty:** Intermediate  
**Phase:** Phase 5 — Advanced Kubernetes & CI/CD  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create a Deployment `ic-deploy-xfusion` with:
- Init container `ic-msg-xfusion` (ubuntu:latest) — writes message to `/ic/blog`
- Main container `ic-main-xfusion` (ubuntu:latest) — reads `/ic/blog` every 5 seconds
- Shared `emptyDir` volume `ic-volume-xfusion` mounted at `/ic` in both containers

---

## 🧠 Concept — Init Containers

### What is an Init Container?

An init container runs **before** the main container(s) start. It must complete successfully (exit 0) before Kubernetes starts the main containers. If the init container fails, Kubernetes restarts it according to the Pod's restartPolicy.

```
Pod lifecycle with init container:

  Init container starts
        │
        ▼
  Init container completes (exit 0)
        │
        ▼
  Main container(s) start
        │
        ▼
  Pod is Running ✅
```

### Init Container vs Sidecar Container

| Feature | Init Container | Sidecar (init + restartPolicy:Always) |
|---------|---------------|--------------------------------------|
| Runs before main | ✅ Yes | ✅ Yes |
| Runs alongside main | ❌ Exits first | ✅ Yes |
| Purpose | Setup, prerequisites | Ongoing helper task |
| Today's pattern | ✅ | No |

### Classic Init Container Use Cases

| Use Case | What Init Container Does |
|----------|------------------------|
| **This task** | Write config/data to shared volume |
| Database migration | Run `db migrate` before app starts |
| Dependency wait | Loop until a service is ready |
| Secret injection | Pull secrets from vault into a file |
| Config generation | Render templates into config files |
| Permission fix | `chmod`/`chown` shared directories |

### The Shared Volume Pattern

```
Init container                 Main container
     │                              │
     │  writes /ic/blog             │  reads /ic/blog every 5s
     │                              │
     └──────► emptyDir ◄────────────┘
              /ic volume
```

Init writes → exits → main starts → reads. Because `emptyDir` persists for the Pod's lifetime (not just a container's lifetime), the file written by the init container is available to the main container when it starts.

> **Real-world context:** Init containers are how Kubernetes applications handle bootstrapping tasks that must complete before the app can start. Database schema migrations, waiting for dependencies (using `until nslookup db-service; do sleep 1; done`), generating TLS certificates, pulling configuration from external sources — all are handled cleanly by init containers without modifying the main application image.

---

## 🔧 The Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ic-deploy-xfusion
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ic-xfusion
  template:
    metadata:
      labels:
        app: ic-xfusion
    spec:
      initContainers:
        - name: ic-msg-xfusion
          image: ubuntu:latest
          command:
            - '/bin/bash'
            - '-c'
            - 'echo Init Done - Welcome to xFusionCorp Industries > /ic/blog'
          volumeMounts:
            - name: ic-volume-xfusion
              mountPath: /ic

      containers:
        - name: ic-main-xfusion
          image: ubuntu:latest
          command:
            - '/bin/bash'
            - '-c'
            - 'while true; do cat /ic/blog; sleep 5; done'
          volumeMounts:
            - name: ic-volume-xfusion
              mountPath: /ic

      volumes:
        - name: ic-volume-xfusion
          emptyDir: {}
```

---

## 🔧 Solution — Step by Step

### Step 1: Apply the Deployment

```bash
kubectl apply -f ic-deploy-xfusion.yaml
```

### Step 2: Watch the init container run

```bash
kubectl get pods -w
```

**Expected sequence:**
```
NAME                              READY   STATUS            RESTARTS
ic-deploy-xfusion-xxx-yyy         0/1     Init:0/1          0    ← init running
ic-deploy-xfusion-xxx-yyy         0/1     PodInitializing   0    ← init done
ic-deploy-xfusion-xxx-yyy         1/1     Running           0    ← main up ✅
```

### Step 3: Verify Deployment

```bash
kubectl get deployment ic-deploy-xfusion
# READY: 1/1 ✅
```

### Step 4: Check main container output

```bash
POD=$(kubectl get pod -l app=ic-xfusion -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD -c ic-main-xfusion
# Expected: Init Done - Welcome to xFusionCorp Industries
```

### Step 5: Follow live output

```bash
kubectl logs $POD -c ic-main-xfusion -f
# Prints every 5 seconds ✅
```

---

## 📌 Commands Reference

```bash
# Apply
kubectl apply -f ic-deploy-xfusion.yaml

# Watch pod startup sequence
kubectl get pods -w

# Get pod name
POD=$(kubectl get pod -l app=ic-xfusion -o jsonpath='{.items[0].metadata.name}')

# Check init container logs
kubectl logs $POD -c ic-msg-xfusion

# Check main container logs
kubectl logs $POD -c ic-main-xfusion
kubectl logs $POD -c ic-main-xfusion -f   # follow

# Describe pod (shows init container state)
kubectl describe pod $POD

# Verify volume mount
kubectl exec $POD -c ic-main-xfusion -- cat /ic/blog
```

---

## ⚠️ Common Mistakes to Avoid

1. **Init container in `containers` instead of `initContainers`** — Placing the init container under `containers` makes it a regular container — it runs in parallel with the main container, not sequentially. Both would start at the same time and the main container might read the file before it's written.
2. **Volume name mismatch** — `volumeMounts[].name` must match `volumes[].name` exactly. A mismatch means the mount silently fails — no shared storage.
3. **Missing `matchLabels` in selector** — The Deployment's `selector.matchLabels` must match `template.metadata.labels`. A mismatch causes the Deployment to be rejected.
4. **Quoting the command incorrectly** — Each command element must be a separate list item. `command: ['/bin/bash', '-c', 'echo ...']` is correct. Putting the whole command in one string fails.
5. **Not specifying `-c ic-main-xfusion` in logs** — When a Pod has multiple containers (including init), always specify `-c container-name` to see the right logs.

---

## 🔍 Init Container Status in `kubectl describe`

```
Init Containers:
  ic-msg-xfusion:
    State:          Terminated
      Reason:       Completed
      Exit Code:    0           ← success
    Ready:          True

Containers:
  ic-main-xfusion:
    State:          Running
    Ready:          True
```

`Terminated: Completed, Exit Code: 0` confirms the init container succeeded. The main container only started after this.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is an init container and how does it differ from a regular container?**

An init container runs before any regular containers in the Pod and must complete successfully (exit 0) before regular containers start. Unlike regular containers, init containers run sequentially (multiple init containers run one after another, not in parallel). They share the same volume mounts and network namespace as the Pod. They're designed for setup tasks — bootstrapping configuration, waiting for dependencies, running migrations — that must complete before the application is ready to start. Regular containers run in parallel with each other and stay running for the Pod's lifetime. Init containers exit after their task is done.

---

**Q2: What happens if an init container fails?**

If an init container exits with a non-zero code, Kubernetes restarts it according to the Pod's `restartPolicy`. With `restartPolicy: Always` (default for Deployments), Kubernetes keeps restarting the failing init container with exponential backoff — similar to `CrashLoopBackOff` for regular containers. The main containers never start until all init containers have succeeded. `kubectl describe pod` shows the init container state and restart count. The fix is to correct whatever the init container is trying to do — bad command, missing dependency, insufficient permissions. If an init container is waiting for a service, it loops until the service is available.

---

**Q3: How do multiple init containers work — do they run in parallel?**

Multiple init containers run sequentially — in the order they're defined in the manifest. Init container 1 must complete successfully before init container 2 starts, which must complete before init container 3 starts, and so on. Only after all init containers have completed successfully do the regular containers start. This sequential guarantee is what makes init containers useful for ordered setup: first wait for the database to be ready, then run migrations, then start the application. All three steps are guaranteed to happen in the correct order.

---

**Q4: How would you use an init container to wait for a dependency before starting the main app?**

A common pattern uses `nslookup` or `curl` to poll until a service is available:

```yaml
initContainers:
  - name: wait-for-db
    image: busybox
    command:
      - '/bin/sh'
      - '-c'
      - 'until nslookup postgres-service; do echo waiting for db; sleep 2; done'
```

This init container loops — polling every 2 seconds — until `postgres-service` DNS resolves successfully. Once it does, the init container exits 0, and the main application starts knowing the database is reachable. Without this pattern, the application might start, fail to connect to the database, and crash — causing `CrashLoopBackOff` while the database is still initializing.

---

**Q5: What data persists between the init container and main container via emptyDir?**

`emptyDir` is scoped to the Pod's lifetime, not to individual containers. When an init container writes to an `emptyDir`-backed mount and exits, the data remains in the volume. When the main container starts and mounts the same `emptyDir` at any path, it sees all the data the init container wrote. This is the standard mechanism for init containers to pass data to main containers — config files, secrets fetched from external sources, pre-computed data. The data survives individual container restarts within the Pod but is lost when the Pod itself is deleted (because `emptyDir` is Pod-scoped, not persistent).

---

**Q6: How does an init container differ from a Kubernetes Job?**

A Kubernetes Job runs a Pod to completion independently — it's not tied to another Pod's lifecycle. Jobs are used for standalone batch tasks: data processing, report generation, periodic cleanup. An init container is tied to its Pod — it runs as part of the Pod's initialization, before the main containers start. Init containers are for setup tasks that must happen before the application in the same Pod is ready. Jobs are for independent tasks that produce a result or trigger an effect independently of any running application. Both run containers to completion, but init containers are Pod-scoped setup steps while Jobs are standalone workloads.

---

## 🔗 References

- [Kubernetes Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [Init Container Patterns](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-initialization/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
