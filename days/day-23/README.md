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

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: What's the difference between a fork, a clone, and a branch? Engineers often confuse these.**

| Action | Location | Purpose |
|--------|----------|---------|
| Fork | Server-side (GitHub/Gitea) | Your own independent server copy |
| Clone | Local machine | Download any repo to work locally |
| Branch | Inside a repo (local or remote) | Isolated line of work within the same repo |

> Fork = separate repo. Clone = local copy. Branch = pointer inside a repo. You typically do all three: fork on the server → clone your fork locally → create a branch to work on. They solve different problems at different levels.

---

**Q2: After forking `sarah/story-blog` to `jon/story-blog`, sarah pushes new commits. How does jon get them?**

```bash
# jon's local clone
cd story-blog

# Add upstream remote (only needed once)
git remote add upstream http://gitea/sarah/story-blog

# Fetch and merge latest from sarah's repo
git fetch upstream
git checkout main
git merge upstream/main

# Push synced main to jon's fork
git push origin main
```

> The `upstream` remote is the connection back to the original repo. Without it, jon's fork drifts out of date. `git fetch upstream` + `git merge upstream/main` keeps it current. This sync workflow is standard for anyone maintaining a long-lived fork.

---

**Q3: Why does the open-source contribution model require forking instead of just branching in the original repo?**

> You don't have write access to `sarah/story-blog`. Forking gives you a repo you **own** (`jon/story-blog`) where you have full push access. You work there, then propose changes back to the original via a Pull Request — which sarah can review and accept or reject.
>
> Branching directly in `sarah/story-blog` would require her to grant you write access — unacceptable for public repos with thousands of contributors. The fork model lets anyone contribute without needing trust upfront.

---

**Q4: In enterprise Gitea/GitLab, when would you fork within the same organization vs just branch?**

> - **Branch**: You're already a member of the project, working on a feature within the team's normal workflow
> - **Fork (within org)**: You're prototyping a significant experiment that might be abandoned, or you want to maintain an independent version of a shared tool
>
> In most enterprise teams, internal contribution goes through branches + PRs. Forks are more common for: inner-source projects where teams consume but don't own the repo, or for maintaining a customized version of a shared library.

---

**Q5: How would a DevOps engineer automate the fork → clone → configure upstream workflow for a new developer onboarding?**

```bash
#!/bin/bash
# Gitea API: fork the repo for the new dev
curl -X POST "http://gitea/api/v1/repos/sarah/story-blog/forks" \
  -H "Authorization: token ${JON_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"organization": "jon"}'

# Clone the fork
git clone "http://gitea/jon/story-blog.git" ~/story-blog
cd ~/story-blog

# Add upstream
git remote add upstream "http://gitea/sarah/story-blog.git"

# Verify
git remote -v
```

> Most Git platforms expose REST APIs for repo operations. Gitea, GitHub, and GitLab all support creating forks via API — useful for automating developer onboarding in large organizations.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
