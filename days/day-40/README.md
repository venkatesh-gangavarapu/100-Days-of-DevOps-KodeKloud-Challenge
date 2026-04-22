# Day 40 — Installing & Configuring Apache Inside a Running Docker Container

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Containerization / Docker / Apache  
**Difficulty:** Intermediate  
**Phase:** Phase 3 — Kubernetes & Orchestration  
**Status:** ✅ Completed

---

## 📋 Task Summary

A developer was mid-task on a running container `kkloud` on **App Server 1** (`stapp01`) before going on PTO. Complete the remaining work:

1. Install `apache2` inside the `kkloud` container using `apt`
2. Configure Apache to listen on port `8088` (not the default 80)
3. Apache must listen on all interfaces — not bound to a specific IP
4. Start Apache service inside the container
5. Keep the container running at the end

---

## 🧠 Concept — Working Inside Running Containers

### `docker exec` — The Entry Point

`docker exec` runs a command inside an already-running container. It's how you interact with a container's environment without restarting it.

```bash
# Interactive shell
docker exec -it container_name /bin/bash

# Single command
docker exec container_name apache2ctl status
```

### Why No `systemctl` Inside Containers

Most Docker containers run a single main process (PID 1) — not a full init system like systemd. `systemctl` requires systemd as PID 1, which containers typically don't have. Instead, use:

| Context | Start Apache |
|---------|-------------|
| Host (RHEL/CentOS) | `systemctl start httpd` |
| Container (Debian/Ubuntu) | `apache2ctl start` or `service apache2 start` |

### Apache Port Configuration Files

On Debian/Ubuntu-based containers, Apache port configuration lives in two places:

```
/etc/apache2/ports.conf            ← Global Listen directives
/etc/apache2/sites-enabled/000-default.conf  ← VirtualHost port
```

Both must be updated when changing the port — `ports.conf` tells Apache what port to listen on, the VirtualHost config tells it which port the site responds on.

### Listen Directive — All Interfaces

```
Listen 8088          ← Listens on all interfaces (0.0.0.0:8088)
Listen 127.0.0.1:8088 ← Listens only on localhost
Listen 0.0.0.0:8088   ← Explicitly all interfaces
```

The task requires listening on all interfaces — `Listen 8088` without an IP prefix is correct. This means Apache responds on localhost, 127.0.0.1, the container's IP, and any other bound address.

> **Real-world context:** Configuring services inside running containers is a critical operational skill. Production containers often need emergency configuration changes — security patches, port adjustments, config fixes — without rebuilding the entire image. `docker exec` is how you get into a running container to make those changes. Understanding the differences between containerized service management (no systemd, different package managers, different service commands) and host-level management is essential for anyone operating containers in production.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 1 (`stapp01`) |
| User | tony |
| Container | `kkloud` |
| Base OS | Ubuntu (Debian-based — uses `apt`) |
| Apache port | `8088` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 1

```bash
ssh tony@stapp01
```

### Step 2: Verify kkloud container is running

```bash
sudo docker ps | grep kkloud
```

**Expected:**
```
CONTAINER ID   IMAGE   ...   STATUS        NAMES
abc123def456   ...     ...   Up X minutes  kkloud
```

### Step 3: Enter interactive shell inside container

```bash
sudo docker exec -it kkloud /bin/bash
```

You're now inside the container. Prompt changes to something like `root@abc123:/# `.

### Step 4: Update package list and install Apache

```bash
apt-get update
apt-get install -y apache2
```

### Step 5: Change Listen port in ports.conf

```bash
sed -i 's/^Listen 80/Listen 8088/' /etc/apache2/ports.conf
```

**Verify:**
```bash
grep "^Listen" /etc/apache2/ports.conf
# Expected: Listen 8088
```

### Step 6: Update VirtualHost port in default site config

```bash
sed -i 's/<VirtualHost \*:80>/<VirtualHost *:8088>/' \
  /etc/apache2/sites-enabled/000-default.conf
```

**Verify:**
```bash
grep "VirtualHost" /etc/apache2/sites-enabled/000-default.conf
# Expected: <VirtualHost *:8088>
```

### Step 7: Start Apache service

```bash
apache2ctl start
```

Or alternatively:
```bash
service apache2 start
```

**Expected output:**
```
AH00558: apache2: Could not reliably determine the server's fully qualified domain name...
```

This warning is normal — Apache starts fine despite it.

### Step 8: Verify Apache is running on port 8088

```bash
curl http://localhost:8088
```

**Expected:** Apache default page HTML — `<title>Apache2 Ubuntu Default Page</title>` ✅

**Alternative check:**
```bash
ss -tlnp | grep 8088
# or
netstat -tlnp | grep 8088
# Expected: apache2 listening on 0.0.0.0:8088
```

### Step 9: Exit the container — keep it running

```bash
exit
```

`exit` ends the `docker exec` session. The container itself keeps running — only the exec shell session closes.

### Step 10: Verify container is still running from host

```bash
sudo docker ps | grep kkloud
# Expected: STATUS "Up" ✅
```

### Step 11: Final verification from host

```bash
# Get container IP
sudo docker inspect kkloud --format '{{.NetworkSettings.IPAddress}}'

# Test Apache from host using container IP
curl http://<container-ip>:8088
```

✅ Apache installed, configured on 8088, running, container still up.

---

## 📌 Commands Reference

```bash
# ─── Access container ────────────────────────────────────
sudo docker exec -it kkloud /bin/bash

# ─── Inside container ────────────────────────────────────
apt-get update
apt-get install -y apache2

# Change port in ports.conf
sed -i 's/^Listen 80/Listen 8088/' /etc/apache2/ports.conf

# Change VirtualHost port
sed -i 's/<VirtualHost \*:80>/<VirtualHost *:8088>/' \
  /etc/apache2/sites-enabled/000-default.conf

# Verify config changes
grep "^Listen" /etc/apache2/ports.conf
grep "VirtualHost" /etc/apache2/sites-enabled/000-default.conf
apachectl configtest                     # Validate config syntax

# Start Apache
apache2ctl start
service apache2 start                    # Alternative

# Verify running
curl http://localhost:8088
ss -tlnp | grep 8088
ps aux | grep apache2

# Exit (container keeps running)
exit

# ─── From host ───────────────────────────────────────────
sudo docker ps | grep kkloud             # Container still running
sudo docker inspect kkloud \
  --format '{{.NetworkSettings.IPAddress}}'  # Get container IP
curl http://<container-ip>:8088          # Test from host
```

---

## ⚠️ Common Mistakes to Avoid

1. **Updating only `ports.conf` but not the VirtualHost** — Apache needs both updated. `ports.conf` defines what port it binds to; the VirtualHost config defines which port the site responds on. Missing either causes Apache to either not start or not serve on the expected port.
2. **Using `systemctl` inside the container** — Most containers don't run systemd. `apache2ctl start` or `service apache2 start` are the correct commands inside a Debian/Ubuntu container.
3. **Exiting with Ctrl+C instead of `exit`** — `exit` closes the exec shell session and keeps the container running. Ctrl+C inside a `docker exec -it` session may send SIGINT to processes running in the foreground.
4. **Not verifying with `curl` inside the container** — Checking `ps aux | grep apache` confirms the process is running but not that it's serving correctly. `curl http://localhost:8088` is the definitive test.
5. **Binding to a specific IP** — `Listen 127.0.0.1:8088` only works for localhost connections. The task requires `Listen 8088` (all interfaces) so the container IP and any bridge network address also work.

---

## 🔍 Apache Config File Structure (Debian/Ubuntu)

```
/etc/apache2/
  ├── apache2.conf          ← Main config (includes ports.conf)
  ├── ports.conf            ← Listen directives ← EDIT THIS
  ├── sites-available/
  │   └── 000-default.conf  ← Default site config
  ├── sites-enabled/
  │   └── 000-default.conf  ← Symlink to sites-available ← EDIT THIS
  ├── mods-available/       ← Available modules
  └── mods-enabled/         ← Active modules (symlinks)
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: Why can't you use `systemctl` inside most Docker containers?**

`systemctl` is the interface to systemd, which is an init system designed to run as PID 1 and manage the full system lifecycle — services, mounts, logging, timers. Docker containers are designed around a single main process as PID 1 — typically the application itself, not an init system. Without systemd running as PID 1, `systemctl` has nothing to communicate with and fails. Inside containers, you use the service's native start command (`apache2ctl`, `nginx`, `gunicorn`) or the legacy `service` command where available. If a container specifically needs systemd (for complex service orchestration), you can run privileged containers with systemd as PID 1, but this is rare and generally discouraged.

---

**Q2: What is the difference between `docker exec` and `docker attach`?**

`docker exec` runs a **new process** inside a running container — typically a shell like `/bin/bash`. You get a fresh interactive session that's separate from the container's main process (PID 1). When you `exit`, the exec process ends but the container and its main process continue running. `docker attach` connects your terminal directly to the container's **main process** (PID 1) stdin/stdout/stderr. If you press Ctrl+C while attached, you send SIGINT to PID 1 — which may stop the container entirely. For most operational work, `docker exec` is what you want because it's safe and non-destructive to the container's lifecycle.

---

**Q3: How do you make configuration changes inside a container persist across container restarts?**

Changes made inside a container's writable layer survive `docker stop` / `docker start` because the writable layer is preserved. They do NOT survive `docker rm` (container deletion) followed by `docker run` (new container from image). To persist changes across container recreation, three approaches work: (1) `docker commit` the container as a new image — changes become a permanent image layer. (2) Use a volume or bind mount for config files — the config lives on the host and survives container recreation. (3) Bake changes into the Dockerfile — rebuild the image with the configuration included. In production, option 3 (Dockerfile) is always preferred for reproducibility.

---

**Q4: How do you find out what IP address a Docker container has?**

`docker inspect container_name --format '{{.NetworkSettings.IPAddress}}'` returns the container's IP on the default bridge network. For containers on custom networks: `docker inspect container_name --format '{{json .NetworkSettings.Networks}}'` shows all network configurations. From inside the container, `hostname -I` or `ip addr` works like on any Linux system. Container IPs are assigned by Docker's internal DHCP and can change each time the container is recreated — for stable addressing, use container names as DNS hostnames on custom Docker networks or use host networking mode.

---

**Q5: What is `apachectl configtest` and when should you use it?**

`apachectl configtest` (or `apache2ctl configtest`) parses the Apache configuration files and reports any syntax errors without actually starting or restarting Apache. It's the Apache equivalent of `nginx -t`. Always run this before restarting Apache in production — a config syntax error on restart takes Apache offline completely. Inside a container: `apachectl configtest` should return `Syntax OK` before you run `apache2ctl start` or `service apache2 restart`. This saved-from-downtime habit applies to any service with a config validation command: `nginx -t`, `sshd -t`, `named-checkconf` — validate before restart, every time.

---

**Q6: How does `Listen 8088` differ from `Listen 0.0.0.0:8088` and `Listen 127.0.0.1:8088`?**

`Listen 8088` without an IP address binds Apache to **all available network interfaces** on the system — equivalent to `0.0.0.0:8088` for IPv4 and `:::8088` for IPv6. This means it responds on localhost (127.0.0.1), the container's assigned IP (e.g. 172.17.0.3), and any other bound address. `Listen 0.0.0.0:8088` explicitly binds to all IPv4 interfaces only. `Listen 127.0.0.1:8088` binds only to the loopback interface — only connections from inside the container itself work, which defeats the purpose of a web server meant to be reached from outside. The task requires `Listen 8088` specifically because the service must be reachable from the container IP, not just localhost.

---

## 🔗 References

- [Apache httpd — Binding to Addresses and Ports](https://httpd.apache.org/docs/2.4/bind.html)
- [`docker exec` documentation](https://docs.docker.com/engine/reference/commandline/exec/)
- [Running Services in Docker Containers](https://docs.docker.com/config/containers/multi-service_container/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
