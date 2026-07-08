# Day 77 — Jenkins Declarative Pipeline: Deploying a Web App from Gitea to Apache

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** CI/CD / Jenkins / Pipeline / Deployment  
**Difficulty:** Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create a Jenkins pipeline job `datacenter-webapp-job` that:
- Runs on App Server 1 (`stapp01`) via a dedicated agent node
- Pulls the latest code from `sarah/web_app` Gitea repository
- Deploys it to `/var/www/html` (Apache document root on stapp01)
- Pipeline has exactly one stage: `Deploy` (case-sensitive)
- Website is accessible at the root LBR URL (no sub-path)

---

## 🧠 Concept — Jenkins Declarative Pipelines

### Pipeline vs Freestyle Job

```
Freestyle Job:
  - Configured via UI checkboxes and dropdowns
  - Limited flexibility, hard to version control
  - Good for simple tasks

Pipeline Job:
  - Defined as code (Jenkinsfile)
  - Version-controllable in Git
  - Full programmatic control
  - Industry standard for CI/CD
```

### Declarative Pipeline Structure

```groovy
pipeline {
    agent { label 'stapp01' }    // WHERE to run
    stages {
        stage('Deploy') {         // Stage NAME (case-sensitive here!)
            steps {
                sh 'command'      // WHAT to run
            }
        }
    }
}
```

Four key blocks:
- `agent` — which node/agent runs this pipeline
- `stages` — ordered collection of stages
- `stage('Deploy')` — named section (name is case-sensitive per task)
- `steps` — the actual commands to execute

### Why `git pull` Instead of `git clone`

The repository is **already cloned** at `/var/www/html`. `git clone` would fail (directory not empty) or create a subdirectory. `git pull` fetches and merges the latest commits into the existing working tree — the deployment is an update, not a fresh install.

```bash
# WRONG for this task:
git clone http://gitea.../sarah/web_app.git /var/www/html
# Fails: destination path '/var/www/html' already exists

# CORRECT:
cd /var/www/html
git pull
# Updates existing repo with latest commits ✅
```

### Agent Root vs Document Root — Why They're Different

```
/home/sarah/jenkins_agent/    ← Jenkins agent workspace
  workspace/
    datacenter-webapp-job/    ← Jenkins checks out code here during builds

/var/www/html/                ← Apache document root
  index.html                  ← what Apache serves to users
  (already has web_app cloned here)
```

The agent root is Jenkins's working area — isolated from the web server. The build step explicitly `cd`s into `/var/www/html` to operate on the actual deployment location. This separation prevents Jenkins build artifacts from polluting the web root and vice versa.

> **Real-world context:** This pipeline represents the simplest possible CI/CD workflow: code pushed to Gitea → Jenkins job triggered (or manually triggered) → latest code pulled onto the server → website updated. Production pipelines add automated triggers (webhooks from Gitea on push), pre-deployment testing stages, staging environment validation, and rollback capability. But the fundamental `pull latest code → restart service` pattern is exactly what drives many small-to-medium production deployments.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Agent node | `App Server 1` (label: `stapp01`) |
| Agent root | `/home/sarah/jenkins_agent` |
| SSH user | `sarah` / `Sarah_pass123` |
| Document root | `/var/www/html` |
| Apache port | `8080` (LBR → port 80 → stapp01:8080) |
| Job name | `datacenter-webapp-job` |
| Job type | Pipeline (NOT Multibranch) |
| Stage name | `Deploy` |
| Gitea repo | `sarah/web_app` |

---

## 🔧 The Jenkinsfile

```groovy
pipeline {
    agent { label 'stapp01' }
    stages {
        stage('Deploy') {
            steps {
                sh '''
                    cd /var/www/html
                    git pull
                '''
            }
        }
    }
}
```

---

## 🔧 Solution — Step by Step

### Step 1: Get Gitea repository URL

```
Gitea → sarah / Sarah_pass123
Navigate: sarah → web_app
Copy HTTP clone URL
```

### Step 2: Add sarah's credentials in Jenkins

```
Manage Jenkins → Credentials → System → Global credentials → Add Credentials
  Kind: Username with password
  Username: sarah
  Password: Sarah_pass123
  ID: sarah-creds
→ Create
```

### Step 3: Add App Server 1 agent node

```
Manage Jenkins → Nodes → New Node
  Name: App Server 1
  Type: Permanent Agent
  Remote root directory: /home/sarah/jenkins_agent
  Labels: stapp01
  Launch method: SSH
    Host: stapp01
    Credentials: sarah
    Host Key Verification: Non verifying
→ Save → verify Online ✅
```

### Step 4: Create pipeline job

```
New Item → datacenter-webapp-job → Pipeline → OK

Pipeline → Definition: Pipeline script
  [paste Jenkinsfile]
→ Save
```

### Step 5: Build and verify

```
Build Now → Console Output → SUCCESS ✅
Click App button → website loads at root URL ✅
```

---

## ⚠️ Common Mistakes to Avoid

1. **Creating Multibranch Pipeline instead of Pipeline** — The task explicitly says "it must not be a Multibranch pipeline." Multibranch creates separate jobs per branch; Pipeline is a single job.
2. **Stage name case** — The task says `Deploy` (capital D). A stage named `deploy` or `DEPLOY` is different — check pipeline syntax carefully for case-sensitive requirements.
3. **Using `git clone` instead of `git pull`** — The repo is already at `/var/www/html`. Clone would fail or create a subdirectory. Pull updates the existing clone.
4. **Running in the wrong directory** — Without `cd /var/www/html`, `git pull` would try to pull in Jenkins's workspace directory, not the Apache document root.
5. **Node name vs label** — Node name is `App Server 1` (display name). Label is `stapp01`. The pipeline `agent { label 'stapp01' }` targets by label, not name.
6. **Wrong agent user** — The remote root `/home/sarah/jenkins_agent` requires the SSH user to be `sarah`. Using `tony` (which has `/home/tony`) would cause permission errors creating the agent directory.

---

## 🔍 Pipeline Execution Flow

```
User clicks "Build Now"
        │
        ▼
Jenkins master routes to agent with label 'stapp01'
        │
        ▼ (App Server 1 agent)
Pipeline starts in /home/sarah/jenkins_agent/workspace/datacenter-webapp-job/
        │
        ▼ stage('Deploy')
sh 'cd /var/www/html && git pull'
  → Fetches from origin (Gitea)
  → Merges latest commits
  → Updates /var/www/html file content
        │
        ▼
Apache reads updated files from /var/www/html
        │
        ▼
LBR routes HTTPS requests to Apache:8080
        │
        ▼
User sees updated website at https://<LBR-URL>/ ✅
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between a Jenkins Pipeline job and a Freestyle job?**

A Freestyle job is configured entirely through the Jenkins UI — build steps, triggers, parameters, and post-build actions are set via forms and dropdowns. It's quick to set up but hard to version-control (the configuration lives in Jenkins's XML files, not in your repo) and has limited flexibility for complex workflows. A Pipeline job is defined as code in a `Jenkinsfile` — the build logic lives in your repository, goes through code review, has full Git history, and can express complex workflows (parallel stages, conditional logic, loop constructs, error handling) that Freestyle cannot. Pipeline-as-Code is the modern standard; Freestyle is used for simple one-off automation tasks.

---

**Q2: Why does the pipeline use `agent { label 'stapp01' }` instead of `agent any`?**

`agent any` runs the pipeline on whichever agent is available first — which could be App Server 2 or App Server 3. The deployment step `cd /var/www/html && git pull` must run specifically on App Server 1 because that's where Apache's document root is and where the repository is cloned. `agent { label 'stapp01' }` targets only agents with the `stapp01` label — ensuring the deployment commands execute on the correct server. This label-based routing is fundamental to multi-agent Jenkins environments where different servers have different roles and capabilities.

---

**Q3: What is the difference between `Pipeline script` and `Pipeline script from SCM` in Jenkins?**

`Pipeline script` (used today) embeds the Jenkinsfile directly in the job configuration in Jenkins — the pipeline code lives in Jenkins itself, not in version control. `Pipeline script from SCM` reads the Jenkinsfile from a Git repository — the pipeline code lives alongside the application code in the repo. For production, `Pipeline script from SCM` is strongly preferred: the pipeline definition is version-controlled with the app, pipeline changes go through code review, and you can have branch-specific pipelines. `Pipeline script` is used for simplicity in lab environments or for pipelines that aren't tied to a specific application repository.

---

**Q4: How would you add automated triggering so the pipeline runs on every push to the Gitea repository?**

Two approaches: (1) **Polling** — in the pipeline job configuration, enable "Poll SCM" with a cron expression like `* * * * *` (every minute). Jenkins periodically checks the Gitea repository for new commits and triggers a build if found. Simple but not instant (up to 1-minute delay) and creates unnecessary Gitea API calls. (2) **Webhook** — in Gitea, add a webhook pointing to `http://jenkins:8080/gitea-webhook/post` (using the Gitea plugin in Jenkins). When code is pushed to Gitea, Gitea immediately POSTs to Jenkins, triggering the build within seconds. Webhooks are the production standard — instant triggers, no polling overhead.

---

**Q5: How would you add a rollback stage to this pipeline?**

```groovy
pipeline {
    agent { label 'stapp01' }
    stages {
        stage('Deploy') {
            steps {
                sh '''
                    cd /var/www/html
                    git pull
                '''
            }
        }
    }
    post {
        failure {
            sh '''
                cd /var/www/html
                git reset --hard HEAD~1
            '''
        }
    }
}
```

The `post { failure { ... } }` block runs only when the pipeline fails — here it rolls back the git working tree to the previous commit. More sophisticated rollback uses `git stash`, blue-green deployment (swap symlinks between two deployment directories), or Kubernetes rollout undo for containerized applications.

---

**Q6: What is the difference between a Pipeline job and a Multibranch Pipeline?**

A Pipeline job is a single job associated with one branch (or runs a static Jenkinsfile regardless of branches). A Multibranch Pipeline automatically discovers all branches and PRs in a repository and creates a separate Jenkins job for each one — `main` gets a job, `feature/login` gets a job, each PR gets a job. This enables branch-specific pipelines and PR validation workflows. The task explicitly requires a regular Pipeline (not Multibranch) because we want a single deployment job targeting one specific deployment, not per-branch jobs.

---

## 🔗 References

- [Jenkins Declarative Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Pipeline vs Freestyle](https://www.jenkins.io/doc/book/pipeline/getting-started/)
- [Using Jenkins Agents](https://www.jenkins.io/doc/book/using/using-agents/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
