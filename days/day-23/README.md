# Day 23 — Forking a Git Repository in Gitea

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Version Control / Git / Gitea  
**Difficulty:** Beginner  
**Phase:** Phase 2 — Infrastructure & Networking  
**Status:** ✅ Completed

---

## 📋 Task Summary

New developer `jon` needs to start contributing to an existing project. The workflow requires forking the repository `sarah/story-blog` on the Gitea server under the `jon` user account.

---

## 🧠 Concept — What is a Fork and Why It Matters

### Fork vs Clone vs Branch

These three are often confused. Each solves a different problem:

| Action | Where | Purpose |
|--------|-------|---------|
| **Fork** | Server-side (Gitea/GitHub) | Your own server copy of someone else's repo — independent |
| **Clone** | Local machine | Download any repo to work on locally |
| **Branch** | Inside a repo | Isolated line of work within the same repo |

### The Fork Workflow — Industry Standard

```
sarah/story-blog  (original — protected)
        │
        └── Fork ──────────────────────► jon/story-blog  (jon's copy)
                                                │
                                           git clone (local)
                                                │
                                           make changes
                                                │
                                           git push (to jon's fork)
                                                │
                                           Pull Request ──► sarah/story-blog
```

This pattern is used everywhere:
- **Open source contributions** — you can't push directly to someone else's repo
- **Code review workflows** — changes go through PRs before merging to main
- **Safe experimentation** — breaking changes in your fork don't affect the original

### Why Gitea?

Gitea is a **self-hosted Git service** — a lightweight, open-source alternative to GitHub that organizations run on their own infrastructure. It provides the same web UI experience (repositories, issues, PRs, organizations, forking) but runs entirely within your own network.

> **Real-world context:** Many enterprises run self-hosted Git servers (Gitea, GitLab CE, Bitbucket Server) for security and compliance reasons — keeping source code within their own infrastructure rather than on third-party platforms. As a DevOps engineer, you'll encounter and manage these platforms regularly. Understanding the fork → clone → PR workflow is foundational regardless of which Git platform the organization uses.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Git Platform | Gitea (self-hosted) |
| Login | `jon` / `Jon_pass123` |
| Source repository | `sarah/story-blog` |
| Fork destination | `jon/story-blog` |

---

## 🔧 Solution — Step by Step (Web UI)

### Step 1: Access the Gitea UI

Click the **Gitea UI** button in the KodeKloud lab top bar to open the Gitea web interface.

### Step 2: Log in as jon

```
Username: jon
Password: Jon_pass123
```

### Step 3: Navigate to the source repository

Go to: `http://<gitea-url>/sarah/story-blog`

Or use **Explore → Repositories** and search for `story-blog`.

### Step 4: Fork the repository

- Click the **Fork** button in the top-right area of the repository page (next to Watch and Star)
- In the fork dialog:
  - **Owner:** `jon` (already selected)
  - **Repository name:** `story-blog` (keep as-is)
- Click **Fork Repository**

### Step 5: Verify the fork was created

After forking, you're redirected to `jon/story-blog`. The page displays:

```
forked from sarah/story-blog
```

This confirms the fork is correctly linked to its upstream source. ✅

---

## 📌 What Happens After Forking — The Complete Workflow

Once the fork exists on Gitea, the typical developer workflow continues locally:

```bash
# Clone your fork to local machine
git clone http://<gitea-url>/jon/story-blog
cd story-blog

# Add upstream remote to track the original
git remote add upstream http://<gitea-url>/sarah/story-blog

# Verify remotes
git remote -v
# origin    http://<gitea>/jon/story-blog   (fetch)
# origin    http://<gitea>/jon/story-blog   (push)
# upstream  http://<gitea>/sarah/story-blog (fetch)
# upstream  http://<gitea>/sarah/story-blog (push)

# Create feature branch
git checkout -b feature/my-changes

# Make changes, commit, push to YOUR fork
git push origin feature/my-changes

# Then open a Pull Request on Gitea: jon/story-blog → sarah/story-blog
```

### Keeping Your Fork in Sync with Upstream

```bash
# Fetch latest changes from original repo
git fetch upstream

# Merge upstream main into your local main
git checkout main
git merge upstream/main

# Push synced main to your fork
git push origin main
```

---

## ⚠️ Key Points to Remember

1. **A fork is server-side** — It lives on Gitea, not on your local machine. You still need to `git clone` to work locally.
2. **Forks are independent** — Pushing to `jon/story-blog` does not affect `sarah/story-blog`. Changes only flow back through Pull Requests.
3. **The `upstream` remote is not set automatically** — After cloning your fork, manually add `upstream` to track the original. Without it, you can't easily sync changes from the original.
4. **Fork ≠ Branch** — A branch is inside a single repository. A fork is a separate repository that shares history with the original.

---

## 🔍 Fork vs Pull Request — The Full Cycle

```
1. FORK     → Create jon/story-blog from sarah/story-blog (server-side)
2. CLONE    → git clone http://gitea/jon/story-blog (local)
3. BRANCH   → git checkout -b feature/new-chapter
4. WORK     → edit files, git add, git commit
5. PUSH     → git push origin feature/new-chapter (to fork)
6. PR       → Open Pull Request: jon/story-blog → sarah/story-blog
7. REVIEW   → sarah reviews, approves, merges
8. SYNC     → git fetch upstream && git merge upstream/main
```

This cycle is identical whether you're on Gitea, GitHub, GitLab, or Bitbucket.

---

## 🔗 References

- [Gitea Documentation — Forking](https://docs.gitea.com/usage/forks)
- [GitHub Flow — Fork-based workflow](https://docs.github.com/en/get-started/quickstart/fork-a-repo)
- [Git — Working with Remotes](https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
