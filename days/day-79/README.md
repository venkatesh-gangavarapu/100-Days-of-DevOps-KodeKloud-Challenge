# Day 79 — Jenkins Auto-Deployment: Webhook + Poll SCM Triggered CI/CD

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** CI/CD / Jenkins / Webhooks / Auto-Deployment  
**Difficulty:** Advanced  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create Jenkins job `xfusion-app-deployment` that:
- Auto-triggers when code is pushed to `sarah/web` master branch in Gitea
- Pulls latest code from `/home/sarah/web` on stapp01
- Deploys entire repo to `/var/www/html` (Apache document root)
- Accessible at root LBR URL — no sub-path

**index.html content:** `Welcome to the xFusionCorp Industries`

---

## 🧠 Concept — Auto-Deploy Architecture

```
sarah: git push origin master
         │
         ▼ (Poll SCM detects commit within 60s)
Jenkins: xfusion-app-deployment triggers
         │ runs on stapp01 agent (label: stapp01)
         ▼
git pull → sudo chown /var/www/html → sudo cp → httpd start
         │
         ▼
Apache:8080 → LBR → App button ✅
```

### Dual Trigger Strategy

This task uses **both** Poll SCM and Gitea webhook:

| Trigger | How it works | Reliability |
|---------|-------------|-------------|
| Poll SCM `* * * * *` | Jenkins checks git every minute | 100% — no external config needed |
| Gitea webhook | Gitea POSTs to Jenkins on push | Instant — but requires ALLOWED_HOST_LIST fix |

**Poll SCM alone is sufficient for validation** — the build IS triggered by the push, Jenkins just detects it by polling rather than real-time notification.

### Gitea ALLOWED_HOST_LIST Issue

KodeKloud's Gitea is configured with a whitelist that blocks outbound webhooks to internal IPs:
```
webhook can only call allowed HTTP servers
(check your webhook.ALLOWED_HOST_LIST setting)
```

**Fix:** Edit `/etc/gitea/app.ini` on the Jenkins/Gitea server:
```ini
[webhook]
ALLOWED_HOST_LIST = *
```
Then restart Gitea. After this, the webhook URL `http://jenkins:8080/gitea-webhook/post` works.

### Why `cp -rp` Not `rsync`

rsync is not installed by default on KodeKloud stapp01:
```
sudo: rsync: command not found
```

`sudo cp -rp /home/sarah/web/. /var/www/html/` achieves the same result:
- `-r` recursive (entire directory tree)
- `-p` preserves permissions and timestamps
- `.` source suffix copies hidden files too

### Sudo Configuration — The Critical Detail

Jenkins pipeline runs as `sarah` (the agent SSH user). `sudo` commands require NOPASSWD in sudoers — **not** just adding sarah to the sudo group.

**Correct method:**
```bash
sudo bash -c 'echo "sarah ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sarah'
sudo chmod 440 /etc/sudoers.d/sarah
```

Verify before running the pipeline:
```bash
sudo -u sarah sudo -n whoami
# Must output: root
```

If this shows a password prompt, the sudoers file didn't apply correctly.

---

## 🔧 Complete Solution

### Pre-work on stapp01

```bash
ssh tony@stapp01   # Ir0nM@n

# Passwordless sudo for sarah
sudo bash -c 'echo "sarah ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sarah'
sudo chmod 440 /etc/sudoers.d/sarah
sudo -u sarah sudo -n whoami   # verify: root

# Set /var/www/html ownership
sudo chown -R sarah:sarah /var/www/html

# Start httpd
sudo systemctl start httpd && sudo systemctl enable httpd

# Install Java
sudo yum install -y java-11-openjdk

# Create agent directory
sudo -u sarah mkdir -p /home/sarah/jenkins_agent
```

### Jenkins Setup

```
Plugins: Gitea, Workflow Aggregator, Git → Install → Restart

Credentials: sarah / Sarah_pass123 → ID: sarah-creds

Node: App Server 1
  Remote root: /home/sarah/jenkins_agent
  Label: stapp01
  SSH: stapp01, sarah-creds, Non verifying
```

### The Jenkinsfile

```groovy
pipeline {
    agent { label 'stapp01' }
    stages {
        stage('Deploy') {
            steps {
                sh '''
                    cd /home/sarah/web
                    git pull origin master
                    sudo chown -R sarah:sarah /var/www/html
                    sudo cp -rp /home/sarah/web/. /var/www/html/
                    sudo systemctl start httpd || true
                '''
            }
        }
    }
}
```

### Job Configuration

```
Name: xfusion-app-deployment
Type: Pipeline

Build Triggers:
  ☑ Poll SCM → * * * * *
  ☑ Build when a change is pushed to Gitea

Pipeline: Pipeline script (paste Jenkinsfile)
→ Save → Build Now → SUCCESS ✅
```

### Fix Gitea ALLOWED_HOST_LIST (for webhook)

```bash
ssh root@jenkins   # S3curePass
find / -name "app.ini" 2>/dev/null
vi /etc/gitea/app.ini
```
Add:
```ini
[webhook]
ALLOWED_HOST_LIST = *
```
```bash
systemctl restart gitea
```

### Gitea Webhook

```
sarah/web → Settings → Webhooks → Add Webhook → Gitea
  Target URL: http://jenkins:8080/gitea-webhook/post
  Content Type: application/json
  Trigger: Push Events
→ Test Delivery → 200 ✅
```

### Push the Code

```bash
ssh sarah@stapp01   # Sarah_pass123
cd /home/sarah/web
echo "Welcome to the xFusionCorp Industries" > index.html
git config user.email "sarah@stratos.xfusioncorp.com"
git config user.name "sarah"
git add .
git commit -m "Deploy: Welcome to xFusionCorp Industries"
git push origin master
# → Jenkins auto-triggers → SUCCESS ✅
```

---

## 🔍 Troubleshooting Reference

| Error | Cause | Fix |
|-------|-------|-----|
| `rsync: command not found` | rsync not installed | Use `cp -rp` instead |
| `sudo: a password is required` | sudoers not configured | `bash -c 'echo ... > /etc/sudoers.d/sarah'` + `chmod 440` |
| Webhook EOF / response 0 | Using external lab URL | Use internal `http://jenkins:8080/...` |
| `ALLOWED_HOST_LIST deny` | Gitea whitelist | Edit `app.ini` → `ALLOWED_HOST_LIST = *` |
| Build not auto-triggering | Webhook failing | Poll SCM `* * * * *` as fallback |

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is Poll SCM and how does it differ from a webhook trigger?**

Poll SCM makes Jenkins periodically query the Git repository for new commits — like a cron job that checks for changes. With `* * * * *`, Jenkins checks every minute. If it finds commits newer than the last build, it triggers a build. A webhook is the opposite: the Git server (Gitea/GitHub) notifies Jenkins the instant a push happens. Webhooks are faster (seconds vs up to a minute) and more efficient (no polling overhead). Poll SCM is more reliable in restricted environments where the Git server can't reach Jenkins due to firewall or network restrictions — which is exactly what happened in this task with the `ALLOWED_HOST_LIST` restriction.

---

**Q2: What is the Gitea `ALLOWED_HOST_LIST` setting and why does it exist?**

Gitea's `ALLOWED_HOST_LIST` is a security feature that prevents Server-Side Request Forgery (SSRF) attacks via webhooks. Without it, an attacker could configure a Gitea webhook pointing to internal services (databases, cloud metadata endpoints, internal APIs) and use Gitea as a proxy to send requests to otherwise inaccessible services. The whitelist restricts which hosts Gitea can send webhook requests to. In KodeKloud labs, setting `ALLOWED_HOST_LIST = *` removes the restriction entirely — acceptable for a controlled lab environment but a security risk in production. Production systems should whitelist only the specific Jenkins IP/hostname.

---

**Q3: Why use `cp -rp /home/sarah/web/. /var/www/html/` with a trailing dot?**

The trailing `.` on the source path (`/home/sarah/web/.`) is crucial — it copies the directory's contents including hidden files (files starting with `.`, like `.gitignore`, `.htaccess`) into the destination. Without the dot, `cp -rp /home/sarah/web/ /var/www/html/` would create `/var/www/html/web/` (a subdirectory) rather than placing files directly in `/var/www/html/`. The dot notation says "copy everything inside this directory to the destination" rather than "copy this directory into the destination." This ensures content is served from the root URL, not a `/web` subdirectory.

---

**Q4: How do you make Jenkins pipeline sudo commands work without a terminal?**

Jenkins pipelines run in a non-interactive shell — there's no terminal to display a password prompt. Any `sudo` command that requires a password will fail with "sudo: a terminal is required to read the password." The solution is passwordless sudo via the NOPASSWD directive in sudoers: `username ALL=(ALL) NOPASSWD: ALL` or scoped to specific commands: `username ALL=(ALL) NOPASSWD: /bin/cp, /bin/chown, /usr/bin/systemctl`. The file must be placed in `/etc/sudoers.d/` with `chmod 440` permissions. Always verify with `sudo -u username sudo -n whoami` before running the pipeline — if it prompts for a password, the configuration isn't applied correctly.

---

**Q5: What does `sudo systemctl start httpd || true` accomplish?**

`systemctl start httpd` starts Apache if it's not running and exits with code 0. On some systems, running it on an already-running service returns exit code 1 (service already running). In a shell script, any non-zero exit code causes the entire script to abort — the pipeline would fail even though Apache was already serving content correctly. `|| true` intercepts that non-zero exit and substitutes exit code 0, allowing the pipeline to continue. This makes the step idempotent: whether Apache was stopped, running, or failed, the pipeline always continues after this step without error.

---

**Q6: How would you improve this pipeline for production use?**

Several enhancements: (1) Add a test stage before deploy — validate HTML, check file integrity, run smoke tests. (2) Implement proper rollback — keep the previous deployment in a backup directory and restore if the new deployment fails health checks. (3) Use atomic deployment — `rsync` to a staging directory, then `mv` to replace the live directory in a single filesystem operation, eliminating the window where the site is partially deployed. (4) Add notifications — Slack or email on build failure. (5) Use `Pipeline script from SCM` — store the Jenkinsfile in the Git repository itself so pipeline changes go through code review. (6) Replace `NOPASSWD: ALL` with scoped commands — only grant sudo for the specific commands needed.

---

## 🔗 References

- [Jenkins Poll SCM](https://www.jenkins.io/doc/book/pipeline/syntax/#triggers)
- [Gitea Webhook Configuration](https://docs.gitea.com/administration/config-cheat-sheet#webhook)
- [Jenkins Gitea Plugin](https://plugins.jenkins.io/gitea/)
- [sudoers NOPASSWD](https://www.sudo.ws/docs/man/sudoers.man/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
