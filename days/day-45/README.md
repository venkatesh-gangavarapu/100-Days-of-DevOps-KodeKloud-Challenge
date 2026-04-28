# Day 45 — Debugging & Fixing a Broken Dockerfile

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Containerization / Docker / Dockerfile  
**Difficulty:** Intermediate  
**Phase:** 🏁 Phase 3 Complete — Kubernetes & Orchestration  
**Status:** ✅ Completed

---

## 📋 Task Summary

A Dockerfile at `/opt/docker/Dockerfile` on **App Server 2** (`stapp02`) was failing to build. The task was to:

1. Identify the errors in the existing Dockerfile
2. Fix only the broken instructions
3. Do NOT change the base image, valid config, or data files (e.g. index.html)
4. Confirm the image builds successfully

---

## 🧠 Concept — Common Dockerfile Errors & How to Spot Them

### The Debugging Approach

Never guess — always read the actual error output first:

```bash
cd /opt/docker
sudo docker build -t test-build . 2>&1
```

Docker's build output is precise — it tells you exactly which line failed and why. Read it before touching anything.

### Most Common Dockerfile Mistakes

| Error Type | Broken Example | Fixed Example |
|-----------|---------------|---------------|
| Wrong instruction case | `form ubuntu:20.04` | `FROM ubuntu:20.04` |
| Typo in instruction | `CPOY index.html /var/www/` | `COPY index.html /var/www/` |
| Missing package | `RUN apt-get install -y apche2` | `RUN apt-get install -y apache2` |
| No apt-get update | `RUN apt-get install -y curl` | `RUN apt-get update && apt-get install -y curl` |
| Wrong CMD format | `CMD apache2ctl start` | `CMD ["apache2ctl", "-D", "FOREGROUND"]` |
| COPY file doesn't exist | `COPY missing.html /var/www/` | Ensure file is in build context |
| Wrong EXPOSE port | `EXPOSE 8080` when serving on 80 | `EXPOSE 80` |
| No shebang in script | Script won't execute | Add `#!/bin/bash` |

### Reading Docker Build Error Output

```
Step 3/6 : RUN apt-get install -y apche2
 ---> Running in abc123def456
E: Unable to locate package apche2
The command '/bin/sh -c apt-get install -y apche2' returned a non-zero code: 100
```

This tells you:
- **Which step failed:** Step 3/6
- **Which instruction:** `RUN apt-get install -y apche2`
- **Why it failed:** Package `apche2` not found (typo — should be `apache2`)

### The Fix Strategy

1. Read the full Dockerfile with `cat`
2. Run `docker build` to see the exact error
3. Fix only the broken line(s)
4. Verify no other valid config was changed
5. Rebuild to confirm success

> **Real-world context:** Broken Dockerfiles are a daily occurrence in any team doing active development. Engineers inherit Dockerfiles from colleagues, copy-paste from documentation, or write them quickly under deadline. Knowing how to read build errors, identify the root cause, and fix precisely — without introducing new problems — is a critical skill. The constraint "don't change valid configuration" is exactly what you'd face inheriting a production Dockerfile: fix what's broken, leave everything else alone.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | App Server 2 (`stapp02`) |
| User | steve |
| Dockerfile location | `/opt/docker/Dockerfile` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into App Server 2

```bash
ssh steve@stapp02
```

### Step 2: Read the existing Dockerfile

```bash
cat /opt/docker/Dockerfile
```

### Step 3: Check build context files

```bash
ls -la /opt/docker/
```

Confirms what files are available for COPY instructions.

### Step 4: Attempt the build — read the error

```bash
cd /opt/docker
sudo docker build -t test-build . 2>&1
```

Docker's output identifies the exact failing line and error message.

### Step 5: Fix the identified errors

```bash
sudo vi /opt/docker/Dockerfile
```

Fix only what's broken. Common fixes:
- Correct instruction spelling/case
- Fix package typos
- Add missing `apt-get update` before `install`
- Fix CMD to use foreground mode
- Correct EXPOSE port

### Step 6: Rebuild to confirm the fix

```bash
cd /opt/docker
sudo docker build -t fixed-image .
```

**Expected:**
```
Successfully built abc123def456
Successfully tagged fixed-image:latest ✅
```

### Step 7: Verify the image exists

```bash
sudo docker images | grep fixed-image
```

---

## 📌 Commands Reference

```bash
# ─── Inspect the broken Dockerfile ───────────────────────
cat /opt/docker/Dockerfile
ls -la /opt/docker/           # Check build context files

# ─── Attempt build to see errors ─────────────────────────
cd /opt/docker
sudo docker build -t test-build . 2>&1

# ─── Fix the Dockerfile ──────────────────────────────────
sudo vi /opt/docker/Dockerfile

# ─── Rebuild and verify ──────────────────────────────────
sudo docker build -t fixed-image .
sudo docker images | grep fixed-image

# ─── Test the built image ────────────────────────────────
sudo docker run -d -p 80:80 --name test-container fixed-image
curl http://localhost:80
sudo docker rm -f test-container

# ─── Dockerfile validation (linting) ─────────────────────
# Install hadolint for Dockerfile linting:
# docker run --rm -i hadolint/hadolint < Dockerfile
```

---

## ⚠️ Common Mistakes to Avoid While Fixing

1. **Changing the base image** — The task explicitly prohibits this. Fix instructions, not the `FROM` line.
2. **Changing valid working instructions** — Only fix what's actually broken. If `RUN apt-get update` works, leave it alone.
3. **Modifying data files (index.html etc.)** — The task says do not change any data being used. Fix only the Dockerfile syntax/instructions.
4. **Introducing new errors while fixing old ones** — Fix one error, rebuild, confirm. Don't change multiple things at once if you're unsure.
5. **Not reading the full error message** — Docker error messages are precise. Read the entire output including the exit code and command that failed — it tells you exactly what to fix.

---

## 🔍 Dockerfile Instruction Quick Reference

```dockerfile
FROM image:tag              # Base image — first line, required
RUN command                 # Execute during build (creates layer)
COPY src dest               # Copy files from build context to image
ADD src dest                # Like COPY + supports URLs and tar extraction
WORKDIR /path               # Set working directory
ENV KEY=value               # Set environment variable
EXPOSE port                 # Document listening port (metadata)
CMD ["cmd", "arg"]          # Default run command (overridable)
ENTRYPOINT ["cmd", "arg"]   # Fixed run command (not easily overridable)
USER username               # Set user for subsequent instructions
VOLUME /path                # Create a mount point
ARG name=default            # Build-time variable
LABEL key=value             # Image metadata
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: How do you systematically debug a failing Docker build?**

Start by reading the build output carefully — Docker identifies the exact step and command that failed. Run `docker build . 2>&1 | tee build.log` to capture the full output. The error message after a failing `RUN` command is the actual shell error — a package not found, a file missing, a command not in PATH. Work top to bottom: if Step 3 fails, check Step 3's instruction first. After fixing, rebuild with `--no-cache` to ensure a clean build without cached layers masking residual issues. For complex builds, add intermediate `docker build --target stage_name` to test individual multi-stage layers.

---

**Q2: What does `2>&1` do when running `docker build`?**

`2>&1` redirects stderr (file descriptor 2) to stdout (file descriptor 1), merging both output streams. Docker writes build progress to stdout and error messages to stderr. Without `2>&1`, piping the output to `grep` or `tee` only captures stdout, missing the actual error messages. `docker build . 2>&1 | grep -i error` captures and filters both streams, making it much easier to spot errors in verbose build output.

---

**Q3: What is the difference between `CMD` and `RUN` in error context?**

`RUN` errors fail at **build time** — the image is never created. `CMD` errors only appear at **run time** — the image builds successfully but the container exits immediately when started. If `docker build` succeeds but `docker run` results in a container that immediately exits, check `docker logs container_name` — the CMD command likely errored. This distinction is important when debugging: build failures point to `RUN`, `COPY`, or `FROM` instructions; runtime failures point to `CMD` or `ENTRYPOINT`.

---

**Q4: Why is `RUN apt-get update && apt-get install` always written as a single command?**

Layer caching. If `apt-get update` and `apt-get install` are separate `RUN` instructions, Docker caches each layer independently. A cached `apt-get update` layer may be days or weeks old when `apt-get install` runs — resulting in stale package lists and "package not found" errors for recently renamed or moved packages. Chaining them with `&&` ensures they always run together in the same layer, guaranteeing the package index is fresh when packages are installed. This is one of the most common sources of intermittent Docker build failures in CI/CD pipelines.

---

**Q5: What is `hadolint` and when would you use it?**

`hadolint` is a Dockerfile linter that statically analyzes Dockerfiles for common mistakes, best practice violations, and potential issues — before you even attempt a build. It catches problems like `apt-get install` without `apt-get update`, using `ADD` where `COPY` is more appropriate, missing `--no-install-recommends` in apt installs, and many others. In CI/CD pipelines, running `hadolint Dockerfile` as an early check catches Dockerfile issues before wasting time on a full build. It integrates with most CI systems and can be run as a Docker container itself: `docker run --rm -i hadolint/hadolint < Dockerfile`.

---

**Q6: How do you fix a Dockerfile where a `COPY` instruction fails because the file doesn't exist?**

The build context is the directory passed to `docker build` (`.` means current directory). `COPY` can only reference files within the build context — you cannot COPY from outside it. If a file is missing, either: (1) the file needs to be created or placed in the build context directory, (2) the COPY path has a typo and should point to an existing file, or (3) the file is in a subdirectory and the path needs adjustment. Running `ls -la /opt/docker/` before building confirms what files are available in the build context. Never add files outside the build context path to fix this — fix the COPY instruction to reference what actually exists.

---

## 🔗 References

- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [hadolint — Dockerfile Linter](https://github.com/hadolint/hadolint)
- [Docker Build Troubleshooting](https://docs.docker.com/build/guide/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
