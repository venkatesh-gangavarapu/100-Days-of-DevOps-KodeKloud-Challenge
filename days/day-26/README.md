# Day 26 — Git Remote Management: Adding a New Remote & Pushing to It

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Version Control / Git / Remote Management  
**Difficulty:** Intermediate  
**Phase:** Phase 2 — Infrastructure & Networking  
**Status:** ✅ Completed

---

## 📋 Task Summary

In `/usr/src/kodekloudrepos/news` on the Storage Server:

1. Add a new remote `dev_news` pointing to `/opt/xfusioncorp_news.git`
2. Copy `/tmp/index.html` into the repo
3. `git add` and `git commit` on `master`
4. Push `master` to the new `dev_news` remote

---

## 🧠 Concept — Git Remotes & Multi-Remote Workflows

### What is a Git Remote?

A remote is a **named reference to another copy of the repository** — local path, SSH, or HTTPS. The name is just an alias for a URL/path.

```
Local repo: /usr/src/kodekloudrepos/news
  ├── origin   → /opt/news.git                  (already exists)
  └── dev_news → /opt/xfusioncorp_news.git       (added today)
```

`origin` is just a convention — the default name `git clone` assigns to the source. It has no special technical status. You can rename it, delete it, or have no remote named `origin` at all.

### Why Multiple Remotes?

| Scenario | Remote setup |
|----------|-------------|
| Fork + upstream | `origin` = your fork, `upstream` = original |
| Multi-environment deploy | `origin` = main, `staging` = staging server, `prod` = production |
| Mirror/backup | `origin` = primary, `backup` = secondary storage |
| This task | `origin` = `/opt/news.git`, `dev_news` = `/opt/xfusioncorp_news.git` |

### `git remote add` Syntax

```bash
git remote add <name> <url-or-path>

# Examples:
git remote add dev_news /opt/xfusioncorp_news.git      # local path
git remote add upstream https://github.com/org/repo    # HTTPS
git remote add production user@prod-server:/opt/repo   # SSH
```

### Pushing to a Specific Remote

```bash
git push <remote-name> <branch>

git push origin master       # push master to origin
git push dev_news master     # push master to dev_news
git push dev_news xfusion    # push xfusion branch to dev_news
```

When you have multiple remotes, always be explicit about which one you're pushing to. `git push` alone uses the configured upstream tracking branch — which may not be what you want when working with multiple remotes.

> **Real-world context:** Multiple remotes are standard in enterprise Git workflows. A developer's local repo might have `origin` pointing to their fork, `upstream` to the main repo, and `deploy` to a production server. CI/CD pipelines use multiple remotes to push build artifacts to different environments. Understanding how to add, rename, and push to specific remotes is essential for managing complex deployment topologies.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | Storage Server (`ststor01`) |
| User | natasha |
| Repository | `/usr/src/kodekloudrepos/news` |
| Existing remote | `origin` → `/opt/news.git` |
| New remote | `dev_news` → `/opt/xfusioncorp_news.git` |
| File to add | `/tmp/index.html` |
| Push target | `dev_news master` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into Storage Server

```bash
ssh natasha@ststor01
```

### Step 2: Navigate to the repository

```bash
cd /usr/src/kodekloudrepos/news
```

### Step 3: Check existing remotes (baseline)

```bash
git remote -v
```

**Expected:**
```
origin  /opt/news.git (fetch)
origin  /opt/news.git (push)
```

### Step 4: Add the new remote

```bash
git remote add dev_news /opt/xfusioncorp_news.git
```

### Step 5: Verify both remotes exist

```bash
git remote -v
```

**Expected:**
```
dev_news  /opt/xfusioncorp_news.git (fetch)
dev_news  /opt/xfusioncorp_news.git (push)
origin    /opt/news.git (fetch)
origin    /opt/news.git (push)
```

### Step 6: Ensure on master branch

```bash
git checkout master
git status
```

### Step 7: Copy index.html into the repository

```bash
cp /tmp/index.html .
```

### Step 8: Verify file is untracked

```bash
git status
```

**Expected:**
```
On branch master
Untracked files:
        index.html
```

### Step 9: Stage and commit

```bash
git add index.html
git commit -m "Add index.html to master branch"
```

**Expected:**
```
[master <hash>] Add index.html to master branch
 1 file changed, 1 insertion(+)
 create mode 100644 index.html
```

### Step 10: Push master to dev_news remote

```bash
git push dev_news master
```

**Expected:**
```
To /opt/xfusioncorp_news.git
 * [new branch]      master -> master
```

### Step 11: Verify final state

```bash
git remote -v                    # Both remotes present
git log --oneline -3             # Commit visible
```

✅ New remote added, file committed, master pushed to `dev_news`.

---

## 📌 Commands Reference

```bash
# ─── Navigate ────────────────────────────────────────────
cd /usr/src/kodekloudrepos/news

# ─── Remote management ───────────────────────────────────
git remote -v                                           # List remotes
git remote add dev_news /opt/xfusioncorp_news.git      # Add remote
git remote rename dev_news new_name                    # Rename remote
git remote remove dev_news                             # Remove remote
git remote set-url dev_news /new/path.git              # Update remote URL

# ─── Add and commit ──────────────────────────────────────
git checkout master
cp /tmp/index.html .
git add index.html
git commit -m "Add index.html to master branch"

# ─── Push to specific remote ─────────────────────────────
git push dev_news master           # Push master to dev_news
git push origin master             # Push master to origin (if needed)

# ─── Verify ──────────────────────────────────────────────
git remote -v
git log --oneline -3
git branch -a                      # See all remote-tracking branches
```

---

## ⚠️ Common Mistakes to Avoid

1. **Pushing to `origin` instead of `dev_news`** — The task requires pushing to the new remote. Always be explicit: `git push dev_news master`, not just `git push`.
2. **Adding a remote with the wrong path** — Double-check the path `/opt/xfusioncorp_news.git` before adding. A typo creates a remote pointing nowhere — push will fail.
3. **Not verifying with `git remote -v` after adding** — Always confirm both remotes are listed correctly before pushing.
4. **Running `git push` without specifying remote** — With multiple remotes, `git push` alone uses the tracking remote (usually `origin`). This would push to the wrong remote.
5. **Forgetting `git checkout master` first** — Commits on the wrong branch get pushed to the wrong place. Always verify branch before committing.

---

## 🔍 Git Remote Internals

After adding `dev_news`, Git stores it in `.git/config`:

```ini
[remote "origin"]
    url = /opt/news.git
    fetch = +refs/heads/*:refs/remotes/origin/*

[remote "dev_news"]
    url = /opt/xfusioncorp_news.git
    fetch = +refs/heads/*:refs/remotes/dev_news/*
```

You can directly edit `.git/config` to add, rename, or update remotes — it's plain text. `git remote` commands are just convenience wrappers around this file.

---

## 🔗 References

- [`git remote` documentation](https://git-scm.com/docs/git-remote)
- [Git — Working with Remotes](https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes)
- [`git push` documentation](https://git-scm.com/docs/git-push)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
