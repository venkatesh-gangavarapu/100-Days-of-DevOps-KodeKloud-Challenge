# Day 80 — Jenkins Chained Builds: Upstream/Downstream Job Pattern

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** CI/CD / Jenkins / Chained Builds / Pipeline Orchestration  
**Difficulty:** Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

Configure Jenkins chained builds:

| Job | Type | Role | Action |
|-----|------|------|--------|
| `nautilus-app-deployment` | Upstream | Deployment | `git pull` in `/var/www/html` |
| `manage-services` | Downstream | Service management | `systemctl restart httpd` |

**Chain rule:** `manage-services` triggers only when `nautilus-app-deployment` is **stable** (SUCCESS).

---

## 🧠 Concept — Jenkins Upstream/Downstream Jobs

### What is a Chained Build?

Jenkins allows jobs to trigger other jobs — creating a build pipeline without writing a single line of Groovy. The upstream job runs first; if it meets the condition (stable/success), it triggers the downstream job.

```
nautilus-app-deployment (upstream)
  │
  │ Post-build: "Build other projects"
  │ Condition: "Trigger only if build is stable"
  │
  ▼ (only triggered on SUCCESS)
manage-services (downstream)
  │
  │ Build Trigger: "Build after other projects are built"
  │ Condition: "Trigger only if build is stable"
  │
  ▼
httpd restarted ✅
```

### Why Separate Jobs?

Separation of concerns — deployment and service management are distinct responsibilities:

```
nautilus-app-deployment: "What code is running?"
  → Pulls latest code, manages document root

manage-services: "Are services running correctly?"
  → Restarts/reloads services after deployment

If deployment fails → services NOT restarted (correct behavior)
If deployment succeeds → services restarted (ensures clean state)
```

### Two Ways to Configure the Chain

**Option A — Post-build action on upstream (used today):**
```
nautilus-app-deployment → Post-build Actions
  → Build other projects → manage-services
  → Trigger only if build is stable
```

**Option B — Build trigger on downstream:**
```
manage-services → Build Triggers
  → Build after other projects are built
  → nautilus-app-deployment is STABLE
```

Both achieve the same result. **Configuring both** (as done today) makes the dependency explicit in both job configurations — easier to understand during audits.

### `git reset --hard` vs `git pull`

```bash
# git pull: merges — can fail on conflicts
git pull origin master

# git reset --hard: forces working tree to match origin — no conflicts possible
git fetch origin master
git reset --hard origin/master
```

`git reset --hard` is more reliable for deployment scenarios — it never fails due to local changes or merge conflicts, always produces a clean working tree matching the remote.

> **Real-world context:** The chained build pattern (sometimes called "build pipeline" in Jenkins) is how organizations structure multi-stage deployment workflows without writing full Pipeline code. Deploy job succeeds → integration test job triggers → if tests pass → service restart job triggers → if service healthy → notification job triggers. Each stage is a separate, independently runnable job that can also be triggered manually when needed.

---

## 🔧 Complete Solution

### Pre-work on stapp01

```bash
ssh tony@stapp01   # Ir0nM@n

# Verify /var/www/html is the git repo
git -C /var/www/html remote -v
# Expected: origin → http://gitea:3000/sarah/web.git

# Verify sarah sudoers
sudo -u sarah sudo -n whoami   # must output: root

# Ensure ownership and httpd running
sudo chown -R sarah:sarah /var/www/html
sudo systemctl start httpd
```

### Job 1: nautilus-app-deployment (Freestyle)

```
New Item → nautilus-app-deployment → Freestyle project → OK

General:
  ☑ Restrict where this project can be run
  Label Expression: stapp01

Build Steps → Execute shell:
  cd /var/www/html
  sudo git fetch origin master
  sudo git reset --hard origin/master
  sudo chown -R sarah:sarah /var/www/html

Post-build Actions → Build other projects:
  Projects to build: manage-services
  ● Trigger only if build is stable
→ Save
```

### Job 2: manage-services (Freestyle)

```
New Item → manage-services → Freestyle project → OK

General:
  ☑ Restrict where this project can be run
  Label Expression: stapp01

Build Triggers:
  ☑ Build after other projects are built
  Projects to watch: nautilus-app-deployment
  ● Trigger only if build is stable

Build Steps → Execute shell:
  sudo systemctl restart httpd
  echo "httpd restarted successfully"
  sudo systemctl status httpd | grep Active
→ Save
```

### Test

```
Jenkins → nautilus-app-deployment → Build Now

Sequence:
  nautilus-app-deployment → SUCCESS ✅
       ↓ auto-triggers
  manage-services → SUCCESS ✅

App button → content loads at root URL ✅
```

---

## ⚠️ Common Mistakes to Avoid

1. **"Trigger only if build is stable" vs "Trigger even if unstable"** — Must select "stable" (green). "Unstable" (yellow) means tests passed with warnings. "Failed" (red) means do not trigger at all.
2. **Not restricting agent in both jobs** — Both jobs must specify `stapp01` as the agent. If `manage-services` runs on master (built-in) node, `systemctl restart httpd` targets the wrong server.
3. **`git pull` failing on conflicts** — Use `git reset --hard origin/master` instead. This forces the working tree to match remote regardless of local state, making builds idempotent.
4. **Forgetting "Build after other projects" in manage-services** — The chain is configured in both directions for clarity: upstream has "Build other projects" and downstream has "Build after other projects." Without the downstream trigger, the chain only works if configured on the upstream side.
5. **httpd restart before git pull completes** — Chained builds run sequentially: `nautilus-app-deployment` fully completes (including all post-build actions verifying the result) before `manage-services` starts. This guarantees httpd is restarted only after code is fully deployed.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between "stable," "successful," and "unstable" in Jenkins build conditions?**

In Jenkins, "successful" (green) means the build completed with exit code 0 and all configured quality gates passed. "Unstable" (yellow) means the build ran but something didn't fully pass — typically test failures when using test result publishers (the build script itself exited 0 but test reports showed failures). "Failed" (red) means the build script exited non-zero. "Stable" in downstream trigger context means "successful" — no test failures, no script errors. Choosing "Trigger only if build is stable" ensures the downstream job (httpd restart) only runs when the upstream deployment was completely clean, not just "it ran but had warnings."

---

**Q2: What is the difference between configuring downstream in the upstream job vs upstream in the downstream job?**

Both achieve the same triggering behavior but from different perspectives. Configuring "Build other projects" in `nautilus-app-deployment` is an outgoing dependency — the upstream declares what it triggers. Configuring "Build after other projects" in `manage-services` is an incoming dependency — the downstream declares what triggers it. Best practice: configure both for clarity and self-documentation. During troubleshooting, checking a job's configuration shows all its dependencies and dependents in one place. Some organizations choose one canonical approach (either all-upstream or all-downstream declarations) for consistency.

---

**Q3: How does Jenkins determine "stable" vs "unstable" for the chained build condition?**

Jenkins evaluates build stability based on: (1) Exit code of the last shell/batch command in the build — non-zero exit code = failed. (2) Test result publishers — if JUnit XML results show test failures, the build is marked unstable even if the script exited 0. (3) Build wrappers and plugins — some plugins can mark builds unstable based on coverage thresholds, code quality metrics, etc. For our shell-based jobs, "stable" simply means the shell script exited 0. The `sudo systemctl restart httpd || true` pattern from Day 79 is an example of forcing exit 0 regardless of the underlying command result — sometimes useful, sometimes masking real failures.

---

**Q4: How would you extend this chain to add a health check between deployment and service restart?**

Add a third job:

```
nautilus-app-deployment → manage-services → health-check

health-check (Execute shell):
  sleep 5  # give httpd time to fully restart
  curl -f http://localhost:8080/ || exit 1
  echo "Health check passed ✅"
```

`manage-services` would have a post-build action triggering `health-check`. If the health check fails (curl returns non-zero because the page didn't load), the chain stops and the team is notified. This three-stage chain (deploy → restart → verify) is a complete zero-downtime deployment workflow for simple static sites.

---

**Q5: What is the Jenkins "Build Pipeline" plugin and how does it improve chained builds?**

The Build Pipeline plugin provides a visual visualization of chained builds — showing upstream and downstream jobs as connected boxes with color coding (green/red/yellow) in a pipeline view. Without it, you navigate each job separately to see its build history. With it, a single view shows the entire chain: deploy triggered at 14:23 (green) → service restart triggered at 14:24 (green) → health check at 14:25 (green). This makes it immediately obvious when the chain breaks — if service restart shows red while deployment shows green, the httpd issue is isolated. The modern alternative is the Blue Ocean plugin which provides similar visualization with a more modern UI.

---

**Q6: What are the limitations of chained freestyle jobs compared to a single Pipeline job?**

Chained freestyle jobs have several limitations: (1) No single view of the entire deployment — each job has its own console output and build history. (2) Parameters must be explicitly passed between jobs using the "Parameterized Trigger" plugin — they don't automatically flow downstream. (3) Rollback requires knowing which build numbers to revert. (4) No conditional branching — you can't say "if deploy job succeeded AND staging tests pass, deploy to production; else notify only." (5) Harder version control — job configuration lives in Jenkins XML, not in Git. A single Declarative Pipeline with `post { success { build 'manage-services' } }` and parallel stages handles all these cases more elegantly. Chained freestyle jobs are appropriate when teams aren't comfortable with Groovy or when jobs need to be manually triggerable independently.

---

## 🔗 References

- [Jenkins Upstream/Downstream](https://www.jenkins.io/doc/book/using/using-agents/)
- [Build Pipeline Plugin](https://plugins.jenkins.io/build-pipeline-plugin/)
- [Jenkins Post-Build Actions](https://www.jenkins.io/doc/pipeline/steps/core/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
