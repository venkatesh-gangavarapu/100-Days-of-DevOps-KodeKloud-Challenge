# Day 43 — Docker Port Mapping: nginx Container with Host-to-Container Port Binding

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Containerization / Docker  
**Difficulty:** Beginner  
**Phase:** Phase 3 — Kubernetes & Orchestration  
**Status:** ✅ Completed

---

## 📋 Task Summary

On **App Server 2** (`stapp02`):

1. Pull `nginx:alpine` image
2. Run a container named `beta`
3. Map host port `3000` → container port `80`
4. Keep the container running

---

## 🧠 Concept — Docker Port Mapping

### Why Port Mapping is Needed

Containers run in their own isolated network namespace. A process inside a container listening on port 80 is NOT accessible from the host or outside world — unless you explicitly map a host port to it.

```
External request → Host port 3000 → Docker NAT → Container port 80 → nginx
```

Without `-p 3000:80`, nginx runs on port 80 inside the container but nothing can reach it from outside.

### Port Mapping Syntax

```bash
docker run -p HOST_PORT:CONTAINER_PORT image

-p 3000:80        # host:3000 → container:80
-p 8080:80        # host:8080 → container:80
-p 443:443        # host:443  → container:443
-p 3000-3005:80   # port range mapping
```

### `-p` vs `--expose` vs `EXPOSE`

| Mechanism | What it does | Accessible from outside? |
|-----------|-------------|------------------------|
| `EXPOSE 80` in Dockerfile | Documents the port — metadata only | ❌ No |
| `--expose 80` in docker run | Same as EXPOSE at runtime | ❌ No |
| `-p 3000:80` in docker run | Actually publishes the port | ✅ Yes |

Only `-p` (publish) makes the port reachable from outside the container.

### Binding to Specific Host Interface

```bash
-p 3000:80              # All interfaces (0.0.0.0:3000)
-p 127.0.0.1:3000:80   # Localhost only — not externally reachable
-p 192.168.1.5:3000:80 # Specific host IP only
```

> **Real-world context:** Port mapping is the fundamental mechanism for making containerized services accessible. Every web application, API, and database running in Docker uses this to expose services. In production, a load balancer or reverse proxy typically sits in front — it receives traffic on standard ports (80/443) and forwards to containers on internal ports. Understanding the host:container port distinction is essential for debugging connectivity issues in containerized environments.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 2 (`stapp02`) |
| User | steve |
| Image | `nginx:alpine` |
| Container name | `beta` |
| Host port | `3000` |
| Container port | `80` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 2

```bash
ssh steve@stapp02
```

### Step 2: Pull nginx:alpine image

```bash
sudo docker pull nginx:alpine
```

### Step 3: Run container with port mapping

```bash
sudo docker run -d --name beta -p 3000:80 nginx:alpine
```

### Step 4: Verify container is running with correct port mapping

```bash
sudo docker ps | grep beta
```

**Expected output:**
```
CONTAINER ID   IMAGE          ...   STATUS        PORTS                  NAMES
abc123def456   nginx:alpine   ...   Up X seconds  0.0.0.0:3000->80/tcp   beta
```

The `PORTS` column shows `0.0.0.0:3000->80/tcp` — confirming host port 3000 maps to container port 80. ✅

### Step 5: Test the port mapping

```bash
curl http://localhost:3000
```

**Expected:** nginx welcome page HTML ✅

---

## 📌 Commands Reference

```bash
# ─── Pull and run ────────────────────────────────────────
sudo docker pull nginx:alpine
sudo docker run -d --name beta -p 3000:80 nginx:alpine

# ─── Verify ──────────────────────────────────────────────
sudo docker ps | grep beta                   # Check STATUS and PORTS column
curl http://localhost:3000                   # Test from host
sudo docker port beta                        # Show all port mappings
# Expected: 80/tcp -> 0.0.0.0:3000

# ─── Port mapping reference ──────────────────────────────
docker run -p 3000:80 image                  # All interfaces
docker run -p 127.0.0.1:3000:80 image       # Localhost only
docker run -p 3000:80 -p 3001:443 image     # Multiple ports
docker run -P image                          # Auto-map all EXPOSE'd ports

# ─── Container management ────────────────────────────────
sudo docker stop beta
sudo docker start beta
sudo docker rm -f beta
```

---

## ⚠️ Common Mistakes to Avoid

1. **Reversing host and container port** — `-p 3000:80` means host:3000 → container:80. Reversing it to `-p 80:3000` maps host port 80 to a container port where nothing is listening.
2. **Host port already in use** — If port 3000 is already bound on the host, `docker run` fails with `bind: address already in use`. Check with `ss -tlnp | grep 3000` before running.
3. **Forgetting `-d`** — Without detached mode the terminal attaches to nginx output. Ctrl+C stops the container.
4. **Confusing EXPOSE with `-p`** — `EXPOSE 80` in the Dockerfile is documentation. It does not make the port accessible. Only `-p 3000:80` at runtime actually publishes the port.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between `-p` and `-P` in `docker run`?**

`-p HOST_PORT:CONTAINER_PORT` (lowercase) explicitly maps a specific host port to a specific container port — you control exactly which ports are used. `-P` (uppercase) automatically maps all ports declared with `EXPOSE` in the Dockerfile to random ephemeral ports on the host (typically in the 32768–60999 range). `-P` is convenient for development when you don't care which host port is used, but unreliable for production where you need predictable, stable port assignments. In production, always use explicit `-p` mappings.

---

**Q2: How do you find out which host port a container is using if it was started with `-P`?**

`docker port container_name` lists all port mappings for a container. `docker ps` also shows the PORTS column. For `-P` containers where random ports were assigned, `docker port beta` shows something like `80/tcp -> 0.0.0.0:32768` — telling you the randomly assigned host port. In scripts, `docker port beta 80` returns just the host port number for container port 80, which is useful for automation that needs to discover the actual host port dynamically.

---

**Q3: Can two containers both map to the same host port?**

No. A host port can only be bound by one process at a time. If container `beta` is using host port 3000 and you try to run another container with `-p 3000:80`, Docker returns `bind: address already in use` and the container fails to start. Each container must use a unique host port. This is why in multi-service deployments you use different host ports for each service (`-p 3000:80`, `-p 3001:80`, `-p 3002:80`) or put a reverse proxy (nginx, Traefik) in front that handles routing to containers on internal Docker network ports.

---

**Q4: What does `0.0.0.0:3000->80/tcp` in `docker ps` mean?**

`0.0.0.0` means the port is bound to all network interfaces on the host — the container is reachable on port 3000 from localhost, the host's LAN IP, and any other bound interface. `3000->80/tcp` means host port 3000 maps to container port 80 over TCP. If you see `127.0.0.1:3000->80/tcp` instead, the port is bound only to localhost and is not reachable from other machines. The `0.0.0.0` binding is what makes the service externally accessible.

---

**Q5: How does Docker port mapping work under the hood?**

Docker uses Linux `iptables` NAT rules to implement port mapping. When you run `-p 3000:80`, Docker adds a DNAT (Destination NAT) iptables rule that rewrites packets arriving at host port 3000, redirecting them to the container's IP on port 80. The `docker-proxy` process (or `iptables` directly in newer configurations) handles this translation. You can see these rules with `sudo iptables -t nat -L -n`. This is why Docker requires root privileges and why port mapping works transparently — the redirection happens at the kernel networking level before traffic ever reaches user space.

---

**Q6: What is the difference between host networking (`--network host`) and port mapping (`-p`)?**

With port mapping (`-p 3000:80`), the container has its own isolated network namespace and Docker NATs traffic between host port 3000 and container port 80. The container's internal IP is separate from the host's IP. With host networking (`--network host`), the container shares the host's network namespace entirely — there is no network isolation, no NAT, and no port mapping needed. If nginx listens on port 80 inside a host-networked container, it's literally binding to the host's port 80 directly. Host networking gives slightly better network performance (no NAT overhead) but eliminates isolation. It's used for network-intensive applications or when containers need to access host network services directly.

---

## 🔗 References

- [`docker run` — Port Publishing](https://docs.docker.com/engine/reference/commandline/run/#publish)
- [Docker Networking — Published Ports](https://docs.docker.com/network/#published-ports)
- [`docker port` documentation](https://docs.docker.com/engine/reference/commandline/port/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
