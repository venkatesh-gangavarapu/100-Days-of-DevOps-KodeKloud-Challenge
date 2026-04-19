# Day 37 — Copying Files Between Docker Host and Container using `docker cp`

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Containerization / Docker  
**Difficulty:** Beginner  
**Phase:** Phase 3 — Kubernetes & Orchestration  
**Status:** ✅ Completed

---

## 📋 Task Summary

An encrypted file `/tmp/nautilus.txt.gpg` on **App Server 2** (`stapp02`) must be copied into the running container `ubuntu_latest` at `/opt/`. The file must not be modified during the operation.

---

## 🧠 Concept — `docker cp`

### What `docker cp` Does

`docker cp` copies files or directories between a Docker container and the host filesystem. It works in both directions — host to container or container to host. The container does **not** need to be running for `docker cp` to work (unlike `docker exec`), though it must exist.

```
# Host → Container
docker cp /host/path container_name:/container/path

# Container → Host
docker cp container_name:/container/path /host/path
```

### File Integrity During `docker cp`

`docker cp` performs a **byte-for-byte copy** — no compression, no encoding, no transformation of any kind. The file content, permissions, and timestamps are preserved. For encrypted files like `.gpg`, this is exactly what's needed — any modification to the binary content would corrupt the encryption.

The correct way to verify integrity after copying is to compare checksums:

```bash
md5sum /tmp/nautilus.txt.gpg           # on host
docker exec container md5sum /opt/nautilus.txt.gpg  # in container
# Both must be identical
```

### `docker cp` vs Volume Mounts

| Method | Use case | Persistent? |
|--------|---------|-------------|
| `docker cp` | One-time file transfer to/from existing container | Only while container exists |
| Volume mount (`-v`) | Ongoing shared filesystem between host and container | Persistent, survives restart |
| Bind mount | Same as volume but with explicit host path | Persistent |

`docker cp` is the right tool for ad-hoc file transfers to running containers. Volume mounts are the right tool for data that needs to persist or be shared continuously.

> **Real-world context:** `docker cp` is used constantly in operational work — copying config files into containers before restart, extracting log files or database dumps from containers for analysis, transferring SSL certificates, injecting test data. It's also a key tool for debugging: you can copy a script into a container and run it without rebuilding the image. Understanding `docker cp` is fundamental to day-to-day container operations.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 2 (`stapp02`) |
| User | steve |
| Source file | `/tmp/nautilus.txt.gpg` (on host) |
| Container | `ubuntu_latest` |
| Destination | `/opt/nautilus.txt.gpg` (inside container) |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 2

```bash
ssh steve@stapp02
```

### Step 2: Verify the source file exists on host

```bash
ls -lh /tmp/nautilus.txt.gpg
```

Confirms the file is present and shows its size — useful as a reference for post-copy verification.

### Step 3: Verify the container is running

```bash
sudo docker ps | grep ubuntu_latest
```

**Expected:**
```
CONTAINER ID   IMAGE    ...   STATUS        NAMES
abc123def456   ubuntu   ...   Up X minutes  ubuntu_latest
```

### Step 4: Copy the file from host to container

```bash
sudo docker cp /tmp/nautilus.txt.gpg ubuntu_latest:/opt/
```

**Syntax breakdown:**
```
docker cp  <source>                    <destination>
           /tmp/nautilus.txt.gpg       ubuntu_latest:/opt/
           └── host file path          └── container:path
```

No output on success — this is normal for `docker cp`.

### Step 5: Verify the file is inside the container

```bash
sudo docker exec ubuntu_latest ls -lh /opt/nautilus.txt.gpg
```

**Expected:**
```
-rw-r--r-- 1 root root 512 Apr 16 /opt/nautilus.txt.gpg
```

### Step 6: Verify file integrity — checksums must match

```bash
# Checksum on host
md5sum /tmp/nautilus.txt.gpg

# Checksum inside container
sudo docker exec ubuntu_latest md5sum /opt/nautilus.txt.gpg
```

**Expected:** Both lines show the **identical hash**:
```
d41d8cd98f00b204e9800998ecf8427e  /tmp/nautilus.txt.gpg
d41d8cd98f00b204e9800998ecf8427e  /opt/nautilus.txt.gpg
```

Identical checksums confirm the file was not modified during the copy. ✅

---

## 📌 Commands Reference

```bash
# ─── Verify prerequisites ────────────────────────────────
ls -lh /tmp/nautilus.txt.gpg                       # Source file exists
sudo docker ps | grep ubuntu_latest                # Container is running

# ─── Copy file host → container ──────────────────────────
sudo docker cp /tmp/nautilus.txt.gpg ubuntu_latest:/opt/

# ─── Verify in container ─────────────────────────────────
sudo docker exec ubuntu_latest ls -lh /opt/
sudo docker exec ubuntu_latest ls -lh /opt/nautilus.txt.gpg

# ─── Verify integrity ────────────────────────────────────
md5sum /tmp/nautilus.txt.gpg                       # Host checksum
sudo docker exec ubuntu_latest md5sum /opt/nautilus.txt.gpg  # Container checksum

# ─── docker cp reference ─────────────────────────────────
# Copy file: host → container
docker cp /host/file.txt container_name:/dest/path/

# Copy directory: host → container
docker cp /host/dir/ container_name:/dest/path/

# Copy file: container → host
docker cp container_name:/container/file.txt /host/dest/

# Copy from stopped container (also works)
docker cp stopped_container:/path/file.txt /host/dest/
```

---

## ⚠️ Common Mistakes to Avoid

1. **Wrong direction syntax** — `docker cp source destination`. Host→container: `docker cp /host/file container:/path`. Container→host: `docker cp container:/path /host/file`. Reversing these copies nothing useful.
2. **Destination path missing trailing slash** — `docker cp file ubuntu_latest:/opt/` copies the file into the `/opt/` directory. Without the trailing slash, Docker may rename the file to `opt` at the root level depending on whether `/opt` exists.
3. **Not verifying checksums** — The task requires the file not be modified. `ls` confirms presence but not integrity. Always use `md5sum` or `sha256sum` to confirm the copy is byte-identical, especially for encrypted or binary files.
4. **Container name vs container ID** — Both work with `docker cp`. `ubuntu_latest` is the container name. You can also use the container ID from `docker ps`. Names are more readable in commands and scripts.
5. **Assuming `docker cp` requires a running container** — Unlike `docker exec`, `docker cp` works on stopped containers too. The container just needs to exist.

---

## 🔍 `docker cp` Under the Hood

When you run `docker cp`, Docker:

1. Identifies the container's overlay filesystem (usually under `/var/lib/docker/overlay2/`)
2. Copies the file directly into the container's writable layer
3. The container doesn't need to be aware — no process interaction required
4. The file appears in the container's filesystem at the specified path

This is why `docker cp` works even on stopped containers — it's a filesystem operation, not a process operation.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is `docker cp` and when would you use it over a volume mount?**

`docker cp` copies files between the host and a container as a one-time operation — it doesn't require the container to be running, just to exist. A volume mount (`-v /host/path:/container/path`) creates a persistent, ongoing shared filesystem between host and container that updates in real time. Use `docker cp` for ad-hoc transfers: injecting a config file, extracting a log file, copying a certificate into a running container without restarting it. Use volume mounts when the data needs to persist across container restarts, be shared between multiple containers, or be updated continuously from the host side.

---

**Q2: How do you verify that a file copied into a container was not modified?**

Compare checksums before and after the copy. On the host: `md5sum /tmp/nautilus.txt.gpg`. Inside the container: `docker exec container_name md5sum /opt/nautilus.txt.gpg`. If both hashes are identical, the file is byte-for-byte identical — no modification occurred. For higher security requirements, use `sha256sum` instead of `md5sum` since SHA-256 is collision-resistant. This checksum verification approach applies to any file transfer scenario — SCP, rsync, S3 copies — not just Docker.

---

**Q3: Can you copy files to a stopped container? What about a paused container?**

Yes and yes. `docker cp` is a filesystem operation — it accesses the container's overlay filesystem directly, bypassing the container's running processes. A stopped container still has its filesystem intact (until `docker rm`), and `docker cp` works on it normally. A paused container's filesystem is also accessible. The only requirement is that the container exists (`docker ps -a` shows it). This is useful for recovering files from a crashed container that can't be restarted.

---

**Q4: What is the difference between `docker exec` and `docker cp` for working inside containers?**

`docker exec` runs a command inside a **running** container's process namespace — it requires the container to be active. It's used for interactive debugging (`docker exec -it container sh`), running scripts, checking processes, or any operation that needs to interact with the container's running environment. `docker cp` operates on the container's **filesystem** directly without involving running processes — it works on stopped containers and doesn't execute anything inside the container. Use `docker exec` when you need to run something inside the container; use `docker cp` when you just need to move files in or out.

---

**Q5: How would you extract application logs from a Docker container to the host for analysis?**

Two approaches: `docker logs container_name` streams the container's stdout/stderr to your terminal, which you can redirect to a file (`docker logs container_name > app.log 2>&1`). For log files written inside the container's filesystem (not to stdout), use `docker cp container_name:/var/log/app/error.log ./error.log` to copy them to the host. In production, neither approach scales — you'd configure a log driver (fluentd, splunk, json-file) or mount a volume to a centralized log directory so logs are accessible without `docker cp` or exec.

---

**Q6: What happens to a file copied into a container when the container is removed?**

The file is lost. `docker cp` writes to the container's writable layer — the thin layer on top of the image's read-only layers. When you `docker rm` the container, this writable layer is deleted along with everything in it, including your copied file. This is one of the fundamental properties of containers: they are ephemeral by default. To persist files across container recreation, use volume mounts or bind mounts so the data lives on the host filesystem independently of the container's lifecycle.

---

## 🔗 References

- [`docker cp` documentation](https://docs.docker.com/engine/reference/commandline/cp/)
- [Docker Storage Overview](https://docs.docker.com/storage/)
- [Docker Volumes vs Bind Mounts](https://docs.docker.com/storage/volumes/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
