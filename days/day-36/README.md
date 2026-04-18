# Day 36 — Running a Named nginx Container with Alpine Tag

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Containerization / Docker  
**Difficulty:** Beginner  
**Phase:** Phase 3 — Kubernetes & Orchestration  
**Status:** ✅ Completed

---

## 📋 Task Summary

Deploy a running nginx container on **App Server 1** (`stapp01`):

- Container name: `nginx_1`
- Image: `nginx:alpine`
- State: `running`

---

## 🧠 Concept — Docker Images, Tags & Container Lifecycle

### Docker Image Tags

A Docker image tag identifies a specific version or variant of an image. The format is `image:tag`.

| Image | Tag | What it is |
|-------|-----|-----------|
| `nginx` | `latest` | Latest stable nginx (Debian-based, ~140MB) |
| `nginx` | `alpine` | nginx on Alpine Linux (~23MB) |
| `nginx` | `1.25` | Specific nginx version |
| `nginx` | `1.25-alpine` | Specific version on Alpine |

**Why Alpine?** Alpine Linux is a security-focused, minimal distribution. Alpine-based images are significantly smaller than Debian/Ubuntu-based equivalents — faster to pull, less attack surface, lower storage cost. In production, Alpine variants are the default choice unless a specific library requires a full OS.

### Docker Container Lifecycle

```
Image (blueprint)
      │
      docker run
      │
      ▼
Created → Running → Paused / Stopped → Removed
              │
              docker stop / docker kill
              │
              ▼
           Stopped (exited)
              │
              docker start
              │
              ▼
           Running again
```

### Key `docker run` Flags

| Flag | Short | Purpose |
|------|-------|---------|
| `--detach` | `-d` | Run in background — returns container ID |
| `--name` | | Assign a human-readable name |
| `--publish` | `-p` | Map host port to container port (`8080:80`) |
| `--volume` | `-v` | Mount host directory into container |
| `--env` | `-e` | Set environment variables |
| `--rm` | | Auto-remove container when it stops |
| `--interactive --tty` | `-it` | Interactive shell access |

> **Real-world context:** Running named containers is the foundation of every Docker deployment. The `--name` flag is important in production because it gives you a predictable handle to reference the container — `docker logs nginx_1`, `docker stop nginx_1`, `docker exec -it nginx_1 sh` — instead of working with opaque container IDs. Naming conventions like `appname_instancenumber` (`nginx_1`) are common in teams running multiple instances of the same service.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 1 (`stapp01`) |
| User | tony |
| Container Name | `nginx_1` |
| Image | `nginx:alpine` |
| Required State | `running` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 1

```bash
ssh tony@stapp01
```

### Step 2: Pull the image

```bash
sudo docker pull nginx:alpine
```

**Expected output:**
```
alpine: Pulling from library/nginx
...
Status: Downloaded newer image for nginx:alpine
```

### Step 3: Run the container in detached mode

```bash
sudo docker run -d --name nginx_1 nginx:alpine
```

**Expected output:**
```
abc123def456789...   ← container ID
```

### Step 4: Verify the container is running

```bash
sudo docker ps
```

**Expected output:**
```
CONTAINER ID   IMAGE          COMMAND                  CREATED        STATUS        PORTS     NAMES
abc123def456   nginx:alpine   "/docker-entrypoint.…"   5 seconds ago  Up 4 seconds  80/tcp    nginx_1
```

`STATUS: Up X seconds` confirms the container is in a running state. ✅

### Step 5: Detailed inspection

```bash
sudo docker inspect nginx_1
```

Key fields to confirm:
```json
"Name": "/nginx_1",
"State": {
    "Status": "running",
    "Running": true,
    ...
}
```

### Step 6: Check container logs

```bash
sudo docker logs nginx_1
```

Shows nginx startup output — confirms the process inside is healthy.

---

## 📌 Commands Reference

```bash
# ─── Pull image ──────────────────────────────────────────
sudo docker pull nginx:alpine

# ─── Run container ───────────────────────────────────────
sudo docker run -d --name nginx_1 nginx:alpine

# ─── Verify running ──────────────────────────────────────
sudo docker ps                              # Running containers
sudo docker ps -a                           # All containers
sudo docker inspect nginx_1                 # Full container details
sudo docker inspect nginx_1 --format '{{.State.Status}}'  # Just status

# ─── Container management ────────────────────────────────
sudo docker logs nginx_1                    # View logs
sudo docker exec -it nginx_1 sh            # Shell into container
sudo docker stop nginx_1                    # Stop container
sudo docker start nginx_1                   # Start stopped container
sudo docker restart nginx_1                 # Restart container
sudo docker rm nginx_1                      # Remove stopped container
sudo docker rm -f nginx_1                   # Force remove running container

# ─── Image management ────────────────────────────────────
docker images                               # List local images
docker image inspect nginx:alpine           # Image details
docker rmi nginx:alpine                     # Remove image
```

---

## ⚠️ Common Mistakes to Avoid

1. **Forgetting `-d` flag** — Without detached mode, `docker run` attaches to the container's stdout. When you exit, the container stops. Always use `-d` for containers that should keep running in the background.
2. **Name conflict** — If a container named `nginx_1` already exists (even stopped), `docker run --name nginx_1` fails. Check with `docker ps -a` first, remove with `docker rm nginx_1` if needed.
3. **Using `nginx` without `:alpine` tag** — `nginx` alone pulls `nginx:latest` which is the Debian-based image. The task requires the alpine variant specifically.
4. **Confusing image and container** — `docker images` lists images (blueprints). `docker ps` lists containers (running instances). You can have the `nginx:alpine` image locally and zero running containers from it, or multiple containers all from the same image.
5. **Not verifying with `docker ps`** — A container can start and immediately exit if the main process fails. `docker ps` shows only running containers. Always verify `STATUS: Up` — not just that the run command didn't error.

---

## 🔍 What Happens During `docker run`

```
sudo docker run -d --name nginx_1 nginx:alpine
         │
         ▼
Docker daemon checks: is nginx:alpine available locally?
         │
    No → Pull from Docker Hub (library/nginx, alpine tag)
    Yes → Use cached local image
         │
         ▼
Create container filesystem from image layers
         │
         ▼
Set container name to nginx_1
         │
         ▼
Start container process (/docker-entrypoint.sh → nginx -g 'daemon off;')
         │
         ▼
Return container ID (detached — control returns to shell)
         │
         ▼
Container running in background ✅
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between `docker run`, `docker start`, and `docker create`?**

`docker create` creates a container from an image but doesn't start it — the container exists in a "created" state on disk. `docker start` starts an already-created (or stopped) container. `docker run` combines both: it creates a new container from an image AND starts it immediately. In day-to-day work, `docker run` is what you use to deploy a new container. `docker start` is what you use to restart a previously stopped container without recreating it.

---

**Q2: Why is the Alpine variant preferred for production Docker images?**

Alpine Linux is built on musl libc and busybox, making base images around 5MB compared to 80MB+ for Debian. The nginx:alpine image is roughly 23MB vs 140MB for nginx:latest (Debian). Smaller images mean faster pulls in CI/CD pipelines, lower storage costs in container registries, and reduced attack surface — fewer packages means fewer potential CVEs. The tradeoff is that Alpine uses musl instead of glibc, which occasionally causes compatibility issues with applications compiled against glibc. For standard applications like nginx, it works perfectly.

---

**Q3: What does the `-d` flag do and what happens without it?**

`-d` runs the container in detached mode — the container starts in the background and the shell prompt returns immediately with the container ID. Without `-d`, Docker attaches your terminal to the container's stdout and stderr. You see the nginx startup logs in real time, but your terminal is "stuck" — you can't type other commands. When you press Ctrl+C, the signal is sent to the container's main process, which stops it. For services that should keep running (web servers, databases, applications), always use `-d`.

---

**Q4: How do you run a command inside a running Docker container?**

Use `docker exec`. To open an interactive shell: `docker exec -it nginx_1 sh` (Alpine uses `sh`, not `bash`). To run a single command and return: `docker exec nginx_1 nginx -v`. The `-i` flag keeps stdin open, `-t` allocates a pseudo-TTY. `exec` runs the command inside the existing running container — it doesn't create a new container. This is how you inspect a container's filesystem, check logs, test connectivity, or debug application issues without restarting the container.

---

**Q5: What is the difference between `docker stop` and `docker kill`?**

`docker stop` sends a SIGTERM to the container's main process, giving it time to shut down gracefully — flush buffers, close connections, write state to disk. After a grace period (default 10 seconds), if the process hasn't stopped, Docker sends SIGKILL. `docker kill` sends SIGKILL immediately — the process is terminated without any cleanup. For stateful applications (databases, message queues), always use `docker stop` to avoid data corruption. `docker kill` is reserved for containers that are hung and not responding to SIGTERM.

---

**Q6: How does Docker naming help in production environments?**

Without `--name`, Docker assigns random two-word names like `confident_torvalds` or `peaceful_einstein`. While unique, they're meaningless and hard to reference in scripts, logs, and monitoring. Named containers like `nginx_1`, `api_server`, `postgres_primary` are self-documenting — you immediately know what the container is. Names also make automation predictable: `docker restart nginx_1` works reliably in a script whereas a random name requires first querying `docker ps` to find the ID. In production, naming conventions (service_instance, environment_service) are enforced as team standards.

---

## 🔗 References

- [Docker Run Reference](https://docs.docker.com/engine/reference/run/)
- [Docker Hub — nginx](https://hub.docker.com/_/nginx)
- [Alpine Linux — Why Alpine?](https://alpinelinux.org/about/)
- [Docker Container Lifecycle](https://docs.docker.com/engine/reference/commandline/container/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
