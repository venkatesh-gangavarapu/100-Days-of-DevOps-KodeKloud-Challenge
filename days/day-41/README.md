# Day 41 — Writing a Dockerfile: Apache on Ubuntu 24.04 with Custom Port

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Containerization / Docker / Dockerfile  
**Difficulty:** Intermediate  
**Phase:** Phase 3 — Kubernetes & Orchestration  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create `/opt/docker/Dockerfile` on **App Server 3** (`stapp03`) to build a custom image that:

- Uses `ubuntu:24.04` as the base image
- Installs `apache2`
- Configures Apache to listen on port `6400`
- Only modifies port configuration — no other Apache settings changed

---

## 🧠 Concept — Dockerfile Fundamentals

### What is a Dockerfile?

A Dockerfile is a **text file containing ordered instructions** that Docker reads to build an image. Each instruction creates a new layer. The result is a reproducible, version-controlled image definition.

```
Dockerfile instructions
        │
        docker build
        │
        ▼
Image (layered filesystem)
        │
        docker run
        │
        ▼
Container (running instance)
```

### Core Dockerfile Instructions

| Instruction | Purpose | Example |
|-------------|---------|---------|
| `FROM` | Base image — every Dockerfile starts here | `FROM ubuntu:24.04` |
| `RUN` | Execute command during build (creates a layer) | `RUN apt-get install -y apache2` |
| `COPY` | Copy files from host into image | `COPY index.html /var/www/html/` |
| `ADD` | Like COPY but supports URLs and tar extraction | `ADD app.tar.gz /opt/` |
| `ENV` | Set environment variables | `ENV PORT=6400` |
| `EXPOSE` | Document which port the container listens on | `EXPOSE 6400` |
| `WORKDIR` | Set working directory for subsequent instructions | `WORKDIR /app` |
| `CMD` | Default command when container starts | `CMD ["apache2ctl", "-D", "FOREGROUND"]` |
| `ENTRYPOINT` | Like CMD but not overridable by default | `ENTRYPOINT ["nginx"]` |

### Why `apache2ctl -D FOREGROUND` is Critical

Docker containers run until their PID 1 exits. Apache by default daemonizes — it forks a background process and the foreground process exits. When the foreground process exits, Docker thinks the container is done and stops it.

```
Without FOREGROUND:
RUN apache2ctl start → apache2 daemonizes → foreground exits → container stops ❌

With FOREGROUND:
CMD apache2ctl -D FOREGROUND → process stays in foreground as PID 1 → container runs ✅
```

`-D FOREGROUND` tells Apache to stay in the foreground, keeping PID 1 alive and the container running.

### `RUN` vs `CMD` — Build Time vs Run Time

| Instruction | When it runs | Use for |
|-------------|-------------|---------|
| `RUN` | **Build time** — during `docker build` | Installing packages, editing configs, creating files |
| `CMD` | **Run time** — when `docker run` is executed | Starting the application process |

All package installs, config changes, and file operations happen in `RUN`. The application start command goes in `CMD`.

### Layer Optimization — Chaining RUN Commands

```dockerfile
# BAD — creates 3 separate layers
RUN apt-get update
RUN apt-get install -y apache2
RUN sed -i 's/Listen 80/Listen 6400/' /etc/apache2/ports.conf

# GOOD — creates 1 layer, smaller image
RUN apt-get update && \
    apt-get install -y apache2 && \
    sed -i 's/Listen 80/Listen 6400/' /etc/apache2/ports.conf
```

Each `RUN` instruction creates a new image layer. Combining related commands with `&&` reduces layer count and image size.

> **Real-world context:** Dockerfiles are the correct, production-grade way to create Docker images. Unlike `docker commit` (Day 39), Dockerfiles are declarative, version-controlled, and reproducible — anyone with the Dockerfile can rebuild the exact same image. Every serious organization stores Dockerfiles in their application repositories alongside the code they containerize. Understanding Dockerfile syntax and best practices is a foundational skill for any DevOps engineer.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 3 (`stapp03`) |
| User | banner |
| Dockerfile location | `/opt/docker/Dockerfile` |
| Base image | `ubuntu:24.04` |
| Apache port | `6400` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 3

```bash
ssh banner@stapp03
```

### Step 2: Create the directory

```bash
sudo mkdir -p /opt/docker
```

### Step 3: Create the Dockerfile

```bash
sudo vi /opt/docker/Dockerfile
```

### The Dockerfile

```dockerfile
FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y apache2 && \
    sed -i 's/^Listen 80/Listen 6400/' /etc/apache2/ports.conf && \
    sed -i 's/<VirtualHost \*:80>/<VirtualHost *:6400>/' \
      /etc/apache2/sites-enabled/000-default.conf

EXPOSE 6400

CMD ["apache2ctl", "-D", "FOREGROUND"]
```

### Step 4: Verify the Dockerfile

```bash
cat /opt/docker/Dockerfile
```

### Step 5: Build the image

```bash
cd /opt/docker
sudo docker build -t apache-custom:6400 .
```

**Expected output:**
```
[+] Building X.Xs
 => [1/2] FROM ubuntu:24.04
 => [2/2] RUN apt-get update && apt-get install -y apache2 ...
 => exporting to image
Successfully built abc123def456
Successfully tagged apache-custom:6400
```

### Step 6: Test the image by running a container

```bash
sudo docker run -d -p 6400:6400 --name apache-test apache-custom:6400
```

### Step 7: Verify the container is running

```bash
sudo docker ps | grep apache-test
```

### Step 8: Test Apache is serving on port 6400

```bash
curl http://localhost:6400
# Expected: Apache2 Ubuntu Default Page HTML ✅
```

### Step 9: Clean up test container (optional)

```bash
sudo docker stop apache-test && sudo docker rm apache-test
```

---

## 📌 Commands Reference

```bash
# ─── Setup ───────────────────────────────────────────────
sudo mkdir -p /opt/docker
sudo vi /opt/docker/Dockerfile

# ─── Build image ─────────────────────────────────────────
cd /opt/docker
sudo docker build -t apache-custom:6400 .
sudo docker build -t apache-custom:6400 . --no-cache  # Force fresh build

# ─── Test ────────────────────────────────────────────────
sudo docker run -d -p 6400:6400 --name apache-test apache-custom:6400
sudo docker ps
curl http://localhost:6400

# ─── Inspect image layers ────────────────────────────────
sudo docker history apache-custom:6400
sudo docker image inspect apache-custom:6400

# ─── Cleanup ─────────────────────────────────────────────
sudo docker stop apache-test && sudo docker rm apache-test
sudo docker rmi apache-custom:6400
```

---

## ⚠️ Common Mistakes to Avoid

1. **Using `CMD` to run `service apache2 start`** — This starts Apache as a background daemon and the container exits immediately. Always use `apache2ctl -D FOREGROUND` as the CMD to keep the process in the foreground.
2. **Lowercase `d` in Dockerfile** — Docker specifically looks for `Dockerfile` (capital D). A file named `dockerfile` is not automatically recognized by `docker build .`.
3. **Updating only `ports.conf` but not the VirtualHost** — Same as Day 40: both files need updating. Missing the VirtualHost edit means the default site doesn't match the listen port.
4. **Multiple `RUN` instructions for related commands** — Use `&&` to chain commands in a single `RUN` instruction. This reduces image layers and produces a smaller, cleaner image.
5. **Forgetting `EXPOSE`** — `EXPOSE 6400` doesn't actually publish the port — that's done with `-p` in `docker run`. But it documents intent and is required for tools like Docker Compose and Kubernetes to understand which ports the container uses.

---

## 🔍 Dockerfile Layer Diagram

```
Layer 0: ubuntu:24.04 base image          (pulled from registry)
         ├── Ubuntu filesystem
         └── Default packages

Layer 1: RUN apt-get update && ...        (created by docker build)
         ├── apache2 installed
         ├── ports.conf: Listen 6400
         └── 000-default.conf: *:6400

Final image: apache-custom:6400
Running: apache2ctl -D FOREGROUND (PID 1)
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between `CMD` and `ENTRYPOINT` in a Dockerfile?**

Both define what runs when a container starts, but with different override behavior. `CMD` provides default arguments that can be completely replaced when you pass a command to `docker run`: `docker run myimage /bin/bash` ignores the CMD entirely. `ENTRYPOINT` defines the fixed executable — it always runs, and arguments passed to `docker run` are appended to it rather than replacing it. In practice: use `ENTRYPOINT` for the main process that should always run (e.g., `ENTRYPOINT ["nginx"]`), and use `CMD` for default arguments to that process (e.g., `CMD ["-g", "daemon off;"]`). For simple cases like this Apache setup, `CMD` alone is sufficient.

---

**Q2: Why must Apache run with `-D FOREGROUND` inside a Docker container?**

Docker containers run until their PID 1 process exits. Apache's default behavior is to daemonize — it starts, forks a background worker process, and then the parent process exits. When that parent exits, Docker interprets it as the container completing its task and stops it. `-D FOREGROUND` overrides this behavior and keeps the Apache process running in the foreground as PID 1, which keeps the container alive. This applies to any service in a container: nginx needs `daemon off;`, MySQL needs `--user=mysql` keeping the process foreground, etc. The container's PID 1 must stay alive for the container to stay alive.

---

**Q3: What does `EXPOSE` actually do in a Dockerfile?**

`EXPOSE` is documentation — it declares which port(s) the container is intended to use. It does NOT actually publish or open any ports. A container with `EXPOSE 6400` is no more accessible than one without it, unless you also use `-p 6400:6400` in `docker run` or `ports:` in Docker Compose. Where `EXPOSE` becomes functional is with `docker run -P` (capital P) — this automatically maps all EXPOSE'd ports to random high ports on the host. Tools like Docker Compose, Kubernetes, and container scanners also read EXPOSE to understand service intent. Think of it as metadata for humans and tooling, not a firewall rule.

---

**Q4: How does layer caching work in `docker build` and how do you optimize for it?**

Docker caches each layer during a build and reuses cached layers if the instruction and its context haven't changed. If you change line 3 of a Dockerfile, Docker rebuilds from line 3 onward but reuses cached layers 1 and 2. This means instruction order matters for build speed. Place frequently-changing instructions (like `COPY . .` for application code) near the bottom, and infrequently-changing instructions (like package installation) near the top. For the `apt-get update && apt-get install` pattern specifically, always chain them in a single `RUN` — if they're separate instructions, a cached `apt-get update` layer may pair with a newer `apt-get install`, resulting in stale package versions.

---

**Q5: What is the difference between `COPY` and `ADD` in a Dockerfile?**

Both copy files from the build context into the image, but `ADD` has additional capabilities: it can fetch files from URLs and automatically extract tar archives. The Docker best practices guide recommends using `COPY` by default because its behavior is explicit and predictable. Use `ADD` only when you specifically need the tar extraction feature — for example, `ADD app.tar.gz /opt/` extracts directly. Using `ADD` for simple file copies is misleading because it implies special handling is happening. `COPY` clearly communicates "copy this file, nothing else."

---

**Q6: How do multi-stage builds reduce final image size?**

A multi-stage build uses multiple `FROM` instructions in one Dockerfile. Early stages can use large build images (with compilers, build tools, etc.) to compile the application. The final stage starts fresh from a minimal base image and copies only the compiled artifacts — not the build tools. Example: build a Go application in a `golang:1.21` image (800MB+), then copy only the compiled binary into a `scratch` or `alpine` base (5MB). The final image contains only what's needed to run the application, not build it. This is how production-grade Docker images achieve small sizes despite complex build requirements.

---

## 🔗 References

- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Build — Layer Caching](https://docs.docker.com/build/cache/)
- [Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
