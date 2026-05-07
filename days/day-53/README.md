# Day 53 — Kubernetes Troubleshooting: Fixing nginx + PHP-FPM Pod

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Troubleshooting / Multi-Container Pods  
**Difficulty:** Intermediate  
**Phase:** Phase 4 — AWS Core Services  
**Status:** ✅ Completed

---

## 📋 Task Summary

The `nginx-phpfpm` Pod was broken. Diagnose the issue using `kubectl describe`, logs, and ConfigMap inspection. Fix it, then copy `/home/thor/index.php` to the nginx document root inside the pod.

---

## 🧠 Concept — Multi-Container Pods & ConfigMaps

### Multi-Container Pod — Shared Network Namespace

In a multi-container Pod, all containers share the same network namespace — the same IP address and port space. This means nginx and php-fpm communicate via **localhost**, not via a service name or separate IP.

```
Pod: nginx-phpfpm
  ├── Container: nginx-container
  │     └── listens on :80
  │           └── fastcgi_pass → 127.0.0.1:9000 ✅  (correct)
  │                              OR
  │                              wrong-host:9000  ❌  (broken)
  │
  └── Container: php-fpm-container
        └── listens on :9000
```

If `fastcgi_pass` points to anything other than `127.0.0.1:9000`, nginx can't reach php-fpm — resulting in 502 Bad Gateway.

### ConfigMaps as nginx Config

nginx configuration is injected via a ConfigMap mounted as a volume. When the ConfigMap has an error, fixing it and restarting the pod picks up the corrected config.

### `kubectl cp` for File Transfer

```bash
kubectl cp <source> <pod>:<destination> -c <container>

# Host → Container
kubectl cp /home/thor/index.php nginx-phpfpm:/var/www/html/index.php -c nginx-container

# Container → Host
kubectl cp nginx-phpfpm:/var/www/html/index.php ./index.php -c nginx-container
```

---

## 🔧 Solution — Step by Step

### Step 1: Check pod status

```bash
kubectl get pod nginx-phpfpm
kubectl describe pod nginx-phpfpm
```

Look for: container states, restart counts, events at the bottom.

### Step 2: Check container logs

```bash
kubectl logs nginx-phpfpm -c nginx-container
kubectl logs nginx-phpfpm -c php-fpm-container
```

nginx logs often show the exact error — `connect() failed`, `502`, or config parse errors.

### Step 3: Inspect the ConfigMap

```bash
kubectl get configmap nginx-config -o yaml
```

Look for `fastcgi_pass` — it must be `127.0.0.1:9000` for a multi-container Pod.

**Common broken config:**
```nginx
fastcgi_pass wrong-service:9000;   ← ❌ can't resolve in same pod
```

**Correct config:**
```nginx
fastcgi_pass 127.0.0.1:9000;      ← ✅ localhost, shared network namespace
```

### Step 4: Fix the ConfigMap

```bash
kubectl edit configmap nginx-config
```

Change the `fastcgi_pass` value to `127.0.0.1:9000` and save.

### Step 5: Restart the pod to pick up changes

```bash
kubectl delete pod nginx-phpfpm
```

If the pod is managed by a controller (Deployment/ReplicaSet), it recreates automatically. If it's a bare pod, recreate manually from the original manifest.

### Step 6: Verify pod is running

```bash
kubectl get pod nginx-phpfpm
```

Wait for `Running` state.

### Step 7: Copy index.php to the container

```bash
kubectl cp /home/thor/index.php nginx-phpfpm:/var/www/html/index.php -c nginx-container
```

### Step 8: Verify file was copied

```bash
kubectl exec -it nginx-phpfpm -c nginx-container -- ls -la /var/www/html/
```

### Step 9: Access the website

Click the **Website** button on the top bar — should serve the PHP page. ✅

---

## 📌 Commands Reference

```bash
# ─── Diagnose ────────────────────────────────────────────
kubectl get pod nginx-phpfpm
kubectl describe pod nginx-phpfpm
kubectl logs nginx-phpfpm -c nginx-container
kubectl logs nginx-phpfpm -c php-fpm-container
kubectl get configmap nginx-config -o yaml

# ─── Fix ConfigMap ───────────────────────────────────────
kubectl edit configmap nginx-config
# Change fastcgi_pass to: 127.0.0.1:9000

# ─── Restart pod ─────────────────────────────────────────
kubectl delete pod nginx-phpfpm

# ─── Copy file ───────────────────────────────────────────
kubectl cp /home/thor/index.php \
  nginx-phpfpm:/var/www/html/index.php -c nginx-container

# ─── Verify ──────────────────────────────────────────────
kubectl get pod nginx-phpfpm
kubectl exec nginx-phpfpm -c nginx-container -- ls /var/www/html/
kubectl exec nginx-phpfpm -c nginx-container -- cat /var/www/html/index.php
```

---

## ⚠️ Common Mistakes to Avoid

1. **Not specifying `-c container-name` with `kubectl cp`** — In multi-container Pods, you must specify which container with `-c`. Without it, kubectl uses the first container which may not be nginx.
2. **Expecting ConfigMap changes to auto-update the running pod** — ConfigMap volume mounts eventually sync (with some delay), but for nginx to pick up the new config it needs to reload. Deleting the pod is the safest way to force a fresh start with the updated ConfigMap.
3. **Wrong document root in kubectl cp** — The task says copy to nginx document root. Check the nginx config for `root` directive — it might be `/usr/share/nginx/html` or `/var/www/html`. Match exactly.
4. **Not checking logs in both containers** — A multi-container pod failure can originate from either container. Always check logs in all containers before assuming which one is broken.

---

## 🔍 Multi-Container Pod Networking

```
Pod IP: 10.244.1.5

Container: nginx-container
  eth0: 10.244.1.5:80    ← same IP as pod
  fastcgi to: 127.0.0.1:9000  ← loopback to php-fpm

Container: php-fpm-container
  eth0: 10.244.1.5:9000  ← same IP — shared namespace
  127.0.0.1:9000 == this container ✅
```

Both containers share `eth0`. `127.0.0.1` inside one container is the same loopback as inside the other. This is fundamentally different from separate Pods where you'd need a Service.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: Why do nginx and PHP-FPM communicate via `127.0.0.1` in a multi-container Pod?**

All containers within the same Pod share the same network namespace — same IP address, same loopback interface, same port space. This means `127.0.0.1` inside the nginx container is identical to `127.0.0.1` inside the php-fpm container. They're on the same loopback. This is by design — sidecar patterns like nginx+phpfpm, application+logging-agent, and application+service-mesh-proxy all rely on this shared network namespace for low-latency local communication. If nginx and phpfpm were in separate Pods, you'd need a Kubernetes Service and the connection string would be a DNS hostname, not localhost.

---

**Q2: How do you update a ConfigMap that's mounted as a volume in a running Pod?**

`kubectl edit configmap` or `kubectl apply -f updated-configmap.yaml` updates the ConfigMap in the API server. For ConfigMaps mounted as volumes, Kubernetes syncs the updated content to the Pod's filesystem eventually — typically within 1-2 minutes, depending on `kubelet` sync frequency. However, the application inside the container (nginx in this case) won't automatically reload its config just because the file changed. nginx requires either a `nginx -s reload` signal or a container restart to pick up changes. The safest approach is to delete the Pod after updating the ConfigMap — the new Pod starts with the fresh config from the start.

---

**Q3: What is the difference between `kubectl exec` and `kubectl cp`?**

`kubectl exec` runs a command inside a running container — it requires the container to be alive and executes within its process environment. `kubectl cp` transfers files between the host and a container's filesystem — it works by running `tar` inside the container behind the scenes, so the container must be running and have `tar` available. For multi-container Pods, both commands require `-c container-name` to specify which container. `kubectl cp` is the correct tool for one-time file transfers; for ongoing file management, volume mounts are more appropriate.

---

**Q4: How would you debug a Pod stuck in `CrashLoopBackOff`?**

`kubectl describe pod <name>` shows the last termination reason and exit code — a non-zero exit code indicates the main process crashed, and the reason gives context (OOMKilled, Error, etc.). `kubectl logs <pod>` shows current container stdout/stderr. `kubectl logs <pod> --previous` shows the logs from the previous (crashed) container instance — critical because current logs may be empty if the container crashes immediately on start. For a completely broken container that crashes before outputting any logs, temporarily change the container's `command` to `["sleep", "3600"]` to keep it running, then `kubectl exec` into it to investigate the filesystem and manually run the failing command.

---

**Q5: What is a ConfigMap in Kubernetes and what are its limitations?**

A ConfigMap stores non-sensitive configuration data as key-value pairs or as file content, decoupled from the Pod spec. Pods consume ConfigMaps as environment variables, command-line arguments, or mounted files. Limitations: (1) Not for sensitive data — use Secrets instead (though Secrets have their own limitations). (2) Size limit of 1MB per ConfigMap. (3) Updates don't hot-reload applications — the application must be restarted or designed to watch for file changes. (4) ConfigMaps are namespace-scoped — a Pod can only use ConfigMaps in its own namespace. (5) Mounted volume syncs are eventually consistent, not instantaneous.

---

**Q6: How do you check which containers are in a multi-container Pod?**

`kubectl get pod nginx-phpfpm -o jsonpath='{.spec.containers[*].name}'` lists all container names. `kubectl describe pod nginx-phpfpm` shows each container's details including image, state, and resource limits in separate sections. `kubectl get pod nginx-phpfpm -o yaml` gives the full spec. For operational commands that need a container name (`kubectl logs -c`, `kubectl exec -c`, `kubectl cp -c`), always check the container names first — guessing wrong silently uses the first container or returns an error.

---

## 🔗 References

- [Kubernetes Multi-Container Pods](https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers)
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [`kubectl cp` documentation](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#cp)
- [Debugging Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
