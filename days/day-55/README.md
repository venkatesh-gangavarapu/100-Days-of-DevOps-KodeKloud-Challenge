# Day 55 — Kubernetes Sidecar Pattern: Log Shipping with Shared emptyDir Volume

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Sidecar Pattern / Volumes  
**Difficulty:** Intermediate  
**Phase:** Phase 4 — AWS Core Services  
**Status:** ✅ Completed

---

## 📋 Task Summary

Implement the sidecar pattern for nginx log shipping:

- Pod: `webserver`
- Volume: `shared-logs` (`emptyDir`)
- Main container: `nginx-container` (`nginx:latest`) — writes logs to `/var/log/nginx`
- Sidecar container: `sidecar-container` (`ubuntu:latest`, init container with `restartPolicy: Always`) — reads and ships logs every 30 seconds

---

## 🧠 Concept — The Sidecar Pattern

### What is the Sidecar Pattern?

The sidecar pattern places a **helper container alongside the main application container** in the same Pod. The sidecar handles a cross-cutting concern — logging, monitoring, proxying, TLS termination — without modifying the main application.

```
Separation of concerns:
  nginx-container     → does one thing: serves web pages
  sidecar-container   → does one thing: ships logs

Shared concern:
  Both mount shared-logs at /var/log/nginx
  nginx writes → sidecar reads → ships to aggregation service
```

### Real Production Sidecar Examples

| Main Container | Sidecar | Purpose |
|---------------|---------|---------|
| Any app | Fluentd/Fluent Bit | Log forwarding |
| Any app | Envoy proxy | Service mesh (Istio) |
| Any app | Prometheus exporter | Metrics scraping |
| Any app | Vault agent | Secret injection |
| Web server | Git sync | Config/content sync |

### Sidecar as Init Container (K8s 1.28+)

Kubernetes 1.28 introduced native sidecar containers — implemented as **init containers with `restartPolicy: Always`**. This gives them unique behavior:

| Feature | Regular init container | Sidecar init container |
|---------|----------------------|----------------------|
| Runs before main containers | ✅ Yes | ✅ Yes (starts before) |
| Runs alongside main containers | ❌ Completes first | ✅ Yes — stays running |
| Restarts on crash | ❌ Pod fails | ✅ Yes |
| Receives SIGTERM on Pod deletion | ✅ After main containers | ✅ |

```yaml
initContainers:
  - name: sidecar-container
    image: ubuntu:latest
    restartPolicy: Always    ← makes this a sidecar, not a classic init
    command: [...]
```

### emptyDir as the Communication Channel

```
Node disk (emptyDir at /var/lib/kubelet/pods/<uid>/volumes/...)
           ↑ nginx writes               ↑ sidecar reads
           │                            │
    nginx-container              sidecar-container
    /var/log/nginx/              /var/log/nginx/
    access.log                   access.log  (same file)
    error.log                    error.log   (same file)
```

> **Real-world context:** The sidecar pattern is how service meshes like Istio work — Envoy proxy runs as a sidecar in every Pod, intercepting and managing all network traffic without the application knowing. Logging sidecars (Fluentd, Fluent Bit, Logstash) are deployed alongside applications to ship logs to ELK Stack, Splunk, or CloudWatch without any logging code in the application itself. Understanding this pattern is essential for working with modern Kubernetes infrastructure.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Access | Jump Host (kubectl pre-configured) |
| Pod name | `webserver` |
| Volume | `shared-logs` (emptyDir) |
| Main container | `nginx-container` (nginx:latest) |
| Sidecar container | `sidecar-container` (ubuntu:latest, init + restartPolicy: Always) |
| Volume mount path | `/var/log/nginx` (both containers) |
| Sidecar command | `cat` access + error logs every 30 seconds |

---

## 🔧 Solution — Step by Step

### The Pod manifest — `webserver.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webserver
spec:
  volumes:
    - name: shared-logs
      emptyDir: {}

  initContainers:
    - name: sidecar-container
      image: ubuntu:latest
      command:
        - "sh"
        - "-c"
        - "while true; do cat /var/log/nginx/access.log /var/log/nginx/error.log; sleep 30; done"
      restartPolicy: Always
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log/nginx

  containers:
    - name: nginx-container
      image: nginx:latest
      volumeMounts:
        - name: shared-logs
          mountPath: /var/log/nginx
```

### Step 1: Apply the manifest

```bash
kubectl apply -f webserver.yaml
```

### Step 2: Verify pod is running

```bash
kubectl get pod webserver
```

**Expected:**
```
NAME        READY   STATUS    RESTARTS   AGE
webserver   1/1     Running   0          30s
```

### Step 3: Check sidecar logs — confirms it's reading nginx logs

```bash
kubectl logs webserver -c sidecar-container
```

**Expected:** nginx access and error log output printed every 30 seconds.

### Step 4: Verify both containers are using the shared volume

```bash
kubectl describe pod webserver | grep -A 3 "Mounts"
```

### Step 5: Generate some nginx traffic to see in logs

```bash
kubectl exec webserver -c nginx-container -- curl -s http://localhost/
# Then check sidecar logs again
kubectl logs webserver -c sidecar-container
```

---

## 📌 Commands Reference

```bash
# ─── Deploy ──────────────────────────────────────────────
kubectl apply -f webserver.yaml

# ─── Verify ──────────────────────────────────────────────
kubectl get pod webserver
kubectl describe pod webserver

# ─── View sidecar logs (log shipper output) ──────────────
kubectl logs webserver -c sidecar-container
kubectl logs webserver -c sidecar-container -f    # Follow live

# ─── View nginx container logs ───────────────────────────
kubectl logs webserver -c nginx-container

# ─── Check shared volume content directly ────────────────
kubectl exec webserver -c nginx-container -- \
  ls -la /var/log/nginx/
kubectl exec webserver -c sidecar-container -- \
  ls -la /var/log/nginx/

# ─── Generate nginx traffic for log testing ──────────────
kubectl exec webserver -c nginx-container -- \
  curl -s http://localhost/

# ─── Cleanup ─────────────────────────────────────────────
kubectl delete pod webserver
```

---

## ⚠️ Common Mistakes to Avoid

1. **Using a regular container instead of init container for the sidecar** — The task explicitly requires `initContainers` with `restartPolicy: Always`. Without this, placing it under `containers` works but doesn't implement the native K8s sidecar pattern.
2. **Forgetting `restartPolicy: Always` on the init container** — Without it, the init container runs the while loop, finishes (if it ever does), and Kubernetes waits for it to complete before starting the main containers. A plain init container with an infinite loop would block nginx from ever starting.
3. **Different mount paths for the two containers** — Both must mount `shared-logs` at exactly `/var/log/nginx`. This is where nginx writes its logs — the sidecar must read from the same path. Different paths mean different directories on the same volume.
4. **Not checking sidecar logs to verify** — Always `kubectl logs webserver -c sidecar-container` to confirm the sidecar is reading and outputting the nginx log content.

---

## 🔍 Sidecar Init Container Lifecycle

```
Pod starts
    │
    ├── initContainers start (in order)
    │     └── sidecar-container starts (restartPolicy: Always)
    │           └── begins while loop — stays running
    │
    ├── containers start (after sidecar is Ready)
    │     └── nginx-container starts
    │           └── serves requests, writes to /var/log/nginx/
    │
    │   [Pod is fully running — READY 1/1]
    │
    │   sidecar reads logs every 30s  ←──────────────────┐
    │   nginx writes logs ────────────────────────────────┘
    │
Pod deletion
    ├── containers receive SIGTERM → graceful shutdown
    └── initContainers receive SIGTERM → graceful shutdown
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the sidecar pattern and why is it used instead of building logging into the main application?**

The sidecar pattern places a secondary container alongside the main container to handle cross-cutting concerns — logging, monitoring, security, proxying. It's preferred over building these concerns into the application for several reasons: separation of concerns (the application team owns app logic, the platform team owns observability), reusability (one Fluentd sidecar config works for any application), independent updates (update the log shipper without redeploying the application), and reduced coupling (the application just writes to a file; where those files go is the sidecar's problem). This aligns with the Unix philosophy that each component does one thing well.

---

**Q2: What is the difference between a classic init container and a sidecar init container in Kubernetes?**

A classic init container runs to completion before the main containers start — it's designed for setup tasks like database migrations, config population, or waiting for dependencies. It must exit with code 0 for Pod initialization to continue. A sidecar init container (init container with `restartPolicy: Always`, introduced in K8s 1.28) starts before the main containers but continues running alongside them for the Pod's entire lifetime. If it crashes, Kubernetes restarts it. It receives SIGTERM during Pod shutdown after the main containers. This native sidecar implementation gives sidecar containers proper lifecycle management that previously required workarounds.

---

**Q3: How does a service mesh like Istio use the sidecar pattern?**

Istio automatically injects an Envoy proxy sidecar container into every Pod in enrolled namespaces. This sidecar intercepts all inbound and outbound network traffic — transparent to the application. The sidecar handles TLS mutual authentication between services, circuit breaking, retries, timeouts, traffic shaping, and telemetry collection. The application communicates on localhost as if no proxy exists; Envoy handles the actual network communication. The entire service mesh — mTLS, observability, traffic management — is implemented without changing a single line of application code, purely through the sidecar pattern.

---

**Q4: Why use `emptyDir` for log sharing instead of a `hostPath` volume?**

`hostPath` mounts a directory from the node's filesystem into the Pod — it creates a dependency on a specific node and requires the directory to exist on every possible node. If the Pod is rescheduled to a different node, the log files from the old node aren't there. `emptyDir` is created fresh on whichever node the Pod lands on and moves with the Pod conceptually. For log shipping where the sidecar processes and forwards logs in real time (and doesn't need to persist them locally), `emptyDir` is the correct choice — ephemeral local storage shared between containers, independent of node-specific paths.

---

**Q5: What happens if the log files don't exist yet when the sidecar runs `cat`?**

`cat` returns an error if the file doesn't exist — "No such file or directory". In a tight while loop, this would print the error every 30 seconds until nginx creates the log files. In production, a more robust sidecar command would use `tail -f` to follow the file as it's created, or check for file existence first. Fluent Bit and Fluentd handle this gracefully by watching directories for file creation rather than reading specific filenames. For this task, nginx creates `access.log` and `error.log` almost immediately on startup, so the timing issue is brief.

---

**Q6: How would you implement log shipping to a real centralized logging system in production?**

Replace the `cat` command with a proper log shipper. For ELK Stack: run Fluent Bit as the sidecar, configured to read from `/var/log/nginx/` and forward to Elasticsearch. For AWS CloudWatch: run the CloudWatch agent as a sidecar. The sidecar approach works but the more scalable production pattern is a DaemonSet — one Fluentd or Fluent Bit Pod per node that reads log files from all Pods on that node via `hostPath`. This avoids adding a sidecar to every single application Pod. DaemonSet-based logging is the standard in most managed Kubernetes environments (EKS, GKE, AKS), while sidecar logging is used when per-application log routing customization is needed.

---

## 🔗 References

- [Kubernetes Sidecar Containers (K8s 1.28+)](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/)
- [Kubernetes — Logging Architecture](https://kubernetes.io/docs/concepts/cluster-administration/logging/)
- [emptyDir Volume](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)
- [Sidecar Pattern — Microsoft](https://learn.microsoft.com/en-us/azure/architecture/patterns/sidecar)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
