# Day 34 — Git Hooks: Automated Release Tagging with post-update Hook

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Version Control / Git / Automation / Hooks  
**Difficulty:** Intermediate–Advanced  
**Phase:** Phase 3 — Kubernetes & Orchestration  
**Status:** ✅ Completed

---

## 📋 Task Summary

In `/usr/src/kodekloudrepos/ecommerce` on Storage Server:

1. Merge `feature` branch into `master`
2. Create a `post-update` hook in `/opt/ecommerce.git/hooks/` that auto-creates a release tag (`release-YYYY-MM-DD`) whenever master is pushed
3. Test the hook by pushing — confirm tag `release-2026-04-16` was created
4. Push all changes to origin

---

## 🧠 Concept — Git Hooks

### What are Git Hooks?

Git hooks are **shell scripts that execute automatically** when specific Git events occur. They live in the `.git/hooks/` directory (or `hooks/` in a bare repo) and fire at defined points in the Git workflow.

### Hook Types — Client-Side vs Server-Side

| Category | Hook | Triggers When |
|----------|------|---------------|
| **Client-side** | `pre-commit` | Before a commit is created |
| **Client-side** | `commit-msg` | After commit message is written |
| **Client-side** | `pre-push` | Before `git push` executes |
| **Server-side** | `pre-receive` | Before any ref is updated on server |
| **Server-side** | `update` | Once per ref being updated |
| **Server-side** | `post-receive` | After all refs updated — used for notifications |
| **Server-side** | **`post-update`** | After all refs updated — used for deployments/tagging |

### `post-update` Hook Specifically

The `post-update` hook:
- Runs **after** all refs have been updated on the server
- Receives the list of updated refs as **arguments** (`$@`)
- Is non-blocking — failures don't reject the push
- Lives in the **bare repo's** `hooks/` directory

```bash
# post-update receives updated refs as arguments:
# $1 = refs/heads/master
# $2 = refs/heads/feature  (if multiple refs pushed)
```

### Hook in the Bare Repo, Not the Working Clone

This is the most important distinction:

```
/usr/src/kodekloudrepos/ecommerce/  ← working clone (natasha works here)
  └── .git/hooks/                   ← client-side hooks (run on push FROM here)

/opt/ecommerce.git/                 ← bare repo (the "server")
  └── hooks/                        ← SERVER-SIDE hooks (run when push ARRIVES here)
      └── post-update               ← this is what we create
```

The `post-update` hook goes in the **bare repo** because it needs to run on the server side — after the push arrives.

### Why `git tag` Works Inside the Hook

When the hook runs inside `/opt/ecommerce.git/`, the working directory IS the bare repo. `git tag` without a `--git-dir` argument works correctly because Git detects the bare repo context.

> **Real-world context:** Git hooks are the foundation of lightweight automation. `post-receive` hooks deploy code to staging when you push to a staging branch. `pre-commit` hooks run linters and formatters before every commit. `post-update` hooks send notifications, create tags, or trigger build systems. Before sophisticated CI/CD tools like Jenkins and GitHub Actions became ubiquitous, entire deployment pipelines were driven by these hooks. Even today, many teams use them for simple, fast automations.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Server | Storage Server (`ststor01`) |
| User | natasha |
| Working repo | `/usr/src/kodekloudrepos/ecommerce` |
| Bare repo | `/opt/ecommerce.git` |
| Hook location | `/opt/ecommerce.git/hooks/post-update` |
| Tag format | `release-YYYY-MM-DD` |
| Today's tag | `release-2026-04-16` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH as natasha

```bash
ssh natasha@ststor01
```

### Step 2: Navigate to working repository

```bash
cd /usr/src/kodekloudrepos/ecommerce
```

### Step 3: Inspect current state

```bash
git branch -a
git log --oneline --all --graph
```

### Step 4: Merge feature into master

```bash
git checkout master
git merge feature
```

**Expected:**
```
Updating <hash>..<hash>
Fast-forward (or Merge made by...)
```

### Step 5: Create the post-update hook

```bash
cat > /opt/ecommerce.git/hooks/post-update << 'EOF'
#!/bin/bash
for ref in "$@"; do
    if [ "$ref" = "refs/heads/master" ]; then
        TAG_NAME="release-$(date +%Y-%m-%d)"
        git tag "$TAG_NAME"
        echo "Created release tag: $TAG_NAME"
    fi
done
EOF
```

**What this hook does:**
- Iterates over every ref updated by the push (`$@`)
- Checks if `refs/heads/master` is among them
- Creates a tag using today's date in `YYYY-MM-DD` format
- Echoes confirmation

### Step 6: Make the hook executable

```bash
chmod +x /opt/ecommerce.git/hooks/post-update
```

This is mandatory — Git silently ignores hooks that aren't executable.

### Step 7: Verify hook is correct

```bash
ls -la /opt/ecommerce.git/hooks/post-update
# Expected: -rwxr-xr-x (executable)

cat /opt/ecommerce.git/hooks/post-update
# Expected: script content as written
```

### Step 8: Push to origin (triggers the hook)

```bash
git push origin master
```

**Expected output includes:**
```
remote: Created release tag: release-2026-04-16
```

The `remote:` prefix means output came from the server-side hook. ✅

### Step 9: Verify the tag was created

```bash
# From working repo
git fetch --tags origin
git tag -l
# Expected: release-2026-04-16

# Or directly from bare repo
git --git-dir=/opt/ecommerce.git tag -l
# Expected: release-2026-04-16
```

✅ Hook fired, tag created, push successful.

---

## 📌 Commands Reference

```bash
# ─── Navigate ────────────────────────────────────────────
cd /usr/src/kodekloudrepos/ecommerce

# ─── Merge feature into master ───────────────────────────
git checkout master
git merge feature

# ─── Create post-update hook ─────────────────────────────
cat > /opt/ecommerce.git/hooks/post-update << 'EOF'
#!/bin/bash
for ref in "$@"; do
    if [ "$ref" = "refs/heads/master" ]; then
        TAG_NAME="release-$(date +%Y-%m-%d)"
        git tag "$TAG_NAME"
        echo "Created release tag: $TAG_NAME"
    fi
done
EOF

# ─── Make executable ─────────────────────────────────────
chmod +x /opt/ecommerce.git/hooks/post-update

# ─── Verify hook ─────────────────────────────────────────
ls -la /opt/ecommerce.git/hooks/post-update
cat /opt/ecommerce.git/hooks/post-update

# ─── Push (triggers hook) ────────────────────────────────
git push origin master
# Watch for: remote: Created release tag: release-2026-04-16

# ─── Verify tag created ──────────────────────────────────
git fetch --tags origin
git tag -l
git --git-dir=/opt/ecommerce.git tag -l
```

---

## ⚠️ Common Mistakes to Avoid

1. **Hook not executable** — The single most common hook failure. If the hook file doesn't have `+x` permission, Git silently skips it — no error, no output, nothing. Always `chmod +x` after creating.
2. **Hook in wrong location** — The `post-update` hook for server-side automation goes in `/opt/ecommerce.git/hooks/`, NOT in `/usr/src/kodekloudrepos/ecommerce/.git/hooks/`. Client-side hooks in the working clone won't fire on the server.
3. **Missing shebang line** — `#!/bin/bash` must be the first line. Without it, the OS doesn't know which interpreter to use.
4. **Not checking `$ref` against `refs/heads/master`** — Without the condition, the hook creates a tag on every push to any branch. The check ensures the tag only fires when master is updated.
5. **Not fetching tags after push** — `git tag -l` in the working repo won't show the new tag until you `git fetch --tags origin`.
6. **Changing repo permissions** — The task explicitly says not to alter existing permissions. Use `cat >` to write the hook file only.

---

## 🔍 Git Hooks — The Complete Server-Side Flow

```
Developer: git push origin master
                │
                ▼
Server receives push
                │
                ▼
pre-receive hook runs     ← can REJECT the push if it exits non-zero
                │
                ▼ (if pre-receive passes)
update hook runs          ← runs once per ref being updated
                │
                ▼
Refs are updated on server
                │
                ▼
post-receive hook runs    ← for notifications, deployments
                │
                ▼
post-update hook runs     ← for tagging, triggers ← TODAY'S HOOK
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What are Git hooks and where do they live?**

Git hooks are shell scripts that Git executes automatically at specific points in the workflow — before a commit, after a push, before a merge, and so on. Client-side hooks live in `.git/hooks/` of the working repository and run on the developer's machine. Server-side hooks live in `hooks/` of the bare repository and run when a push arrives at the server. A hook is only active if the file is executable — Git silently ignores non-executable hook files with no error or warning, which is why `chmod +x` is non-negotiable.

---

**Q2: What is the difference between `post-receive` and `post-update` hooks?**

Both are server-side hooks that run after a push is accepted, but they receive different arguments. `post-receive` receives the old ref, new ref, and ref name on stdin — one line per updated ref, giving you access to the full before/after state. `post-update` receives the updated ref names as command-line arguments (`$@`). In practice, `post-receive` is more commonly used for deployment triggers and notifications because it shows you what changed. `post-update` is simpler and suited for additive actions like creating tags — which is exactly the use case today.

---

**Q3: Why does `chmod +x` matter for Git hooks — what happens if you forget it?**

Git checks whether a hook file is executable before running it. If the file exists but lacks execute permission, Git silently skips it — no error is raised, no warning is logged, the hook simply doesn't run. This makes it one of the harder hook failures to debug because everything looks correct but nothing fires. Always verify with `ls -la /opt/ecommerce.git/hooks/post-update` and confirm the permission string starts with `-rwx`. This is the first thing to check whenever a hook that "should be working" isn't firing.

---

**Q4: In a production environment, how would you prevent a push to master if CI tests have not passed?**

Use a `pre-receive` hook on the bare repository. Unlike `post-update` (which runs after refs are already updated), `pre-receive` runs before any refs are updated — if it exits with a non-zero code, the entire push is rejected. Inside the hook, you call your CI system's API or check a build status file to verify test results for the incoming commit SHA. If tests didn't pass, `exit 1` rejects the push with a message back to the developer. This is the exact mechanism that platforms like GitHub and GitLab implement at scale for branch protection rules — the underlying Git primitive is the same.

---

**Q5: What is the risk of using `post-update` for enforcement instead of `pre-receive`?**

`post-update` runs after the refs have already been updated — the push has already succeeded and cannot be rolled back from within the hook. Any action in `post-update` is additive only: tagging, notifications, triggering builds. `pre-receive` runs before refs are updated and can reject the entire push by exiting non-zero. If you need to enforce a policy — tests must pass, commit message format must match a pattern, no direct pushes to master — you must use `pre-receive` or `update`. Using `post-update` for enforcement is a timing mistake: by the time it runs, the code you wanted to block is already in the repository.

---

**Q6: How do Git hooks fit into a modern CI/CD pipeline — are they still relevant?**

Hooks remain highly relevant, especially for lightweight or self-hosted setups. A `pre-commit` hook running a linter catches issues before they leave the developer's machine — faster feedback than any CI system. A `post-receive` hook deploying to a staging server on every push to a staging branch is simpler and faster than a full pipeline for small teams. Where hooks fall short compared to platforms like GitHub Actions or Jenkins is visibility, parallelism, and shared configuration — hooks are local files and aren't version-controlled in the repo by default. In mature pipelines, hooks and CI systems complement each other: hooks for fast local enforcement, CI for comprehensive testing and deployment orchestration.

---

## 🔗 References

- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
- [Atlassian — Git Hooks](https://www.atlassian.com/git/tutorials/git-hooks)
- [Git — Customizing Git Hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
