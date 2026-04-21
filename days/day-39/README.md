# Day 39 — Creating a Docker Image from a Running Container using `docker commit`

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Containerization / Docker  
**Difficulty:** Beginner  
**Phase:** Phase 3 — Kubernetes & Orchestration  
**Status:** ✅ Completed

---

## 📋 Task Summary

On **App Server 2** (`stapp02`), create a new Docker image `beta:xfusion` from the running container `ubuntu_latest`. This preserves the container's current state — including any changes made inside it — as a reusable image.

---

## 🧠 Concept — `docker commit`

### What `docker commit` Does

`docker commit` creates a new image from a container's **current filesystem state** — including all changes made inside the container since it was started. The result is a new image layer on top of the original base image.

```
ubuntu_latest container
  ├── Base image layers (read-only)
  └── Writable layer (changes made inside container)
          │
          docker commit
          │
          ▼
beta:xfusion image
  ├── All original base layers (inherited)
  └── New layer (writable layer captured as read-only)
```

### When to Use `docker commit`

| Use Case | Description |
|----------|-------------|
| **Backup/snapshot** | Save current container state before risky changes |
| **Quick image creation** | Capture a working environment without writing a Dockerfile |
| **Debugging** | Snapshot a broken container for offline analysis |
| **Sharing a dev environment** | Commit a configured container and share the image |

### `docker commit` vs Dockerfile

| Method | Reproducible? | Recommended for? |
|--------|--------------|-----------------|
| `docker commit` | ❌ No audit trail | Quick snapshots, debugging, backups |
| `Dockerfile` | ✅ Declarative, versioned | Production images, CI/CD pipelines |

> **Real-world context:** `docker commit` is the operational escape hatch — when a developer has spent hours configuring a container and needs to preserve that work before something changes. In production, all images should be built from Dockerfiles committed to version control. But during development and debugging, `docker commit` is invaluable for capturing state. Understanding both approaches — and when each is appropriate — is what distinguishes a pragmatic DevOps engineer from a purist.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 2 (`stapp02`) |
| User | steve |
| Source container | `ubuntu_latest` |
| New image name | `beta` |
| New image tag | `xfusion` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 2

```bash
ssh steve@stapp02
```

### Step 2: Verify the container is running

```bash
sudo docker ps | grep ubuntu_latest
```

**Expected:**
```
CONTAINER ID   IMAGE    ...   STATUS        NAMES
abc123def456   ubuntu   ...   Up X minutes  ubuntu_latest
```

### Step 3: Commit the container as a new image

```bash
sudo docker commit ubuntu_latest beta:xfusion
```

**Expected output:**
```
sha256:def456abc789...
```

The SHA-256 hash of the newly created image. ✅

### Step 4: Verify the image was created

```bash
sudo docker images | grep beta
```

**Expected:**
```
REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
beta         xfusion   def456abc789   X seconds ago    77.9MB
```

### Step 5: Inspect the image (optional but thorough)

```bash
sudo docker image inspect beta:xfusion
```

Confirms the parent image, creation time, and layer history.

---

## 📌 Commands Reference

```bash
# ─── Verify container ────────────────────────────────────
sudo docker ps | grep ubuntu_latest

# ─── Commit container to image ───────────────────────────
sudo docker commit ubuntu_latest beta:xfusion

# ─── Verify image created ────────────────────────────────
sudo docker images | grep beta
sudo docker image inspect beta:xfusion

# ─── docker commit with metadata ─────────────────────────
sudo docker commit \
  --author "DevOps Team" \
  --message "Backup of ubuntu_latest dev environment" \
  ubuntu_latest beta:xfusion

# ─── Run a container from the new image ──────────────────
sudo docker run -it beta:xfusion /bin/bash

# ─── View commit history / layers ────────────────────────
sudo docker history beta:xfusion
```

---

## ⚠️ Common Mistakes to Avoid

1. **Committing a stopped container** — `docker commit` works on stopped containers too, but verify the container state matches what you intend to capture. Always `docker ps` first.
2. **Using `docker commit` for production images** — Production images should always come from Dockerfiles. `docker commit` produces images with no audit trail — nobody knows what was run inside the container to produce that state. Use Dockerfiles for anything that goes to production.
3. **Forgetting the image format is `name:tag`** — `docker commit container beta:xfusion` not `docker commit container beta xfusion`. The colon separates name from tag in a single argument.
4. **Expecting volumes to be committed** — `docker commit` captures the container's union filesystem but NOT mounted volumes. Data in volume-mounted directories is not included in the committed image.

---

## 🔍 How `docker commit` Builds the Image Layer

```
Original ubuntu image:
  Layer 1: Ubuntu base filesystem    [read-only]
  Layer 2: Default packages          [read-only]

ubuntu_latest container:
  Layer 1: Ubuntu base               [read-only]
  Layer 2: Default packages          [read-only]
  Layer 3: Writable layer            ← changes made inside

After docker commit ubuntu_latest beta:xfusion:
  Layer 1: Ubuntu base               [read-only]
  Layer 2: Default packages          [read-only]
  Layer 3: Former writable layer     [now read-only] ← captured
```

The committed image is the original image with an additional read-only layer containing all filesystem changes from the container's writable layer.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is `docker commit` and how does it differ from building with a Dockerfile?**

`docker commit` creates a new image by capturing the current filesystem state of a running or stopped container — including all changes made inside it since the container started. It's fast and requires no Dockerfile. A Dockerfile defines image construction declaratively — each instruction creates a layer, and the file is version-controlled alongside the application code. The key difference is reproducibility: a Dockerfile can be rebuilt at any time to produce the same image. A `docker commit` image has no record of how it was created — you can't recreate it without the exact container state. For production, Dockerfiles are mandatory. For quick snapshots and debugging, `docker commit` is the pragmatic choice.

---

**Q2: Are Docker volumes committed when you run `docker commit`?**

No. `docker commit` only captures the container's union filesystem — the layered overlay that represents the container's internal state. Data in volume-mounted directories (`-v /host/path:/container/path` or named volumes) exists outside the container's union filesystem on the host and is explicitly excluded from the commit. If a developer has important data in a mounted volume, they need to copy it into the container's filesystem first before committing. This is a common source of confusion — developers commit a container and later discover their database files or application data are missing from the new image.

---

**Q3: How does the image size after `docker commit` compare to the original base image?**

The committed image is always larger than or equal to the base image. Every change made inside the container — installed packages, created files, modified configs — is captured as an additional layer on top of the base. If a developer `apt install`ed several packages and created dozens of files, the committed image could be significantly larger. Notably, `docker commit` doesn't benefit from Docker's layer deduplication for new content — even if you delete a file inside a container, the original layer containing that file still exists, and the deletion is recorded as a separate "whiteout" entry in the new layer. This is one of the reasons Dockerfiles with multi-stage builds produce leaner images than committed containers.

---

**Q4: Can you inspect what changed inside a container before committing it?**

Yes. `docker diff container_name` shows all filesystem changes since the container started — files added (`A`), changed (`C`), or deleted (`D`). This is useful to review exactly what will be captured before committing. For example: `docker diff ubuntu_latest` might show `A /opt/nautilus.txt.gpg` from Day 37's task and any other changes the developer made. Running `docker diff` before `docker commit` is good practice — it confirms you're capturing what you intend and nothing unexpected.

---

**Q5: How would you share a `docker commit` image with another team member?**

After creating the image with `docker commit`, save it as a tar archive: `docker save beta:xfusion | gzip > beta-xfusion.tar.gz`. The other person loads it with `docker load < beta-xfusion.tar.gz`. For team-wide sharing, the better approach is to push to a registry: tag the image for your registry (`docker tag beta:xfusion myregistry.io/beta:xfusion`), authenticate, and push (`docker push myregistry.io/beta:xfusion`). Team members can then `docker pull myregistry.io/beta:xfusion`. The registry approach is preferred because it provides versioning, access control, and availability without manual file transfers.

---

**Q6: What is `docker history` and how does it help after a `docker commit`?**

`docker history image_name` shows the layer history of an image — each layer, its size, and the command that created it. For images built from Dockerfiles, each layer corresponds to a Dockerfile instruction with the command clearly visible. For images created with `docker commit`, the committed layer shows a generic message without the specific commands run inside the container. This is the audit trail problem with `docker commit` — `docker history beta:xfusion` will show the base image layers clearly but the committed layer just says something like `<missing>` or a generic string. This reinforces why Dockerfiles are preferred for anything important: every layer is self-documenting.

---

## 🔗 References

- [`docker commit` documentation](https://docs.docker.com/engine/reference/commandline/commit/)
- [`docker diff` documentation](https://docs.docker.com/engine/reference/commandline/diff/)
- [`docker history` documentation](https://docs.docker.com/engine/reference/commandline/history/)
- [Best Practices — Use Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
