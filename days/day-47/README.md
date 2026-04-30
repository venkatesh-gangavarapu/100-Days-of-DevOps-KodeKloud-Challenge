# Day 47 — Dockerizing a Python Application: Dockerfile, Build & Deploy

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Containerization / Docker / Python  
**Difficulty:** Intermediate  
**Phase:** Phase 4 — AWS Core Services  
**Status:** ✅ Completed

---

## 📋 Task Summary

Dockerize a Python application on **App Server 2** (`stapp02`):

1. Create `/python_app/Dockerfile` — python base image, install deps, expose 8085, run server.py
2. Build image `nautilus/python-app`
3. Run container `pythonapp_nautilus` — map host `8097` → container `8085`
4. Verify: `curl http://localhost:8097/`

---

## 🧠 Concept — Dockerizing a Python Application

### Standard Python Dockerfile Pattern

```dockerfile
FROM python:3.11-slim        # Minimal Python base
WORKDIR /app                 # Set working directory
COPY requirements.txt .      # Copy deps file FIRST (layer cache optimization)
RUN pip install -r requirements.txt  # Install deps (cached if requirements unchanged)
COPY src/ .                  # Copy app code LAST (changes most frequently)
EXPOSE 8085                  # Document listening port
CMD ["python", "server.py"]  # Start the app
```

### Why `COPY requirements.txt` Before `COPY src/`?

Docker layer caching. If you copy all files first then install deps:

```dockerfile
# BAD — cache busted every time any file changes
COPY src/ .
RUN pip install -r requirements.txt  # Reinstalls on every code change!

# GOOD — dependencies only reinstall when requirements.txt changes
COPY src/requirements.txt .
RUN pip install -r requirements.txt  # Cached unless requirements.txt changes
COPY src/ .                           # Only this layer rebuilds on code changes
```

In active development, `requirements.txt` rarely changes. App code changes constantly. This ordering means `pip install` is only re-run when dependencies actually change — dramatically faster builds.

### `python:3.11-slim` vs `python:3.11` vs `python:3.11-alpine`

| Image | Size | Use case |
|-------|------|---------|
| `python:3.11` | ~900MB | Full Debian — max compatibility |
| `python:3.11-slim` | ~130MB | Minimal Debian — most packages work |
| `python:3.11-alpine` | ~50MB | Minimal Alpine — musl, may need build tools |

`slim` is the sweet spot for most Python apps — significantly smaller than the full image while maintaining glibc compatibility that many Python packages (numpy, pandas, cryptography) require.

### `--no-cache-dir` in pip install

```dockerfile
RUN pip install --no-cache-dir -r requirements.txt
```

`--no-cache-dir` tells pip not to cache downloaded packages in the image layer. This reduces image size — the cache is only useful for repeated installs on the same machine, not in a Docker layer that's already committed.

> **Real-world context:** Python app containerization follows this exact pattern across the industry — Flask APIs, Django apps, FastAPI services, data science notebooks. Understanding the layer ordering optimization separates engineers who write correct Dockerfiles from engineers who write fast, production-grade Dockerfiles. CI/CD pipelines that rebuild on every commit can take 30 seconds or 5 minutes depending on whether dependencies are cached correctly.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 2 (`stapp02`) |
| User | steve |
| Dockerfile location | `/python_app/Dockerfile` |
| App source | `/python_app/src/` |
| Image name | `nautilus/python-app` |
| Container name | `pythonapp_nautilus` |
| Host port | `8097` |
| Container port | `8085` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 2

```bash
ssh steve@stapp02
```

### Step 2: Inspect the source directory

```bash
ls -la /python_app/src/
cat /python_app/src/requirements.txt
```

Confirms `requirements.txt` and `server.py` are present.

### Step 3: Create the Dockerfile

```bash
sudo vi /python_app/Dockerfile
```

### The Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ .

EXPOSE 8085

CMD ["python", "server.py"]
```

### Step 4: Build the image

```bash
cd /python_app
sudo docker build -t nautilus/python-app .
```

**Expected:**
```
Successfully built abc123def456
Successfully tagged nautilus/python-app:latest ✅
```

### Step 5: Verify image exists

```bash
sudo docker images | grep nautilus
# Expected: nautilus/python-app   latest   abc123   X seconds ago
```

### Step 6: Run the container with port mapping

```bash
sudo docker run -d \
  --name pythonapp_nautilus \
  -p 8097:8085 \
  nautilus/python-app
```

### Step 7: Verify container is running

```bash
sudo docker ps | grep pythonapp_nautilus
# Expected: 0.0.0.0:8097->8085/tcp   pythonapp_nautilus
```

### Step 8: Test the application

```bash
curl http://localhost:8097/
```

✅ Python app running in Docker, accessible on host port 8097.

---

## 📌 Commands Reference

```bash
# ─── Inspect source ──────────────────────────────────────
ls -la /python_app/src/
cat /python_app/src/requirements.txt

# ─── Create and build ────────────────────────────────────
sudo vi /python_app/Dockerfile
cd /python_app
sudo docker build -t nautilus/python-app .
sudo docker build -t nautilus/python-app . --no-cache   # Force fresh build

# ─── Run container ───────────────────────────────────────
sudo docker run -d \
  --name pythonapp_nautilus \
  -p 8097:8085 \
  nautilus/python-app

# ─── Verify and test ─────────────────────────────────────
sudo docker ps | grep pythonapp_nautilus
sudo docker images | grep nautilus
curl http://localhost:8097/

# ─── Debug if needed ─────────────────────────────────────
sudo docker logs pythonapp_nautilus
sudo docker exec -it pythonapp_nautilus /bin/bash
```

---

## ⚠️ Common Mistakes to Avoid

1. **Wrong COPY path** — The Dockerfile is at `/python_app/` but source files are in `/python_app/src/`. The COPY path must be relative to the build context: `COPY src/requirements.txt .` not `COPY requirements.txt .`
2. **Skipping layer cache ordering** — Always copy and install `requirements.txt` before copying the rest of the app code. Reversing this kills build cache optimization.
3. **Using `python server.py` as a shell string in CMD** — `CMD ["python", "server.py"]` (JSON array, exec form) is correct. `CMD python server.py` (shell form) wraps in `/bin/sh -c`, adding an unnecessary shell process as PID 1 and potentially causing signal handling issues.
4. **Port mismatch** — Container runs on `8085`, host maps to `8097`. These are different numbers — `-p 8097:8085` is correct. Swapping them means nothing receives the traffic.
5. **Building from wrong directory** — `docker build` must run from `/python_app/` (where the Dockerfile lives) so the build context includes `src/`. Running from `/python_app/src/` won't find the Dockerfile.

---

## 🔍 Python Dockerfile Layer Optimization Visualized

```
Build 1 (initial):
  Layer 1: FROM python:3.11-slim          [pull from registry]
  Layer 2: WORKDIR /app                   [create dir]
  Layer 3: COPY src/requirements.txt .    [copy 1 file]
  Layer 4: RUN pip install ...            [install packages — SLOW]
  Layer 5: COPY src/ .                    [copy app code]

Build 2 (code change only):
  Layer 1: FROM python:3.11-slim          [CACHED ✅]
  Layer 2: WORKDIR /app                   [CACHED ✅]
  Layer 3: COPY src/requirements.txt .    [CACHED ✅]
  Layer 4: RUN pip install ...            [CACHED ✅ — requirements unchanged!]
  Layer 5: COPY src/ .                    [rebuilds — code changed]

Build 3 (requirements change):
  Layer 1-3: CACHED ✅
  Layer 4: RUN pip install ...            [rebuilds — requirements changed]
  Layer 5: COPY src/ .                    [rebuilds]
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: Why use `python:3.11-slim` instead of `python:3.11` or `python:alpine`?**

`python:3.11` is the full Debian-based image at ~900MB — it includes build tools, compilers, and development headers that most production applications don't need at runtime. `python:3.11-slim` strips those extras down to ~130MB while keeping glibc compatibility, which matters for packages like numpy, pandas, and cryptography that compile C extensions against glibc. `python:alpine` is only ~50MB but uses musl libc, which causes compilation failures for many popular Python packages without additional build steps. `slim` is the pragmatic production choice — significantly smaller than full, broadly compatible unlike alpine.

---

**Q2: What is the difference between CMD exec form and shell form?**

`CMD ["python", "server.py"]` is exec form — Docker runs `python` directly as PID 1 with `server.py` as an argument. No shell process is involved. `CMD python server.py` is shell form — Docker runs `/bin/sh -c "python server.py"`, making `sh` PID 1 and `python` a child process. Exec form is preferred in production because: (1) Python is PID 1 and receives OS signals directly — `docker stop` sends SIGTERM to Python, enabling graceful shutdown. In shell form, SIGTERM goes to `sh`, which may not forward it to Python, causing forceful SIGKILL after the timeout. (2) No unnecessary shell overhead.

---

**Q3: How would you handle environment-specific configuration (dev vs prod) in a Python Docker container?**

Use environment variables injected at runtime rather than baking config into the image. The Python app reads `os.environ.get('DATABASE_URL')`, `os.environ.get('DEBUG', 'false')`, etc. For development: `docker run -e DATABASE_URL=sqlite:///dev.db -e DEBUG=true nautilus/python-app`. For production: `docker run -e DATABASE_URL=postgresql://... nautilus/python-app`. With Docker Compose, use an `.env` file or the `environment:` section. This keeps the image environment-agnostic — one image runs everywhere with different configs at runtime. Never bake environment-specific values into the Dockerfile with `ENV` unless they're truly universal defaults.

---

**Q4: What is a multi-stage build and when would you use it for a Python app?**

Multi-stage builds use multiple `FROM` instructions in one Dockerfile. For Python, this is useful when your app has compiled dependencies (C extensions, Cython). Stage 1 uses a full image with build tools to compile extensions. Stage 2 starts from `slim` and copies only the compiled artifacts — not the compiler or build tools. Example: install `cryptography` (needs gcc, libssl-dev) in stage 1, copy the installed packages to stage 2. The final image has the compiled library without the ~500MB of build tools. For pure Python apps without compiled dependencies, multi-stage builds offer less benefit, but they're essential for apps with heavy C extension requirements.

---

**Q5: How do you run a Python Flask/FastAPI app correctly in Docker for production?**

Don't run with `python app.py` in production — Flask and FastAPI's built-in servers are development servers, not production-grade. Use a WSGI/ASGI server: `gunicorn` for Flask/Django (`CMD ["gunicorn", "app:app", "--workers", "4", "--bind", "0.0.0.0:8085"]`) or `uvicorn` for FastAPI (`CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8085", "--workers", "4"]`). Production servers handle concurrent connections, worker management, and graceful restarts properly. For this challenge, `python server.py` is sufficient as it's a test app, but in a real deployment, the production server choice matters significantly for performance and reliability.

---

**Q6: How do you keep Docker images secure for Python applications?**

Several layers: (1) Use specific image versions (`python:3.11.9-slim`) not `latest` — prevents unexpected updates breaking the app. (2) Run as a non-root user — add `RUN useradd -m appuser && USER appuser` before CMD — limits blast radius if the app is compromised. (3) Use `--no-cache-dir` in pip to avoid caching downloaded packages. (4) Scan images with tools like `docker scout` or `trivy` for known CVEs. (5) Use `.dockerignore` to exclude `.git`, `__pycache__`, `.env`, test files, and secrets from the build context. (6) Pin dependencies in `requirements.txt` with exact versions (`flask==3.0.0`) not ranges (`flask>=2.0`) for reproducible builds.

---

## 🔗 References

- [Docker Hub — python](https://hub.docker.com/_/python)
- [Python Docker Best Practices](https://docs.docker.com/language/python/)
- [pip install — No Cache](https://pip.pypa.io/en/stable/cli/pip_install/)
- [Dockerfile CMD vs ENTRYPOINT](https://docs.docker.com/engine/reference/builder/#cmd)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
