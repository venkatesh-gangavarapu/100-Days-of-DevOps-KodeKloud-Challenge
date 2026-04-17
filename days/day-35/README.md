# Day 35 — Installing Docker CE & Docker Compose on App Server 3

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Containerization / Docker  
**Difficulty:** Beginner–Intermediate  
**Phase:** Phase 3 — Kubernetes & Orchestration  
**Status:** ✅ Completed

---

## 📋 Task Summary

The Nautilus DevOps team is beginning containerization testing. On **App Server 3** (`stapp03`):

1. Install `docker-ce` and `docker compose`
2. Start the Docker service

---

## 🧠 Concept — Docker Architecture

### What is Docker?

Docker is a **containerization platform** that packages applications and their dependencies into isolated, portable containers. Unlike virtual machines, containers share the host OS kernel — making them lightweight, fast to start, and consistent across environments.

```
Traditional VM Stack:          Container Stack:
┌─────────────────┐            ┌──────────────────┐
│   Application   │            │  App A  │  App B  │
├─────────────────┤            ├─────────┴─────────┤
│   Guest OS      │            │   Container Runtime│
├─────────────────┤            ├───────────────────┤
│   Hypervisor    │            │   Host OS Kernel  │
├─────────────────┤            ├───────────────────┤
│   Hardware      │            │   Hardware        │
└─────────────────┘            └───────────────────┘
Full OS per VM (~GBs)          Shared kernel (~MBs)
```

### Docker CE vs Docker EE

| Edition | Full Name | Use Case |
|---------|-----------|---------|
| **Docker CE** | Community Edition | Open source, free — individuals and small teams |
| **Docker EE** | Enterprise Edition | Paid, with support SLA — enterprise production |

For this challenge and most DevOps work, Docker CE is the standard choice.

### Docker Compose

Docker Compose is a tool for defining and running **multi-container applications** using a `docker-compose.yml` file. Instead of running multiple `docker run` commands manually, you define all services, networks, and volumes in one YAML file and bring everything up with `docker compose up`.

```yaml
# Example docker-compose.yml
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
```

### docker compose vs docker-compose

| Version | Command | How installed |
|---------|---------|---------------|
| v1 (legacy) | `docker-compose` | Separate binary (`pip install`) |
| v2 (current) | `docker compose` | Built-in Docker plugin |

The modern approach is `docker-compose-plugin` — it installs as a Docker CLI plugin and is invoked as `docker compose` (no hyphen). The old standalone `docker-compose` binary is deprecated.

> **Real-world context:** Docker is the foundation of modern application deployment. Every Kubernetes pod runs containers. Every CI/CD pipeline builds Docker images. Every microservices architecture packages services as containers. Installing Docker CE and understanding its architecture is the essential first step before working with Kubernetes, container registries, CI/CD pipelines, and cloud container services like ECS, EKS, and GKE.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 3 (`stapp03`) |
| User | banner |
| OS | CentOS / RHEL-based |
| Packages | `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-compose-plugin` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 3

```bash
ssh banner@stapp03
```

### Step 2: Install required dependencies

```bash
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
```

These provide the storage driver and repo management tools Docker needs.

### Step 3: Add Docker's official repository

```bash
sudo yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo
```

### Step 4: Install Docker CE and Docker Compose plugin

```bash
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

**Package breakdown:**

| Package | Purpose |
|---------|---------|
| `docker-ce` | Docker Community Edition daemon |
| `docker-ce-cli` | Docker command-line interface |
| `containerd.io` | Container runtime (manages container lifecycle) |
| `docker-compose-plugin` | Docker Compose as a CLI plugin (`docker compose`) |

### Step 5: Start and enable Docker

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

`enable` ensures Docker starts automatically on every future reboot.

### Step 6: Verify Docker is running

```bash
sudo systemctl status docker
```

**Expected output:**
```
● docker.service - Docker Application Container Engine
   Active: active (running)
   Loaded: loaded ... enabled
```

### Step 7: Verify versions

```bash
docker --version
# Expected: Docker version 24.x.x

docker compose version
# Expected: Docker Compose version v2.x.x
```

### Step 8: End-to-end test

```bash
sudo docker run hello-world
```

**Expected output includes:**
```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

✅ Docker CE installed, service running, Compose available.

---

## 📌 Commands Reference

```bash
# ─── Installation ────────────────────────────────────────
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# ─── Service Management ──────────────────────────────────
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker
sudo systemctl restart docker

# ─── Verify ──────────────────────────────────────────────
docker --version
docker compose version
sudo docker run hello-world
sudo docker info                    # Full system info

# ─── Post-install: run docker without sudo ───────────────
sudo usermod -aG docker banner      # Add user to docker group
newgrp docker                       # Apply group without logout

# ─── Basic Docker commands reference ─────────────────────
docker images                       # List local images
docker ps                           # List running containers
docker ps -a                        # List all containers
docker pull nginx                   # Pull image from registry
docker run -d -p 80:80 nginx        # Run container in background
docker stop <container_id>          # Stop container
docker rm <container_id>            # Remove container
docker rmi <image_id>               # Remove image
```

---

## ⚠️ Common Mistakes to Avoid

1. **Starting Docker without enabling it** — `systemctl start` runs it now. `systemctl enable` makes it survive reboots. Always do both.
2. **Using `docker-compose` (v1) instead of `docker compose` (v2)** — The modern plugin is invoked without the hyphen. If you install `docker-compose-plugin`, the command is `docker compose`. The old hyphenated binary is separate and deprecated.
3. **Forgetting to add the Docker repo before install** — `yum install docker-ce` without adding the official Docker repo installs an outdated version from the default CentOS repos. Always add the Docker repo first.
4. **Running Docker commands without sudo** — By default, the Docker daemon socket is owned by root. Either prefix commands with `sudo` or add your user to the `docker` group with `usermod -aG docker <username>`.
5. **Not verifying with `hello-world`** — Always run the hello-world container after installation. It confirms the daemon is running, images can be pulled from Docker Hub, and containers can be started successfully.

---

## 🔍 Docker Architecture Deep Dive

```
docker run nginx
      │
      ▼
Docker CLI (docker-ce-cli)
      │
      ▼ REST API
Docker Daemon (dockerd)
      │
      ├── Image not local? → Pull from Docker Hub
      │
      ▼
containerd (container runtime)
      │
      ▼
runc (OCI runtime — creates the actual container)
      │
      ▼
Container running nginx ✅
```

Understanding this stack explains why there are multiple packages: `docker-ce` is the daemon, `docker-ce-cli` is the client, `containerd.io` is the runtime that actually manages containers.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between a Docker container and a virtual machine?**

Both provide isolated environments for running applications, but the mechanism is fundamentally different. A VM runs a full guest operating system on top of a hypervisor — each VM includes its own kernel, OS libraries, and binaries, consuming gigabytes of memory and taking minutes to boot. A container shares the host OS kernel and isolates only the application's filesystem, processes, and network namespace using Linux kernel features (namespaces and cgroups). Containers start in milliseconds, consume megabytes, and are portable across any host running the same container runtime. The tradeoff is isolation — VMs provide stronger isolation since each has its own kernel, while containers share the host kernel.

---

**Q2: What is `containerd` and why is it a separate package from Docker CE?**

`containerd` is an industry-standard container runtime that manages the complete container lifecycle — pulling images, creating containers, managing storage and network. Docker CE originally had its own runtime, but over time the runtime was extracted into `containerd` as a standalone CNCF project. This separation allows Kubernetes to use `containerd` directly without Docker CE — which is exactly how modern Kubernetes clusters work. When you install `docker-ce`, it sits on top of `containerd.io`. Understanding this separation matters because Kubernetes deprecated the Docker shim in v1.24 and now communicates with `containerd` directly.

---

**Q3: What happens when you run `docker run hello-world` for the first time?**

Docker follows this sequence: the CLI sends the run command to the Docker daemon. The daemon checks if the `hello-world` image exists locally — it doesn't. The daemon contacts Docker Hub (the default registry), authenticates if needed, and pulls the image layers. The layers are cached locally. The daemon passes the image to `containerd`, which uses `runc` to create a container from it. The container's process runs, prints the Hello from Docker message to stdout, and exits. The container is stopped but not removed. Running `docker ps -a` shows the stopped container. This entire sequence — registry pull, layer caching, runtime creation — is the core Docker workflow in miniature.

---

**Q4: What is the difference between `docker compose` (v2) and `docker-compose` (v1)?**

Docker Compose v1 was a standalone Python application installed separately as `docker-compose` (with a hyphen). It's now deprecated and no longer receives updates. Docker Compose v2 is a Go rewrite that ships as a Docker CLI plugin — installed as `docker-compose-plugin` and invoked as `docker compose` (no hyphen). V2 is faster, supports all modern Compose specification features, and is actively maintained. In production environments today, always use `docker compose` (v2). If you see scripts using `docker-compose` with a hyphen, they're using the legacy tool and should be updated.

---

**Q5: Why should `docker` service be enabled and not just started?**

`systemctl start docker` launches the Docker daemon for the current session only. If the server reboots — for maintenance, kernel update, or power event — the daemon doesn't restart and all containerized applications that depend on Docker being available will fail. `systemctl enable docker` creates a systemd symlink that ensures the daemon starts automatically at every boot. In production, always pair `start` with `enable`. The same principle applies to every service that must survive reboots: databases, web servers, monitoring agents — start it now, enable it for the future.

---

**Q6: How would you verify a Docker installation is fully working beyond just checking `systemctl status`?**

`systemctl status docker` only confirms the daemon process is running. A complete verification checks the full chain: `docker --version` confirms the CLI is installed, `docker info` shows daemon configuration and system resources, `docker run hello-world` confirms the daemon can pull images from a registry AND create and run containers. If `hello-world` succeeds, you've validated the CLI, daemon, network connectivity to Docker Hub, image layer download, local image storage, and container runtime — the entire stack in one command. In an air-gapped or restricted environment, you'd substitute a locally available image for the registry pull test.

---

## 🔗 References

- [Docker CE Installation — CentOS](https://docs.docker.com/engine/install/centos/)
- [Docker Compose v2 Plugin](https://docs.docker.com/compose/install/linux/)
- [containerd — CNCF Project](https://containerd.io/)
- [Docker Architecture Overview](https://docs.docker.com/get-started/overview/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
