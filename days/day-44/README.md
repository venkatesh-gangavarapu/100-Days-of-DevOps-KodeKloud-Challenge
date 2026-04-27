# Day 44 — Docker Compose: httpd Container with Port & Volume Mapping

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Containerization / Docker Compose  
**Difficulty:** Intermediate  
**Phase:** Phase 3 — Kubernetes & Orchestration  
**Status:** ✅ Completed

---

## 📋 Task Summary

On **App Server 3** (`stapp03`), deploy a static website using Docker Compose:

- File: `/opt/docker/docker-compose.yml`
- Image: `httpd:latest`
- Container name: `httpd`
- Port mapping: host `8084` → container `80`
- Volume: `/opt/sysops` (host) → `/usr/local/apache2/htdocs` (container)

---

## 🧠 Concept — Docker Compose

### What is Docker Compose?

Docker Compose is a tool for defining and running **multi-container applications** using a single YAML file. Instead of long `docker run` commands with many flags, you describe the desired state declaratively and let Compose manage it.

```bash
# Without Compose — one long command:
docker run -d \
  --name httpd \
  -p 8084:80 \
  -v /opt/sysops:/usr/local/apache2/htdocs \
  httpd:latest

# With Compose — clean YAML + one command:
docker compose up -d
```

### Docker Compose File Structure

```yaml
version: '3'          # Compose file format version

services:             # Define one or more containers
  service_name:       # Logical name (used for DNS in the network)
    image:            # Docker image to use
    container_name:   # Explicit container name (overrides default)
    ports:            # Port mappings (host:container)
    volumes:          # Volume/bind mount mappings
    environment:      # Environment variables
    networks:         # Networks to connect to
    depends_on:       # Service startup order
```

### Volumes in Docker Compose

```yaml
volumes:
  - /host/path:/container/path          # Bind mount (host dir)
  - named_volume:/container/path        # Named volume (Docker managed)
  - /container/path                     # Anonymous volume
```

**Bind mounts** (today's task) map a specific host directory directly into the container. Changes on the host are immediately visible inside the container and vice versa — no sync delay. This is perfect for serving static website content that's managed on the host.

### `container_name` vs Service Name

```yaml
services:
  web:                       # Service name — used for DNS between containers
    container_name: httpd    # Actual Docker container name — used in docker ps/stop/etc
```

Without `container_name`, Docker auto-generates a name like `docker_web_1`. Specifying it explicitly gives you a predictable name for operations like `docker logs httpd` or `docker stop httpd`.

> **Real-world context:** Docker Compose is the standard tool for local development environments and single-host deployments. Every team working with containers uses Compose for defining their application stack — web server, database, cache, queue — all in one file. The same Compose file serves as documentation of the application's dependencies and configuration. Understanding Compose YAML syntax directly transfers to Kubernetes manifest syntax, which follows many of the same structural patterns.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 3 (`stapp03`) |
| User | banner |
| Compose file | `/opt/docker/docker-compose.yml` |
| Image | `httpd:latest` |
| Container name | `httpd` |
| Host port | `8084` |
| Container port | `80` |
| Host volume | `/opt/sysops` |
| Container volume | `/usr/local/apache2/htdocs` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 3

```bash
ssh banner@stapp03
```

### Step 2: Verify host volume directory exists

```bash
ls -la /opt/sysops
```

Do NOT modify any content here — just confirm it exists.

### Step 3: Ensure the docker directory exists

```bash
sudo mkdir -p /opt/docker
```

### Step 4: Create the docker-compose.yml

```bash
sudo vi /opt/docker/docker-compose.yml
```

### The docker-compose.yml

```yaml
version: '3'
services:
  web:
    image: httpd:latest
    container_name: httpd
    ports:
      - "8084:80"
    volumes:
      - /opt/sysops:/usr/local/apache2/htdocs
```

### Step 5: Start the container with Docker Compose

```bash
cd /opt/docker
sudo docker compose up -d
```

**Expected output:**
```
[+] Running 2/2
 ✔ web Pulled
 ✔ Container httpd  Started
```

### Step 6: Verify container is running

```bash
sudo docker ps | grep httpd
```

**Expected:**
```
CONTAINER ID   IMAGE          ...   STATUS        PORTS                  NAMES
abc123def456   httpd:latest   ...   Up X seconds  0.0.0.0:8084->80/tcp   httpd
```

### Step 7: Verify volume mount is correct

```bash
sudo docker inspect httpd --format '{{json .Mounts}}'
```

Confirms `/opt/sysops` is mounted to `/usr/local/apache2/htdocs`.

### Step 8: Test the web server

```bash
curl http://localhost:8084
```

**Expected:** Content from `/opt/sysops` served by Apache httpd. ✅

---

## 📌 Commands Reference

```bash
# ─── Setup ───────────────────────────────────────────────
sudo mkdir -p /opt/docker
sudo vi /opt/docker/docker-compose.yml

# ─── Compose operations ──────────────────────────────────
cd /opt/docker
sudo docker compose up -d           # Start in background
sudo docker compose up              # Start with attached logs
sudo docker compose down            # Stop and remove containers
sudo docker compose ps              # List services
sudo docker compose logs            # View logs
sudo docker compose logs -f         # Follow logs
sudo docker compose restart         # Restart services
sudo docker compose pull            # Pull latest images

# ─── Verify ──────────────────────────────────────────────
sudo docker ps | grep httpd
sudo docker inspect httpd --format '{{json .Mounts}}'
sudo docker port httpd
curl http://localhost:8084
```

---

## ⚠️ Common Mistakes to Avoid

1. **Wrong file name or location** — The task requires `/opt/docker/docker-compose.yml` exactly. Docker Compose looks for `docker-compose.yml` by default — any other name requires `-f filename`.
2. **Modifying `/opt/sysops` content** — The task explicitly says do not modify any data in the volume directories. Only create the Compose file and start the container.
3. **Forgetting `container_name`** — Without it, Docker Compose generates `docker_web_1` or similar. The task requires the container to be named exactly `httpd`.
4. **Port format without quotes** — `8084:80` without quotes can be misinterpreted in YAML as a time value. Always quote port mappings: `"8084:80"`.
5. **Running `docker compose up` from the wrong directory** — Always `cd /opt/docker` first. Compose looks for `docker-compose.yml` in the current directory by default.

---

## 🔍 docker-compose.yml Structure Explained

```yaml
version: '3'              # Compose file format — '3' is widely supported

services:                 # All container definitions go here
  web:                    # Service name — internal DNS name for inter-service communication
    image: httpd:latest   # Image to use — pulls from Docker Hub if not local
    container_name: httpd # Override default name — makes docker ps/logs/stop predictable
    ports:
      - "8084:80"         # "HOST:CONTAINER" — traffic at host:8084 → container:80
    volumes:
      - /opt/sysops:/usr/local/apache2/htdocs
      #  HOST_PATH       :  CONTAINER_PATH
      # Changes on host immediately visible in container
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is Docker Compose and when would you use it over plain `docker run`?**

Docker Compose is a tool for defining and running multi-container applications using a declarative YAML file. You'd use it whenever you have more than one container, or whenever a single container needs complex configuration — volumes, networks, environment variables, port mappings. A `docker run` command with many flags becomes hard to read, share, and reproduce. A `docker-compose.yml` is self-documenting, version-controllable, and can be brought up or torn down with a single command. In practice, even single-container deployments often use Compose for consistency and readability.

---

**Q2: What is the difference between a bind mount and a named volume in Docker Compose?**

A bind mount maps a specific host filesystem path directly into the container: `- /opt/sysops:/usr/local/apache2/htdocs`. The container reads and writes directly to that host path — changes are immediate and bidirectional. A named volume is managed by Docker: `- mydata:/var/lib/mysql`. Docker creates and manages the storage location (usually in `/var/lib/docker/volumes/`). Named volumes are portable — they survive `docker compose down` and can be backed up. Bind mounts are better when you need the host to control the content (serving static files, injecting configs). Named volumes are better for persistent application data like databases.

---

**Q3: What happens to container data when you run `docker compose down`?**

`docker compose down` stops and removes the containers and the default network, but preserves named volumes and bind mounts. The data in `/opt/sysops` on the host is completely unaffected — it exists independently of the container lifecycle. Named volumes also survive `docker compose down`. To also remove named volumes, use `docker compose down -v`. The key principle: containers are ephemeral, but volumes (especially bind mounts to host directories) are persistent. This is why you never store important data inside a container's writable layer.

---

**Q4: What is the `version` field in docker-compose.yml and does it still matter?**

The `version` field specified which Compose file format to use — different versions supported different features. Common values were `'2'`, `'3'`, `'3.8'`. In recent versions of Docker Compose (v2+), the `version` field is effectively deprecated — the Compose specification has unified across versions and the field is ignored. However, it's still commonly seen in existing files and doesn't cause errors. For new files, you can omit it entirely. For maximum compatibility with older tooling, `version: '3'` is a safe choice.

---

**Q5: How does `docker compose up` handle image updates?**

`docker compose up -d` uses locally cached images if available. If you want to ensure the latest version is pulled, run `docker compose pull` first, then `docker compose up -d`. Alternatively, `docker compose up -d --pull always` (Compose v2) pulls a fresh copy every time. In production CI/CD pipelines, the standard pattern is: build new image → push to registry → `docker compose pull` → `docker compose up -d` → the running container is replaced with the new image while the old one is stopped. Compose handles the replacement gracefully for single-host deployments.

---

**Q6: How does Docker Compose DNS resolution work between services?**

When Docker Compose starts multiple services, it creates a default bridge network and makes each service reachable by its service name as a DNS hostname. If your Compose file has services `web` and `db`, the `web` container can connect to the database using `db` as the hostname — Docker's internal DNS resolves it to the `db` container's IP. This is why service names matter — they become hostnames. The `container_name` setting doesn't affect DNS resolution between services; only the service name does. This service-name DNS resolution is one of the main reasons custom networks (which Compose creates automatically) are superior to the default bridge network.

---

## 🔗 References

- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Docker Compose Getting Started](https://docs.docker.com/compose/gettingstarted/)
- [Bind Mounts vs Named Volumes](https://docs.docker.com/storage/bind-mounts/)
- [Docker Hub — httpd](https://hub.docker.com/_/httpd)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
