# Day 57 — Kubernetes Environment Variables: Injecting Config into Pods

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Kubernetes / Environment Variables / Configuration  
**Difficulty:** Beginner  
**Phase:** Phase 4 — AWS Core Services  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create a Pod that uses three environment variables to print a greeting message:

- Pod: `print-envars-greeting`
- Container: `print-env-container` (bash image)
- Env vars: `GREETING=Welcome to`, `COMPANY=DevOps`, `GROUP=Industries`
- Command: `echo "$(GREETING) $(COMPANY) $(GROUP)"`
- restartPolicy: `Never`

**Expected output:** `Welcome to DevOps Industries`

---

## 🧠 Concept — Environment Variables in Kubernetes

### Why Environment Variables?

Environment variables are the standard mechanism for injecting runtime configuration into containers — database URLs, API keys, feature flags, service addresses. They follow the 12-Factor App principle: config belongs in the environment, not in code or images.

```
Hard-coded in image (bad):       Injected via env var (good):
COPY config.json /app/           env:
# Fixed at build time              - name: DB_HOST
# Different image per env            value: "postgres-service"
# Secrets in the image             # Changed per environment
```

### Env Var Sources in Kubernetes

| Source | YAML | Use case |
|--------|------|---------|
| Literal value | `value: "Welcome to"` | Static config |
| ConfigMap key | `valueFrom: configMapKeyRef` | Shared non-sensitive config |
| Secret key | `valueFrom: secretKeyRef` | Passwords, tokens, keys |
| Pod field | `valueFrom: fieldRef` | Pod name, namespace, IP |
| Resource field | `valueFrom: resourceFieldRef` | CPU/memory limits |

### `restartPolicy: Never` — Run-to-Completion Pods

```
restartPolicy: Always   ← default, restart on any exit (Deployment Pods)
restartPolicy: OnFailure ← restart only on non-zero exit (batch jobs)
restartPolicy: Never    ← never restart — run once and done
```

For one-shot tasks (scripts, data migrations, test jobs), `Never` is correct. Without it, the container exits after `echo`, Kubernetes restarts it, it exits again — `CrashLoopBackOff` within seconds even though the task succeeded perfectly.

### Shell Variable Expansion in CMD

```yaml
command: ["/bin/sh", "-c", 'echo "$(GREETING) $(COMPANY) $(GROUP)"']
```

The shell (`/bin/sh -c`) handles `$(VAR)` expansion. The single quotes prevent the jump host's shell from expanding the variables before passing to Kubernetes — the literal string `$(GREETING)` goes into the Pod spec, and the container's shell expands it at runtime using the env vars set in the Pod spec.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Pod name | `print-envars-greeting` |
| Container | `print-env-container` (bash) |
| GREETING | `Welcome to` |
| COMPANY | `DevOps` |
| GROUP | `Industries` |
| restartPolicy | `Never` |

---

## 🔧 The Manifest

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: print-envars-greeting
spec:
  restartPolicy: Never
  containers:
    - name: print-env-container
      image: bash
      env:
        - name: GREETING
          value: "Welcome to"
        - name: COMPANY
          value: "DevOps"
        - name: GROUP
          value: "Industries"
      command: ["/bin/sh", "-c", 'echo "$(GREETING) $(COMPANY) $(GROUP)"']
```

### Apply and verify

```bash
kubectl apply -f print-envars-greeting.yaml
kubectl get pod print-envars-greeting
# STATUS: Completed (ran once, exited cleanly with restartPolicy: Never)

kubectl logs -f print-envars-greeting
# Welcome to DevOps Industries ✅
```

---

## 📌 Commands Reference

```bash
kubectl apply -f print-envars-greeting.yaml
kubectl get pod print-envars-greeting
kubectl logs -f print-envars-greeting
kubectl describe pod print-envars-greeting
kubectl delete pod print-envars-greeting
```

---

## ⚠️ Common Mistakes to Avoid

1. **Missing `restartPolicy: Never`** — Container exits after echo, Kubernetes restarts it in a loop — CrashLoopBackOff. Always set `Never` for run-to-completion tasks.
2. **Using double quotes in command string** — `'echo "$(GREETING)..."'` — single quotes in the YAML value prevent the local shell from expanding variables. The container's shell does the expansion at runtime.
3. **`restartPolicy` at container level** — It belongs under `spec`, not under `containers`. Placing it inside a container spec is a YAML validation error.
4. **Wrong env var format** — Each env var needs both `name:` and `value:` fields. Missing either causes a validation error.

---

## 🔍 Execution Flow

```
kubectl apply → Pod scheduled → bash container starts
                                    │
                                    ├── env vars loaded:
                                    │     GREETING=Welcome to
                                    │     COMPANY=DevOps
                                    │     GROUP=Industries
                                    │
                                    └── /bin/sh -c 'echo "$(GREETING) $(COMPANY) $(GROUP)"'
                                              │
                                              ▼
                                    stdout: "Welcome to DevOps Industries"
                                              │
                                    container exits (code 0)
                                              │
                                    restartPolicy: Never → STATUS: Completed ✅
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What are the different ways to inject environment variables into a Kubernetes container?**

Four main sources: (1) Literal `value` — hardcoded in the Pod spec, suitable for non-sensitive static config. (2) `configMapKeyRef` — pulls a specific key from a ConfigMap, used for shared configuration like feature flags or service URLs. (3) `secretKeyRef` — pulls from a Kubernetes Secret, used for passwords, API tokens, and credentials. (4) `fieldRef` — injects Pod metadata like the Pod's own name, namespace, or IP address, useful for logging and tracing. You can mix all four sources in a single container's `env` list. `envFrom` (not used here) bulk-imports all keys from a ConfigMap or Secret as environment variables at once.

---

**Q2: What is `restartPolicy: Never` and when should you use it?**

`restartPolicy: Never` tells Kubernetes not to restart the container regardless of exit code. After the container finishes, the Pod moves to `Succeeded` (exit 0) or `Failed` (non-zero exit). Use it for: one-shot scripts, database migrations, data import jobs, test runners, and any task that should run exactly once. The alternatives: `Always` (default) restarts on any exit — correct for long-running services. `OnFailure` restarts only on non-zero exit — correct for batch jobs that might need retrying. For repeatable batch jobs with scheduling, use a Kubernetes `Job` resource (which wraps a Pod with `restartPolicy: Never/OnFailure`) or `CronJob`.

---

**Q3: What is the difference between `env` and `envFrom` in a Kubernetes Pod spec?**

`env` injects individual named variables — you specify each variable name and its source explicitly. This gives you granular control: rename keys, mix sources (literal + ConfigMap + Secret), and inject only specific keys from a ConfigMap. `envFrom` bulk-imports all keys from a ConfigMap or Secret as environment variables, using the key names directly. `envFrom` is simpler when you want all keys from a ConfigMap, but it can pollute the environment with unexpected variable names if the ConfigMap grows. In practice, `env` with `configMapKeyRef` is preferred for predictability and explicit dependency documentation.

---

**Q4: How do environment variables compare to ConfigMaps for application configuration?**

Environment variables (injected via `env`) are suitable for simple key-value configuration that's known at Pod creation time and doesn't change while the Pod runs. ConfigMaps can be consumed as environment variables OR as mounted files. The file-mount approach allows live config updates without Pod restart (with some sync delay) and supports complex config formats (YAML, JSON, nginx.conf). For simple string values, env vars are simpler. For complex configuration files or values that need hot-reloading, ConfigMap volume mounts are more appropriate. Environment variables injected at startup are immutable for the Pod's lifetime.

---

**Q5: What happens to a Pod with `restartPolicy: Never` after the container exits successfully?**

The Pod moves to `Completed` status and stays in that state indefinitely until manually deleted. It doesn't consume CPU or memory (no running process), but it does occupy an entry in the API server's etcd. The logs remain available via `kubectl logs` even after completion — this is intentional so you can review the output. In automated pipelines, Pods from `Job` resources (which use `restartPolicy: Never/OnFailure`) are often cleaned up automatically via `ttlSecondsAfterFinished` to avoid accumulating completed Pods.

---

**Q6: How would you use environment variables to configure a containerized application across environments (dev/staging/prod)?**

The same Docker image runs in all environments; configuration changes via environment variables. In development, `DB_HOST=localhost`, `LOG_LEVEL=debug`. In production, `DB_HOST=rds.amazonaws.com`, `LOG_LEVEL=warn`. Kubernetes implements this through: separate ConfigMaps per namespace (dev namespace has dev ConfigMap, prod namespace has prod ConfigMap), same application Pod spec referencing the ConfigMap by name — same YAML, different values per environment. Sensitive values (DB passwords) come from Secrets injected the same way. This is the 12-Factor App "III. Config" principle: strict separation of config from code, config in the environment.

---

## 🔗 References

- [Kubernetes — Environment Variables](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)
- [Kubernetes — Pod restartPolicy](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy)
- [12-Factor App — Config](https://12factor.net/config)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
