# Day 38 — Docker Image Management: Pull & Re-tag

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Containerization / Docker  
**Difficulty:** Beginner  
**Phase:** Phase 3 — Kubernetes & Orchestration  
**Status:** ✅ Completed

---

## 📋 Task Summary

On **App Server 2** (`stapp02`):

1. Pull the `busybox:musl` image from Docker Hub
2. Re-tag it as `busybox:blog`

---

## 🧠 Concept — Docker Image Tagging

### What is a Docker Tag?

A tag is a **label that points to a specific image layer set**. Tags don't copy image data — they create a new pointer to the same underlying layers. Two tags with the same Image ID share 100% of their storage.

```
busybox:musl  ──►  Image ID: abc123  ──►  Layer data (1.41MB)
busybox:blog  ──►  Image ID: abc123  ──┘  (same layers, no duplication)
```

### Why Re-tag Images?

| Use Case | Example |
|----------|---------|
| Internal naming convention | `busybox:musl` → `busybox:blog` |
| Promote to private registry | `nginx:alpine` → `myregistry.io/nginx:v1.0` |
| Environment promotion | `myapp:build-123` → `myapp:staging` → `myapp:prod` |
| Pin a version | `postgres:latest` → `postgres:stable` (prevents drift) |

### `docker tag` Syntax

```bash
docker tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]

# Examples:
docker tag busybox:musl busybox:blog
docker tag nginx:alpine myregistry.io/myteam/nginx:v1.0-prod
docker tag myapp:latest myapp:2024-04-16
```

> **Real-world context:** Re-tagging is a core part of every CI/CD pipeline. A build pipeline typically pulls a base image, builds an application image, tags it with a build number (`myapp:build-456`), runs tests, and if tests pass, re-tags it as `myapp:stable` or `myapp:latest` before pushing to the registry. The tag is the promotion mechanism — the image content doesn't change, only the label that points to it.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 2 (`stapp02`) |
| User | steve |
| Source image | `busybox:musl` |
| Target tag | `busybox:blog` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 2

```bash
ssh steve@stapp02
```

### Step 2: Pull the busybox:musl image

```bash
sudo docker pull busybox:musl
```

**Expected output:**
```
musl: Pulling from library/busybox
...
Status: Downloaded newer image for busybox:musl
docker.io/library/busybox:musl
```

### Step 3: Re-tag as busybox:blog

```bash
sudo docker tag busybox:musl busybox:blog
```

No output on success — this is normal.

### Step 4: Verify both tags exist and share the same Image ID

```bash
sudo docker images | grep busybox
```

**Expected output:**
```
REPOSITORY   TAG    IMAGE ID       CREATED       SIZE
busybox      musl   abc123def456   X days ago    1.41MB
busybox      blog   abc123def456   X days ago    1.41MB
```

Same Image ID confirms both tags point to the same image. ✅

---

## 📌 Commands Reference

```bash
# ─── Pull image ──────────────────────────────────────────
sudo docker pull busybox:musl

# ─── Re-tag ──────────────────────────────────────────────
sudo docker tag busybox:musl busybox:blog

# ─── Verify ──────────────────────────────────────────────
sudo docker images | grep busybox
sudo docker image inspect busybox:blog --format '{{.Id}}'   # check ID
sudo docker image inspect busybox:musl --format '{{.Id}}'   # must match

# ─── Tag reference ───────────────────────────────────────
# Tag for private registry
docker tag busybox:musl myregistry.io/busybox:blog

# Tag with build number
docker tag myapp:latest myapp:build-$(date +%Y%m%d)

# Remove a tag (doesn't delete image if other tags exist)
docker rmi busybox:blog
```

---

## ⚠️ Common Mistakes to Avoid

1. **Thinking `docker tag` copies the image** — It doesn't. It creates a new pointer to the same Image ID. Both tags share the same storage — no duplication.
2. **Removing a tag thinking it deletes the image** — `docker rmi busybox:blog` removes the `blog` tag only. The `musl` tag and underlying image data remain. The image is only deleted when all tags pointing to it are removed.
3. **Forgetting to pull before tagging** — If `busybox:musl` doesn't exist locally, `docker tag` fails. Always `docker pull` first.
4. **Confusing tag with digest** — A tag is mutable — `busybox:latest` today may be a different image tomorrow. A digest (`busybox@sha256:abc123`) is immutable — it always points to the same exact image. For reproducible deployments, use digests.

---

## 🔍 Image Tags vs Image Digests

```bash
# Tag — mutable pointer (can change over time)
busybox:musl

# Digest — immutable pointer (always same image)
busybox@sha256:abc123def456...

# See digest for an image
docker inspect busybox:musl --format '{{.RepoDigests}}'
```

In production CI/CD pipelines, pinning to digests instead of tags prevents unexpected image updates from breaking deployments.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What does `docker tag` actually do under the hood — does it copy the image?**

No copy happens. `docker tag` creates a new entry in Docker's local image store that points to the same Image ID and underlying layer data. Both `busybox:musl` and `busybox:blog` share 100% of their storage — if the image is 1.41MB, two tags still only consume 1.41MB total. Tagging is essentially creating an alias. This is why you can have dozens of tags for the same image with virtually no storage overhead.

---

**Q2: What is the difference between an image tag and an image digest?**

A tag is a mutable human-readable label — `nginx:latest` today might point to a completely different image next week when the maintainer updates it. A digest is a SHA-256 hash of the image manifest — it's immutable and always refers to the exact same image regardless of when or where it's used. For production deployments, pinning to digests (`nginx@sha256:abc123...`) ensures reproducibility — your deployment 6 months from now uses exactly the same image as today. Tags are convenient for development; digests are reliable for production.

---

**Q3: How does image tagging work in a typical CI/CD pipeline?**

A typical pipeline uses tags to track image promotion through environments. The build step creates an image tagged with a build identifier: `myapp:build-456`. Automated tests run against that specific tag. If tests pass, the image is re-tagged as `myapp:staging` and deployed to staging. After staging validation, it's re-tagged as `myapp:prod-2026-04-16` and `myapp:latest` before production deployment. The same image layers move through every stage — only the tag changes. This makes rollback simple: `docker tag myapp:prod-2026-04-15 myapp:latest` points production back to the previous build instantly.

---

**Q4: What is the difference between `busybox:musl` and `busybox:glibc`?**

Both are BusyBox distributions but with different C standard libraries. `glibc` (GNU C Library) is the default on most Linux distributions — it's larger but highly compatible with most software. `musl` is a lightweight, security-focused alternative C library used in Alpine Linux — it's smaller and faster but occasionally has compatibility differences with software compiled specifically for glibc. For container images, `musl`-based variants like Alpine are preferred when size matters and the application doesn't have glibc-specific dependencies.

---

**Q5: When would you push a re-tagged image to a private registry?**

In any organization running a private container registry (AWS ECR, Google Artifact Registry, Harbor, Nexus). The typical workflow: pull a public base image from Docker Hub, apply security patches or customizations, tag it with your registry URL (`myregistry.io/team/busybox:blog`), and push it to your private registry. This serves several purposes — you control the image supply chain (no dependency on Docker Hub availability), you can scan images for CVEs before they enter your environment, and you enforce which image versions teams are allowed to use. Most regulated industries (finance, healthcare) require all container images to come from a controlled internal registry.

---

**Q6: How do you remove an image tag without deleting the image itself?**

`docker rmi busybox:blog` removes the `blog` tag but leaves `busybox:musl` and the underlying image data intact — as long as at least one other tag points to the same Image ID. Docker only deletes the actual image layers when the last tag pointing to that Image ID is removed. This is useful when cleaning up temporary build tags (`myapp:build-456`) after promoting to a stable tag, without losing the image itself. Running `docker images` after removal confirms the `blog` tag is gone while `musl` remains.

---

## 🔗 References

- [`docker tag` documentation](https://docs.docker.com/engine/reference/commandline/tag/)
- [`docker pull` documentation](https://docs.docker.com/engine/reference/commandline/pull/)
- [Docker Hub — busybox](https://hub.docker.com/_/busybox)
- [Docker Content Trust — Image Digests](https://docs.docker.com/engine/security/trust/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
