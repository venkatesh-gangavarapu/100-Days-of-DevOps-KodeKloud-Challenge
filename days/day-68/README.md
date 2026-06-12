# Day 68 — Jenkins Installation: Setting Up CI/CD Server

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** CI/CD / Jenkins / Installation  
**Difficulty:** Beginner–Intermediate  
**Phase:** Phase 5 — Advanced Kubernetes & CI/CD  
**Status:** ✅ Completed

---

## 📋 Task Summary

Install Jenkins on the Jenkins server using `apt`, start it with `service jenkins start`, and create the admin user through the web UI:

| Setting | Value |
|---------|-------|
| Username | `theadmin` |
| Password | `Adm!n321` |
| Full name | `Yousuf` |
| Email | `yousuf@jenkins.stratos.xfusioncorp.com` |

---

## 🧠 Concept — Jenkins & CI/CD

### What is Jenkins?

Jenkins is an open-source automation server — the most widely deployed CI/CD tool in the industry. It automates the build, test, and deploy stages of the software development lifecycle.

```
Developer pushes code
        │
        ▼
Jenkins detects change (SCM polling or webhook)
        │
        ├── Run tests
        ├── Build artifact (Docker image, JAR, etc.)
        ├── Push to registry
        └── Deploy to staging/production
```

### Jenkins Architecture

```
Jenkins Master (this server)
  ├── Web UI (port 8080)
  ├── Job scheduler
  ├── Build history
  └── Plugin management

Jenkins Agents (workers — optional)
  └── Execute build steps distributed across multiple machines
```

### Why `apt` + `service` (not Docker)?

This task specifically requires apt installation — the traditional bare-metal/VM approach. Jenkins also runs excellently in Docker (`jenkins/jenkins:lts`), but bare-metal installation is important to understand for environments where Docker isn't available or when Jenkins needs direct host access.

### Java Dependency

Jenkins is a Java application. It requires a JRE (Java Runtime Environment) to run. LTS versions of Jenkins currently require Java 21 or 17. Installing `openjdk-21-jre` satisfies this requirement.

> **Real-world context:** Jenkins is deployed in virtually every enterprise doing CI/CD. Even as cloud-native alternatives (GitHub Actions, GitLab CI, Tekton) grow, Jenkins remains dominant due to its extensibility (1800+ plugins), enterprise adoption, and the massive existing pipeline investments. Understanding Jenkins installation, configuration, and pipeline creation is one of the most employable DevOps skills.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Jenkins Server | `jenkins` host |
| Access | `ssh root@jenkins` from jump host |
| Root password | `S3curePass` |
| Jenkins default port | `8080` |
| Admin username | `theadmin` |
| Admin password | `Adm!n321` |
| Admin full name | `Yousuf` |
| Admin email | `yousuf@jenkins.stratos.xfusioncorp.com` |

---

## 🔧 Solution — Step by Step

### Step 1: SSH into Jenkins Server

```bash
ssh root@jenkins
# Password: S3curePass
```

### Step 2: Update and install Java

```bash
apt update
apt install -y fontconfig openjdk-21-jre
java -version
# Expected: openjdk version "21.x.x"
```

### Step 3: Add Jenkins repository key

```bash
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
  tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
```

### Step 4: Add Jenkins apt repository

```bash
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | \
  tee /etc/apt/sources.list.d/jenkins.list > /dev/null
```

### Step 5: Install Jenkins

```bash
apt update
apt install -y jenkins
```

### Step 6: Start and verify Jenkins

```bash
service jenkins start
service jenkins status
# Expected: Active: active (running) ✅
```

**If timeout occurs:**
```bash
# Check logs for root cause
cat /var/log/jenkins/jenkins.log | tail -50
# Common issues: Java version mismatch, port conflict
```

### Step 7: Get initial admin password

```bash
cat /var/lib/jenkins/secrets/initialAdminPassword
```

Copy this password — needed for the UI setup.

### Step 8: Web UI Setup (click Jenkins button)

1. Enter the initial admin password
2. Select **Install suggested plugins** — wait for installation
3. **Create First Admin User:**
   - Username: `theadmin`
   - Password: `Adm!n321`
   - Full name: `Yousuf`
   - Email: `yousuf@jenkins.stratos.xfusioncorp.com`
4. Accept default Jenkins URL
5. Click **Start using Jenkins** ✅

---

## 📌 Commands Reference

```bash
# Installation
apt update
apt install -y fontconfig openjdk-21-jre
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
  tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | \
  tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt update
apt install -y jenkins

# Service management
service jenkins start
service jenkins stop
service jenkins restart
service jenkins status

# Initial password
cat /var/lib/jenkins/secrets/initialAdminPassword

# Logs
cat /var/log/jenkins/jenkins.log
journalctl -u jenkins -n 50

# Jenkins home directory
ls /var/lib/jenkins/
```

---

## ⚠️ Common Mistakes to Avoid

1. **Installing Jenkins without Java** — Jenkins won't start without a compatible JRE. Always install Java first and verify with `java -version`.
2. **Wrong Java version** — Jenkins LTS requires Java 17 or 21. Java 8 or 11 may cause startup failures visible in `/var/log/jenkins/jenkins.log`.
3. **Not adding the Jenkins apt repo before installing** — `apt install jenkins` without the repo installs nothing (package not found). Always add the official Jenkins repo first.
4. **Port 8080 already in use** — Jenkins defaults to port 8080. If another service is using it, Jenkins fails to start. Check with `ss -tlnp | grep 8080`.
5. **Incorrect admin credentials in UI** — The admin user details must be exactly as specified. Pay attention to case sensitivity in username and password.
6. **Skipping plugin installation** — Selecting "Install suggested plugins" is important for a functional Jenkins instance — it installs Git, Pipeline, and other essential plugins.

---

## 🔍 Jenkins File Structure After Installation

```
/var/lib/jenkins/          ← Jenkins home directory
  ├── secrets/
  │   └── initialAdminPassword  ← one-time setup password
  ├── jobs/                ← pipeline/job definitions
  ├── plugins/             ← installed plugins
  ├── users/               ← user accounts
  └── workspace/           ← build workspaces

/var/log/jenkins/
  └── jenkins.log          ← Jenkins application log

/etc/default/jenkins       ← Jenkins startup configuration
  (JAVA_ARGS, HTTP_PORT, JENKINS_HOME, etc.)
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is Jenkins and why is it still widely used despite newer CI/CD tools?**

Jenkins is an open-source automation server that orchestrates CI/CD pipelines — building, testing, and deploying software automatically on code changes. Despite GitHub Actions, GitLab CI, and CircleCI gaining popularity, Jenkins remains dominant for several reasons: it has 1800+ plugins covering virtually every tool integration, it runs on-premises (important for regulated industries), its Pipeline-as-Code (Jenkinsfile) is extremely flexible, and organizations have massive existing investments in Jenkins jobs and pipelines. Jenkins is not going away — understanding it is one of the most employable CI/CD skills.

---

**Q2: What is the difference between `service jenkins start` and `systemctl start jenkins`?**

Both start the Jenkins service, but `service` is the older SysVinit-compatible wrapper while `systemctl` is the systemd-native command. On modern Debian/Ubuntu systems running systemd, `service jenkins start` ultimately calls `systemctl start jenkins` internally. The task specifically requires `service` — this is important in environments that may use SysVinit or where scripts must be portable across init systems. `systemctl` provides more information (`systemctl status jenkins` shows logs, PID, memory, timing) while `service jenkins status` provides basic status. For automation scripts targeting diverse Linux environments, `service` is more portable.

---

**Q3: What is the Jenkins initial admin password and why does it exist?**

The initial admin password is a one-time secret stored at `/var/lib/jenkins/secrets/initialAdminPassword` that Jenkins generates on first install. It exists to ensure only someone with server access (who can read that file) can complete the initial setup — preventing unauthorized configuration of a newly installed Jenkins instance. Once you've completed setup and created an admin account through the UI, the initial password is no longer used and can be deleted. This security pattern (requiring local server access for initial configuration) is common in self-hosted tools.

---

**Q4: What are Jenkins plugins and which are essential for a DevOps pipeline?**

Jenkins plugins extend its functionality — almost every integration is a plugin. Essential plugins for a modern DevOps pipeline: **Git** (source code checkout), **Pipeline** (Jenkinsfile support), **Docker Pipeline** (build and push Docker images), **Kubernetes** (run build agents as K8s pods), **Blue Ocean** (modern pipeline visualization), **Credentials** (secure secret storage), **SSH Agent** (SSH key injection), **Slack Notification** or **Email Extension** (build notifications). The "Install suggested plugins" option during setup installs the most commonly needed subset. Additional plugins are added via Manage Jenkins → Manage Plugins.

---

**Q5: What is a Jenkinsfile and how does Pipeline-as-Code work?**

A Jenkinsfile is a text file stored in the source code repository that defines the CI/CD pipeline as code. Jenkins reads it and executes the pipeline stages. Example:
```groovy
pipeline {
    agent any
    stages {
        stage('Build') { steps { sh 'docker build -t myapp .' } }
        stage('Test')  { steps { sh 'docker run myapp pytest' } }
        stage('Deploy'){ steps { sh 'kubectl apply -f k8s/' } }
    }
}
```
Pipeline-as-Code means the pipeline definition is version-controlled alongside the application — pipeline changes go through code review, are tracked in git history, and can be rolled back. This is fundamentally better than GUI-configured jobs that have no audit trail.

---

**Q6: How would you secure a Jenkins installation in production?**

Multiple layers: (1) **Authentication** — configure LDAP/Active Directory or OAuth (GitHub, Google) so users log in with corporate credentials rather than local Jenkins accounts. (2) **Authorization** — use Role-Based Access Strategy plugin to restrict who can create jobs, trigger builds, manage plugins. (3) **CSRF protection** — enabled by default, prevents cross-site request forgery. (4) **Credentials management** — store secrets (API keys, passwords, SSH keys) in Jenkins Credentials Manager, never in Jenkinsfiles or job configs in plain text. (5) **HTTPS** — put Jenkins behind a reverse proxy (nginx) with TLS termination — never expose HTTP port 8080 directly. (6) **Network** — Jenkins UI accessible only on VPN or corporate network; agent communication on internal network only. (7) **Plugin hygiene** — regularly update plugins and Jenkins itself; outdated plugins are a major attack surface.

---

## 🔗 References

- [Jenkins Installation on Debian/Ubuntu](https://www.jenkins.io/doc/book/installing/linux/#debianubuntu)
- [Jenkins Getting Started](https://www.jenkins.io/doc/book/getting-started/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Jenkins Security Best Practices](https://www.jenkins.io/doc/book/security/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
