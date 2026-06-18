# Day 71 — Jenkins Parameterized Job: Remote Package Installation via SSH

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** CI/CD / Jenkins / Automation / SSH  
**Difficulty:** Intermediate  
**Phase:** Phase 5 — Advanced Kubernetes & CI/CD  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create a Jenkins job `install-packages` that:
1. Accepts a string parameter `PACKAGE`
2. Connects to the Storage Server via SSH
3. Installs the specified package using the package manager
4. Verified by building with `PACKAGE=vim-enhanced` and confirming installation

---

## 🧠 Concept — Jenkins as an Automation Orchestrator

### What This Task Actually Demonstrates

This is the simplest possible CI/CD pattern with real value: a human (or another system) provides a parameter, Jenkins executes a remote action, and the result is auditable. Instead of someone SSHing manually into the Storage Server and running `yum install`, the action is now: repeatable, logged (Console Output), permission-controlled (via yesterday's RBAC setup), and triggerable by anyone with Job/Build rights — without giving them SSH access to the server itself.

```
Before Jenkins:
  Engineer SSHes into Storage Server manually
  Runs yum install <package>
  No record of who did what, when

After Jenkins:
  Engineer triggers "install-packages" job with PACKAGE=vim-enhanced
  Jenkins SSHes in on their behalf using stored credentials
  Console Output is the permanent audit log
  Engineer never needs direct SSH access to the server
```

### Build Parameters

```
This project is parameterized
  → String Parameter
      Name: PACKAGE
      Default Value: (optional)
```

Parameters turn a fixed job into a reusable template. The same job installs `vim-enhanced`, `htop`, `git`, or any other package — driven entirely by what's passed at build time. In the job's build steps, `$PACKAGE` (or `${PACKAGE}`) is substituted with whatever value was provided.

### Publish Over SSH Plugin

This plugin lets Jenkins maintain a registry of SSH server connections (hostname, credentials) configured once in `Manage Jenkins → System`, then referenced by name in any job's build steps. This separation matters:

```
Global SSH Server config (configured once):
  Name: storage-server
  Hostname: ststor01
  Username: natasha
  Password: ********

Job build step (referenced by name):
  SSH Server: storage-server
  Exec command: sudo yum install -y $PACKAGE
```

Credentials live in one place, managed by an admin. Jobs reference the server by name without ever exposing the password in job configuration — useful when multiple jobs need to reach the same server, and critical when jobs are configured by users who shouldn't see raw credentials.

> **Real-world context:** This pattern — Jenkins as a controlled gateway to infrastructure operations — is extremely common for "break glass" or routine maintenance tasks. Instead of distributing SSH keys to every engineer who might need to install a package or restart a service, you give them a Jenkins job with a parameter. The job runs with infrastructure-team-controlled credentials, every execution is logged, and access can be revoked by removing Jenkins job permissions rather than rotating SSH keys across the fleet.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Jenkins access | UI (top bar button) |
| Login | `admin` / `Adm!n321` |
| Job name | `install-packages` |
| Job type | Freestyle project |
| Parameter | `PACKAGE` (String Parameter) |
| Target | Storage Server (`ststor01`) |
| SSH user | `natasha` |
| Verification package | `vim-enhanced` |

---

## 🔧 Solution — Step by Step

### Step 1: Install Publish Over SSH plugin

```
Manage Jenkins → Plugins → Available plugins
  Search "Publish Over SSH" → check it → Install
→ Restart Jenkins when installation is complete and no jobs are running
→ Wait for login page → log back in
```

### Step 2: Configure the SSH server connection

```
Manage Jenkins → System → Publish over SSH
  Add SSH Server:
    Name: storage-server
    Hostname: ststor01
    Username: natasha
    Remote Directory: /tmp
  Advanced → Use password authentication
    Password: <storage server password>
  Test Configuration → Success ✅
→ Save
```

### Step 3: Create the freestyle job

```
Dashboard → New Item → install-packages → Freestyle project → OK
```

### Step 4: Add the String Parameter

```
General → ☑ This project is parameterized
  → Add Parameter → String Parameter
      Name: PACKAGE
```

### Step 5: Add the SSH build step

```
Build Steps → Add build step → Send files or execute commands over SSH
  SSH Server: storage-server
  Exec command: sudo yum install -y $PACKAGE
→ Save
```

### Step 6: Build and verify

```
Build with Parameters → PACKAGE: vim-enhanced → Build
→ Console Output confirms successful SSH exec + yum install

On Storage Server:
  rpm -q vim-enhanced → confirms installed ✅
```

### Step 7: Confirm reliability with a second build

```
Build with Parameters → PACKAGE: htop → Build
→ Console Output confirms success again ✅
```

---

## 📌 Verification Checklist

```
[O☑ Publish Over SSH plugin installed and Jenkins restarted
☑ SSH server "storage-server" configured and tested successfully
☑ Job "install-packages" created as Freestyle project
☑ String Parameter "PACKAGE" added
☑ SSH build step configured with $PACKAGE substitution
☑ First build (PACKAGE=vim-enhanced) successful
☑ Package verified installed on Storage Server
☑ Second build with different package also successful
☑ Console Output reviewed for both builds — no errors
```

---

## ⚠️ Common Mistakes to Avoid

1. **Not testing the SSH connection before saving** — Always click "Test Configuration" in the Publish Over SSH global settings. A failed connection here means every job using this server will fail.
2. **Wrong variable syntax in Exec command** — `$PACKAGE` and `${PACKAGE}` both work in most shells, but verify the build step actually substitutes the parameter — check Console Output for the literal command that ran.
3. **Forgetting `sudo`** — If the SSH user (`natasha`) isn't root, `yum install` fails with a permission error unless `sudo` is used and the user has passwordless sudo configured.
4. **Remote Directory misconfiguration** — Publish Over SSH requires a "Remote Directory" even if you're only running exec commands, not transferring files. Use `/tmp` or any writable path.
5. **Not verifying on the actual target server** — A "successful" build in Jenkins doesn't guarantee the package is installed if the SSH command silently failed past Jenkins's exit-code checking. Always verify with `rpm -q $PACKAGE` or `which $PACKAGE` on the storage server directly.

---

## 🔍 Build Execution Flow

```
User clicks "Build with Parameters" → enters PACKAGE=vim-enhanced
        │
        ▼
Jenkins job starts → substitutes $PACKAGE in build step
        │
        ▼
Publish Over SSH plugin connects to storage-server (ststor01)
  using stored credentials (natasha)
        │
        ▼
Executes: sudo yum install -y vim-enhanced
        │
        ▼
Exit code 0 → Jenkins marks build SUCCESS
Exit code non-zero → Jenkins marks build FAILURE
        │
        ▼
Console Output stores full transcript — permanent audit record
```

---
[I
## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the benefit of using Jenkins parameters instead of hardcoding values into a job?**

Parameters turn a single-purpose job into a reusable template. Without parameters, you'd need a separate job for every package you might want to install — `install-vim`, `install-htop`, `install-git` — each duplicating the same SSH connection logic. With a `PACKAGE` string parameter, one job handles all of them. This reduces maintenance (one job to update if the SSH server changes), reduces job sprawl in the Jenkins dashboard, and makes the job genuinely general-purpose. The tradeoff is less validation — a parameterized job will attempt to install whatever string is provided, so input validation (a `Choice Parameter` with a fixed list instead of free-text `String Parameter`) is safer in production for sensitive operations.

---

**Q2: What is the Publish Over SSH plugin and what problem does it solve?**

It provides a centralized way to configure SSH server connections (hostname, port, credentials) once in Jenkins's global configuration, then reference them by name in any job's build steps without re-entering credentials. The alternative — using `Execute shell` with a raw `ssh user@host command` invocation — requires the Jenkins agent to have SSH keys configured locally and exposes connection details in every job's configuration. Publish Over SSH centralizes credential management: an admin configures the server once, and job authors only select it by name, never seeing the actual password. This is a meaningful security improvement when many jobs need access to the same set of target servers.

---

**Q3: Why is "Test Configuration" important before saving an SSH server connection in Jenkins?**

It validates the hostname is reachable, the username/credentials are correct, and the connection method (password or key) actually works — before any job depends on it. Without testing, a misconfigured SSH server entry fails silently until the first job tries to use it, at which point you're debugging during an actual automation run instead of during setup. Testing immediately surfaces issues like wrong hostname, firewall blocking the port, or incorrect credentials, letting you fix them in a controlled context rather than during a "this should just work" automation trigger.

---

**Q4: How would you make this job more secure for a production environment?**

Several improvements: (1) Use SSH key-based authentication instead of password authentication — store the private key as a Jenkins Credential rather than a plaintext password in the Publish Over SSH config. (2) Restrict the SSH user's sudo permissions to only `yum install` via a sudoers rule, rather than full sudo access — limiting blast radius if the job is somehow triggered maliciously. (3) Use a `Choice Parameter` with an approved package allowlist instead of a free-text `String Parameter`, preventing arbitrary command injection via creative package names. (4) Apply yesterday's RBAC lessons — restrict who has Job/Build permission on this specific job via project-based security, since it has real infrastructure impact.

---

**Q5: What is the risk of using a free-text String Parameter for something that triggers a shell command?**

Command injection. If the Exec command is built by directly substituting `$PACKAGE` into a shell command without sanitization, a malicious or careless value like `vim-enhanced; rm -rf /` could execute unintended commands on the target server — depending on how Jenkins and the shell handle the substitution. In practice, Jenkins's parameter substitution for `Execute shell`-style steps generally treats the parameter as a single token rather than re-parsing it as shell syntax, which mitigates but doesn't eliminate this risk. For genuinely sensitive operations, a `Choice Parameter` with predefined safe values, or explicit input validation in a scripted/pipeline job, is the safer pattern.

---

**Q6: How would you convert this freestyle job into a Jenkins Pipeline (Jenkinsfile) for better version control?**

```groovy
pipeline {
    agent any
    parameters {
        string(name: 'PACKAGE', defaultValue: '', description: 'Package to install')
    }
    stages {
        stage('Install Package') {
            steps {
                sshagent(['storage-server-credentials']) {
                    sh "ssh natasha@ststor01 'sudo yum install -y ${params.PACKAGE}'"
                }
            }
        }
    }
}
```
This Jenkinsfile would be stored in a Git repository, giving the job definition itself version control, code review, and change history — improvements over the freestyle job's UI-only configuration which has no audit trail for configuration changes (only build execution history). Pipeline-as-Code is the standard production approach; freestyle jobs are typically used for learning or simple, infrequently-changed automation.

---

## 🔗 References

- [Publish Over SSH Plugin](https://plugins.jenkins.io/publish-over-ssh/)
- [Jenkins Parameterized Builds](https://www.jenkins.io/doc/book/pipeline/syntax/#parameters)
- [Jenkins Freestyle Projects](https://www.jenkins.io/doc/book/pipeline/getting-started/#defining-a-pipeline-in-scm)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
