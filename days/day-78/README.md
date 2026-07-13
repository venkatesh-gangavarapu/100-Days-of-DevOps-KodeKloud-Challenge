# Day 78 — Jenkins Parameterized Pipeline: Conditional Branch Deployment

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** CI/CD / Jenkins / Pipeline / Parameterized Deployment  
**Difficulty:** Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create a Jenkins pipeline job `nautilus-webapp-job` with:
- String parameter `BRANCH`
- Single stage `Deploy` (case-sensitive)
- Conditional logic: `master` → deploy master branch, `feature` → deploy feature branch
- Runs on App Server 1 (stapp01 agent), deploys to `/var/www/html`

---

## 🧠 Concept — Parameterized Pipelines with Branch Switching

### Adding Parameters to a Declarative Pipeline

```groovy
pipeline {
    parameters {
        string(name: 'BRANCH', defaultValue: 'master', description: '...')
    }
}
```

Parameters declared in the `parameters {}` block appear in **"Build with Parameters"** when the job is triggered. The value is accessed as `${params.BRANCH}` (Groovy) or `$BRANCH` (shell).

### The Conditional Deployment Logic

The task says: "if master is passed → deploy master, if feature is passed → deploy feature."

The simplest implementation uses the parameter directly in `git checkout`:

```bash
cd /var/www/html
git checkout ${params.BRANCH}    # switches to the specified branch
git pull origin ${params.BRANCH} # pulls latest from that branch
```

This is naturally conditional — the parameter value determines which branch is checked out and pulled.

### `git checkout` + `git pull` vs `git pull` alone

```
git pull (alone):
  Pulls latest from the CURRENT branch only
  If already on master, pulling doesn't switch to feature

git checkout $BRANCH + git pull origin $BRANCH:
  Step 1: Switch to the specified branch
  Step 2: Pull latest from that branch on origin
  Handles both branch switching AND updating ✅
```

### First Build Behavior — Parameters Not Shown Until Second Build

A quirk of Jenkins parameterized pipelines: the first build after creating the job **won't show "Build with Parameters"** — it shows "Build Now" instead and runs with default values. After the first build, Jenkins discovers the parameters from the pipeline script and subsequent builds show the parameter input form. This is expected behavior — just run Build Now first, then subsequent builds will show "Build with Parameters."

> **Real-world context:** Parameterized branch deployment is a core CI/CD pattern. Development teams push to `feature` branches, Jenkins deploys to a staging environment with `BRANCH=feature`. After review, the branch is merged to `master`, and `BRANCH=master` deploys to production. One pipeline, multiple environments, controlled by a single parameter. This avoids maintaining separate pipeline configurations per branch.

---

## 🔧 The Jenkinsfile

```groovy
pipeline {
    agent { label 'stapp01' }
    parameters {
        string(
            name: 'BRANCH',
            defaultValue: 'master',
            description: 'Branch to deploy: master or feature'
        )
    }
    stages {
        stage('Deploy') {
            steps {
                sh """
                    cd /var/www/html
                    git checkout ${params.BRANCH}
                    git pull origin ${params.BRANCH}
                """
            }
        }
    }
}
```

---

## 🔧 Solution — Step by Step

### Pre-work: Fix agent if offline

```bash
# From jump host
ssh tony@stapp01       # Password: Ir0nM@n

# Install Java (required for Jenkins agent)
sudo yum install -y java-11-openjdk

# Ensure sarah user and agent directory exist
sudo useradd sarah 2>/dev/null || true
sudo mkdir -p /home/sarah/jenkins_agent
sudo chown -R sarah:sarah /home/sarah/jenkins_agent

# Back in Jenkins: Nodes → App Server 1 → Launch agent
```

### Create and configure the job

```
New Item → nautilus-webapp-job → Pipeline → OK

Pipeline → Definition: Pipeline script
  [paste Jenkinsfile]
→ Save
```

### Build with master branch

```
Build Now (first build) → runs with default: BRANCH=master
OR
Build with Parameters → BRANCH: master → Build

Console Output:
  git checkout master → Already on 'master' (or Switched to branch 'master')
  git pull origin master → Already up to date.
  Finished: SUCCESS ✅
```

### Build with feature branch

```
Build with Parameters → BRANCH: feature → Build

Console Output:
  git checkout feature → Switched to branch 'feature'
  git pull origin feature → Already up to date.
  Finished: SUCCESS ✅
```

### Verify website

```
Click App button → https://<LBR-URL>/ loads ✅ (no sub-path)
```

---

## ⚠️ Common Mistakes to Avoid

1. **`${params.BRANCH}` not substituting** — If using single quotes `sh '...'`, Groovy variable interpolation doesn't happen. Use double quotes `sh """..."""` or `sh "..."` so `${params.BRANCH}` expands to the actual value.
2. **"Build Now" instead of "Build with Parameters"** — First build after creating a parameterized pipeline shows "Build Now" (runs with defaults). After it completes, subsequent builds show "Build with Parameters." Expected behavior.
3. **Feature branch doesn't exist** — `git checkout feature` fails if the branch doesn't exist locally or on origin. Verify: `git -C /var/www/html branch -a` on stapp01.
4. **Stage name case** — Must be exactly `Deploy` (capital D). `deploy` or `DEPLOY` are different.
5. **Agent still offline** — Build fails immediately with "App Server 1 is offline." Fix the agent first (Java install, user creation, directory permissions).

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: How do Jenkins pipeline parameters work and when do they first appear?**

Parameters declared in the `parameters {}` block are processed when Jenkins runs the pipeline. On the very first build after creation, Jenkins hasn't read the Jenkinsfile yet and shows "Build Now" (no parameter form). After the first build completes, Jenkins caches the parameter definitions and subsequent builds show "Build with Parameters" with the form. This is a known Jenkins behavior — always run the first build with defaults, then use parameters from the second build onward. In `Pipeline script from SCM` mode (reading Jenkinsfile from Git), the same applies: the first scan builds with defaults.

---

**Q2: What is the difference between `${params.BRANCH}` and `$BRANCH` in a Jenkinsfile?**

`${params.BRANCH}` is Groovy interpolation — Jenkins's native way to reference pipeline parameters in a Declarative Pipeline. It works in `sh """..."""` (double-quoted heredoc, Groovy interprets `${...}` before passing to shell). `$BRANCH` is standard shell variable syntax — it works when Jenkins exports the parameter as an environment variable to the shell step. Both work in practice for simple string parameters, but `${params.BRANCH}` is more explicit and avoids potential conflicts with shell variables of the same name. If using single-quoted `sh '...'`, neither works — single quotes prevent Groovy interpolation.

---

**Q3: How would you add a validation step to reject invalid BRANCH values?**

```groovy
stage('Deploy') {
    steps {
        script {
            if (params.BRANCH != 'master' && params.BRANCH != 'feature') {
                error("Invalid BRANCH value: '${params.BRANCH}'. Must be 'master' or 'feature'.")
            }
        }
        sh """
            cd /var/www/html
            git checkout ${params.BRANCH}
            git pull origin ${params.BRANCH}
        """
    }
}
```

Or use a Choice Parameter instead of String Parameter — limits input to predefined values at the UI level, no validation code needed. `choice(name: 'BRANCH', choices: ['master', 'feature'], description: '...')` — the user selects from a dropdown instead of typing freely.

---

**Q4: How would you extend this pipeline to deploy different servers based on the branch?**

```groovy
pipeline {
    agent none
    parameters {
        string(name: 'BRANCH', defaultValue: 'master', ...)
    }
    stages {
        stage('Deploy') {
            agent {
                label params.BRANCH == 'master' ? 'production' : 'staging'
            }
            steps {
                sh """
                    cd /var/www/html
                    git checkout ${params.BRANCH}
                    git pull origin ${params.BRANCH}
                """
            }
        }
    }
}
```

This routes master branch deployments to the `production` labeled agent and feature branch to `staging`. The conditional agent selection is a Groovy ternary expression in the `agent` block. Combined with Day 75's labeled nodes, this pattern enables environment-aware routing entirely through pipeline code.

---

**Q5: What is the difference between a `String` parameter and a `Choice` parameter for branch selection?**

A String parameter is free text — the user types any value. This is flexible but risky: a typo like "mastr" would cause `git checkout mastr` to fail at runtime. A Choice parameter is a dropdown — the user selects from predefined options, preventing invalid input entirely. For branch selection where only specific branches are valid, Choice is safer: the error is caught at parameter selection time, not during build execution. String parameters are better when the set of valid values is dynamic or not known at job creation time (e.g., any arbitrary branch name the developer wants to build).

---

**Q6: How would you trigger this pipeline automatically when code is pushed to either branch?**

Configure a Gitea webhook: in Gitea's repository settings, add a webhook pointing to Jenkins (`http://jenkins:8080/gitea-webhook/post` with the Gitea plugin installed). The webhook fires on every push. In Jenkins, configure the pipeline trigger to receive the webhook and extract the branch name from the payload. The pipeline is then triggered automatically with `BRANCH=master` or `BRANCH=feature` depending on which branch was pushed to — no manual "Build with Parameters" needed. This closes the CI/CD loop: push code → webhook fires → Jenkins deploys the correct branch → website updated automatically.

---

## 🔗 References

- [Declarative Pipeline Parameters](https://www.jenkins.io/doc/book/pipeline/syntax/#parameters)
- [Pipeline Syntax — sh step](https://www.jenkins.io/doc/pipeline/steps/workflow-durable-task-step/#sh-shell-script)
- [Gitea Plugin for Jenkins](https://plugins.jenkins.io/gitea/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
