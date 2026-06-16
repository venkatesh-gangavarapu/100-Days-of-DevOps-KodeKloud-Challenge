# Day 69 — Jenkins Plugin Installation: Git & GitLab

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** CI/CD / Jenkins / Plugin Management  
**Difficulty:** Beginner  
**Phase:** Phase 5 — Advanced Kubernetes & CI/CD  
**Status:** ✅ Completed

---

## 📋 Task Summary

Log into Jenkins UI and install two essential plugins:
- **Git** plugin
- **GitLab** plugin

Restart Jenkins to complete installation, then verify both plugins are active.

---

## 🧠 Concept — Jenkins Plugin Architecture

### Why Plugins Matter

Jenkins core is intentionally minimal — almost all functionality beyond basic job scheduling comes from plugins. There are 1800+ plugins in the Jenkins ecosystem covering SCM integration, build tools, notification systems, cloud providers, and more.

```
Jenkins Core
  ├── Job scheduler
  ├── Build queue
  └── Plugin system
        ├── Git plugin       ← clone/checkout from Git repos
        ├── GitLab plugin    ← GitLab webhook triggers, MR status
        ├── Pipeline plugin  ← Jenkinsfile support
        ├── Docker plugin    ← build/push Docker images
        └── ... 1800+ more
```

### Git Plugin vs GitLab Plugin

| Plugin | Purpose |
|--------|---------|
| **Git** | Core SCM integration — clone repos, checkout branches, poll for changes. Works with GitHub, GitLab, Bitbucket, any Git server. |
| **GitLab** | GitLab-specific integration — webhook triggers on push/MR events, build status reporting back to GitLab, merge request pipeline triggers. |

The Git plugin is the foundation — almost every Jenkins job that builds from source code needs it. The GitLab plugin adds GitLab-specific features on top: triggering builds from GitLab webhooks and posting pipeline status back to GitLab merge requests.

### Plugin Installation Workflow

```
Manage Jenkins → Plugins → Available plugins
        │
        ├── Search "Git" → check checkbox
        ├── Search "GitLab" → check checkbox
        │
        ▼
   Click Install
        │
        ▼
Installation progress page
        │
        ├── Option: "Restart Jenkins when installation
        │            is complete and no jobs are running"
        │
        ▼
Jenkins restarts (if checked) → core reloads with new plugins active
        │
        ▼
Login page reappears → log back in → plugins active ✅
```

### Why Restart is Sometimes Required

Some plugins modify Jenkins core behavior (new job types, new UI elements, security model changes) and require a full JVM restart to load correctly. Other plugins can be installed "hot" without restart. Jenkins determines this automatically and shows the restart option only when needed.

> **Real-world context:** Git and GitLab plugins are foundational for any Jenkins setup integrating with GitLab-hosted repositories — extremely common in enterprises using GitLab as their primary Git platform. Installing the right plugin set before creating jobs is standard practice; doing it ad-hoc per-job leads to inconsistent environments across a team.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Access | Jenkins UI (top bar button) |
| Username | `admin` |
| Password | `Adm!n321` |
| Plugins to install | Git, GitLab |

---

## 🔧 Solution — Step by Step

### Step 1: Access Jenkins UI and log in

Click the **Jenkins** button on the top bar.
- Username: `admin`
- Password: `Adm!n321`

### Step 2: Navigate to Plugin Manager

```
Dashboard → Manage Jenkins → Plugins
```

### Step 3: Go to "Available plugins"

Click **Available plugins** in the left sidebar.

### Step 4: Search and select Git plugin

Type `Git` in the search box. Check the checkbox next to **Git plugin**.

### Step 5: Search and select GitLab plugin

Clear the search, type `GitLab`. Check the checkbox next to **GitLab Plugin**.

### Step 6: Install

Click **Install** at the bottom of the page.

### Step 7: Restart Jenkins if prompted

On the installation progress page, check:
> ☑ Restart Jenkins when installation is complete and no jobs are running

### Step 8: Wait for Jenkins to restart

The page shows "Jenkins is restarting" — wait until the **login page reappears** (30-90 seconds typically).

### Step 9: Log back in and verify plugins

```
Manage Jenkins → Plugins → Installed plugins
```

Search `Git` and `GitLab` — both should be listed as installed and enabled. ✅

---

## 📌 Verification Checklist

```
☑ Logged into Jenkins UI with admin/Adm!n321
☑ Navigated to Manage Jenkins → Plugins → Available
☑ Searched and checked "Git" plugin
☑ Searched and checked "GitLab" plugin
☑ Clicked Install
☑ Checked "Restart Jenkins when installation is complete"
☑ Waited for login page to reappear after restart
☑ Logged back in successfully
☑ Verified both plugins in Installed plugins list
```

---

## ⚠️ Common Mistakes to Avoid

1. **Not waiting for full restart** — Refreshing the browser too early during Jenkins restart can show misleading errors. Always wait for the login page to fully reappear.
2. **Confusing Git and GitHub plugins** — "Git plugin" (SCM core) and "GitHub plugin" (GitHub-specific webhooks) are different. This task specifically requires Git and GitLab plugins.
3. **Forgetting to restart when prompted** — Some plugin features won't activate until restart. If the option is offered, take it rather than skipping.
4. **Not verifying installation** — Always check "Installed plugins" after restart to confirm — installation can occasionally fail silently if dependencies conflict.
5. **Navigating away during installation** — Let the install progress bar complete fully before navigating to another page.

---

## 🔍 Plugin Manager Navigation (Jenkins 2.x+)

```
Dashboard
  └── Manage Jenkins
        └── Plugins
              ├── Updates          (pending plugin updates)
              ├── Available plugins (browse/install new plugins)
              ├── Installed plugins (currently active plugins)
              └── Advanced settings (proxy, plugin upload)
```

Older Jenkins versions used "Manage Plugins" with tabs (Updates / Available / Installed / Advanced) instead of separate sidebar links — same functionality, different UI layout.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between the Git plugin and the GitLab plugin in Jenkins?**

The Git plugin provides core SCM (Source Control Management) functionality — cloning repositories, checking out specific branches or commits, and polling for changes. It works with any Git server (GitHub, GitLab, Bitbucket, self-hosted Git). The GitLab plugin adds GitLab-specific integration on top: receiving webhook triggers when code is pushed or merge requests are created in GitLab, and reporting build/pipeline status back to GitLab's merge request UI (showing green checkmarks or red X's on MRs). You need the Git plugin for basic source checkout regardless of which Git host you use; you need the GitLab plugin specifically for GitLab webhook integration and status reporting.

---

**Q2: Why does installing some Jenkins plugins require a restart while others don't?**

Plugins that only add new build steps, post-build actions, or simple UI elements can typically be loaded dynamically without restart — Jenkins's plugin manager hot-loads the new classes. Plugins that modify core security behavior, introduce new job types, change the authentication system, or have complex class-loading dependencies require a full JVM restart to ensure consistent state. Jenkins's installer automatically detects which category a plugin falls into and only prompts for restart when genuinely necessary, avoiding unnecessary downtime for simple plugin installs.

---

**Q3: What happens to running jobs if you restart Jenkins during a build?**

If you select "Restart Jenkins when installation is complete and no jobs are running," Jenkins waits until all currently running builds finish before restarting — this prevents interrupting active build processes. If you force an immediate restart (via `Manage Jenkins → Restart Jenkins` without the "no jobs running" condition), any in-progress builds are abruptly terminated, potentially leaving build artifacts in an inconsistent state or failing to report results back to the triggering system (GitLab MR, GitHub PR). Production Jenkins administrators always prefer the graceful "wait for jobs to finish" restart option.

---

**Q4: How would you install Jenkins plugins via CLI/automation instead of the UI for reproducible setups?**

Jenkins provides several non-UI approaches: (1) **Jenkins CLI** — `java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin git gitlab-plugin`. (2) **plugins.txt with Docker** — the official Jenkins Docker image supports a `plugins.txt` file listing required plugins (`git:latest`, `gitlab-plugin:latest`), installed automatically via `jenkins-plugin-cli` on container startup. (3) **Configuration as Code (JCasC)** — combined with Job DSL or Configuration as Code plugin, the entire Jenkins setup including plugins can be defined in YAML and applied automatically. For reproducible Jenkins environments (especially containerized), the Docker `plugins.txt` approach is standard — it ensures every Jenkins instance has identical plugins without manual UI clicking.

---

**Q5: What security considerations apply to installing third-party Jenkins plugins?**

Jenkins plugins run with the same privileges as the Jenkins process itself — a malicious or vulnerable plugin can compromise the entire Jenkins instance, including access to stored credentials, source code, and deployment targets. Best practices: only install plugins from the official Jenkins Update Center (which includes basic vetting), check plugin popularity and maintenance status (last updated date, open security advisories) before installing, regularly update plugins to patch known CVEs (Jenkins publishes a security advisory list), and use the "Plugin Usage" feature to remove plugins that aren't actively used — reducing attack surface. The Git and GitLab plugins installed here are both extremely popular, actively maintained, and considered safe/standard for any Jenkins setup.

---

**Q6: How does the GitLab plugin enable webhook-triggered builds?**

After installing the GitLab plugin, you configure a GitLab Connection in Jenkins (Manage Jenkins → System → GitLab) pointing to your GitLab server with an API token. Then, in a specific job's configuration, you enable "Build when a change is pushed to GitLab" and configure trigger conditions (push events, merge request events, comments). Jenkins generates a webhook URL. You add this URL to the GitLab repository's webhook settings. When a developer pushes code or opens a merge request, GitLab sends an HTTP POST to Jenkins's webhook endpoint, which triggers the configured job automatically — no polling required, builds start within seconds of the push.

---

## 🔗 References

- [Jenkins Plugin Index](https://plugins.jenkins.io/)
- [Git Plugin](https://plugins.jenkins.io/git/)
- [GitLab Plugin](https://plugins.jenkins.io/gitlab-plugin/)
- [Jenkins Configuration as Code](https://www.jenkins.io/projects/jcasc/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
