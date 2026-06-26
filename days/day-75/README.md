# Day 75 — Jenkins Agent Nodes: Distributing Builds Across All App Servers

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** CI/CD / Jenkins / Distributed Builds / Agents  
**Difficulty:** Intermediate  
**Phase:** 🏁 Phase 5 Complete — Advanced Kubernetes & CI/CD  
**Status:** ✅ Completed

---

## 📋 Task Summary

Configure Jenkins master-agent architecture by adding all three app servers as SSH build agents:

| Node Name | Host | User | Root Directory | Label |
|-----------|------|------|----------------|-------|
| `App_server_1` | `stapp01` | tony / Ir0nM@n | `/home/tony/jenkins` | `stapp01` |
| `App_server_2` | `stapp02` | steve / Am3ric@ | `/home/steve/jenkins` | `stapp02` |
| `App_server_3` | `stapp03` | banner / BigGr33n | `/home/banner/jenkins` | `stapp03` |

---

## 🧠 Concept — Jenkins Master-Agent Architecture

### Why Distributed Builds?

A standalone Jenkins master runs all builds on itself — which works for small teams but creates bottlenecks and risks as scale increases. Jenkins master-agent (formerly master-slave) architecture separates concerns:

```
Jenkins Master (controller):
  - Hosts the UI and API
  - Schedules and coordinates builds
  - Stores build history and artifacts
  - Does NOT run build steps (ideally)

Jenkins Agents (nodes):
  - Execute the actual build steps
  - Isolated environments per server
  - Can have different OS, tools, capabilities
  - Scalable — add more agents as load increases
```

### SSH Build Agents — How They Work

```
Jenkins Master
    │
    │ 1. TCP/SSH connection to agent
    │ 2. Upload agent.jar (Jenkins remoting)
    │ 3. Start agent.jar with Java
    │
    ▼
App Server (agent)
    - agent.jar runs in /home/tony/jenkins
    - Opens bidirectional channel to master
    - Receives build instructions
    - Executes steps locally
    - Returns results/artifacts to master
```

Jenkins master SSHes to the agent server, uploads a small Java process (`agent.jar`), and that process handles build execution. The agent server needs Java installed and an SSH-accessible user.

### Labels — Targeting Specific Agents

```yaml
# In a Jenkins job or Jenkinsfile:
node('stapp01') {
    // This build ONLY runs on the agent labeled stapp01
    sh 'hostname'  # outputs: stapp01
}

node('stapp02') {
    // This build ONLY runs on the agent labeled stapp02
}
```

Labels allow directing specific jobs to specific servers. A job that installs packages for App Server 1's environment is pinned with `label: stapp01` to ensure it runs on that specific node — not App Server 2 or 3.

### Remote Root Directory

```
/home/tony/jenkins/
  ├── workspace/        ← build workspaces live here
  │     └── job-name/  ← one subdir per job
  ├── remoting/         ← agent.jar and logs
  └── tools/            ← auto-installed tools (Maven, etc.)
```

Jenkins creates this directory if it doesn't exist. The user (`tony`) must have write access to this path.

> **Real-world context:** Jenkins master-agent is the production standard for teams running more than a handful of jobs. In cloud environments, agents are often ephemeral — Kubernetes pods or EC2 instances that spin up for a single build and terminate when done. The permanent agent model (today's task) is used for dedicated servers that need to be continuously available for specific workloads — running jobs on specific infrastructure, maintaining environment state between builds, or testing on bare-metal hardware.

---

## 🔧 Solution — Step by Step

### Step 1: Verify SSH Build Agents plugin

```
Manage Jenkins → Plugins → Installed plugins → Search "SSH Build Agents"
(Install if not present, restart Jenkins if required)
```

### Step 2: Add credentials for each server

```
Manage Jenkins → Credentials → System → Global credentials → Add Credentials
  (Repeat for each server: tony/Ir0nM@n, steve/Am3ric@, banner/BigGr33n)
```

### Step 3: Add App_server_1

```
Manage Jenkins → Nodes → New Node
  Name: App_server_1 → Permanent Agent → Create

  Remote root directory: /home/tony/jenkins
  Labels:               stapp01
  Launch method:        Launch agents via SSH
    Host:               stapp01
    Credentials:        tony (Ir0nM@n)
    Host Key Verification: Non verifying
→ Save → Launch Agent
```

### Step 4: Add App_server_2

```
New Node → App_server_2 → Permanent Agent → Create
  Remote root directory: /home/steve/jenkins
  Labels:               stapp02
  Launch method:        SSH
    Host:               stapp02
    Credentials:        steve (Am3ric@)
    Host Key Verification: Non verifying
→ Save → Launch Agent
```

### Step 5: Add App_server_3

```
New Node → App_server_3 → Permanent Agent → Create
  Remote root directory: /home/banner/jenkins
  Labels:               stapp03
  Launch method:        SSH
    Host:               stapp03
    Credentials:        banner (BigGr33n)
    Host Key Verification: Non verifying
→ Save → Launch Agent
```

### Step 6: Verify all agents online

```
Manage Jenkins → Nodes
  App_server_1  ● Connected ✅
  App_server_2  ● Connected ✅
  App_server_3  ● Connected ✅
```

**Troubleshooting if offline:**
- Click the node → click "Launch agent"  
- Check log output for SSH errors, Java version issues, or directory permissions
- Verify the username/password are correct by SSHing manually from Jenkins server

---

## 📌 Verification Checklist

```
☑ SSH Build Agents plugin installed
☑ Credentials added for tony, steve, banner
☑ App_server_1: name, label (stapp01), root (/home/tony/jenkins), SSH host (stapp01)
☑ App_server_2: name, label (stapp02), root (/home/steve/jenkins), SSH host (stapp02)
☑ App_server_3: name, label (stapp03), root (/home/banner/jenkins), SSH host (stapp03)
☑ All three nodes show Connected/Online in Manage Jenkins → Nodes
☑ Agent log shows "Agent successfully connected and online"
```

---

## ⚠️ Common Mistakes to Avoid

1. **Wrong node naming** — The task requires exactly `App_server_1`, `App_server_2`, `App_server_3` (underscore, capital A and S). Typos fail validation.
2. **Wrong label** — Labels must be `stapp01`, `stapp02`, `stapp03` — lowercase, matching the hostnames exactly.
3. **Wrong remote root directory** — Must match exactly: `/home/tony/jenkins`, `/home/steve/jenkins`, `/home/banner/jenkins`.
4. **Host Key Verification rejecting connection** — First connection from Jenkins to a new host fails if host key verification is set to "Known hosts file" and the host isn't in `~/.ssh/known_hosts`. Use "Non verifying Verification Strategy" for lab environments.
5. **Java not installed on agent servers** — Jenkins agent requires Java on the target server. If SSH connects but agent fails to start, check `java -version` on the app server. Install Java if missing.
6. **Permissions on remote root directory** — Jenkins creates the directory if the user has write permission to the parent (`/home/tony/`). If permission is denied, Jenkins logs show the error.

---

## 🔍 Agent Connection Flow

```
Jenkins master: ssh tony@stapp01
  → Upload agent.jar to /home/tony/jenkins/remoting/
  → Execute: java -jar agent.jar -jnlpUrl ...
  → stapp01 runs agent.jar
  → Bidirectional TCP channel established
  → Jenkins node shows: Connected ✅

Build triggered with label stapp01:
  Jenkins → "which agent has label stapp01?" → App_server_1
  → Send build instructions to App_server_1
  → App_server_1 executes steps in /home/tony/jenkins/workspace/
  → Results returned to Jenkins master
```

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between a Jenkins master and a Jenkins agent?**

The Jenkins master (controller) manages the overall CI/CD system: hosts the web UI and API, schedules builds, stores configuration and history, manages credentials and plugins. The Jenkins agent (formerly slave) is a remote machine that executes build steps on behalf of the master. The master tells the agent what to run; the agent runs it and reports results back. In production, the master is typically a dedicated server running only Jenkins controller processes — no build steps run on it directly. All actual compilation, testing, and deployment happens on agents. This separation keeps the master stable (not resource-exhausted by builds) and allows scaling by adding more agents.

---

**Q2: What is the "Remote root directory" in a Jenkins agent configuration?**

The remote root directory is the working directory on the agent server where Jenkins creates all its agent-side files. It contains: `workspace/` (one subdirectory per Jenkins job that runs on this agent, where source code is checked out and build steps execute), `remoting/` (the agent JAR file and communication logs), and `tools/` (auto-installed build tools like specific JDK versions, Maven, etc.). Jenkins creates this directory if it doesn't exist (if the user has permission). Each agent gets its own isolated remote root, preventing cross-job interference. The path should be on a disk with sufficient space for build workspaces and artifacts.

---

**Q3: What are Jenkins agent labels and how do they affect job routing?**

Labels are arbitrary tags assigned to agents that jobs use to request specific execution environments. In a Freestyle job, you check "Restrict where this project can be run" and enter a label expression. In a Pipeline, `node('stapp01') { ... }` routes that block to any agent with the `stapp01` label. Labels can be: specific agents (`stapp01`), agent groups (`linux`, `docker-enabled`), capability-based (`has-maven`, `large-memory`), or environment-based (`production`, `testing`). Multiple labels can be assigned per agent: `stapp01 linux x86_64`. Label expressions support AND (`stapp01 && docker`), OR (`stapp01 || stapp02`), and NOT (`!windows`). This flexibility enables complex job routing logic.

---

**Q4: What is "Host Key Verification Strategy" and why does "Non verifying" work for lab environments?**

When SSH connects to a server, it checks the server's public key against a known hosts file (`~/.ssh/known_hosts`) to prevent man-in-the-middle attacks. "Known hosts file" verification rejects connections to hosts not previously added to known_hosts — appropriate for production where you've explicitly verified each server's identity. "Non verifying" accepts any host key without checking — equivalent to `ssh -o StrictHostKeyChecking=no`. In lab environments where servers are newly provisioned and frequently rebuilt, "Non verifying" prevents constant known_hosts management. In production, use "Manually trusted key Verification Strategy" (prompts admin to approve the key once and stores it) or ensure agents' keys are pre-populated in known_hosts.

---

**Q5: How would you use these labeled agents to run a job specifically on App Server 2?**

In a Freestyle job: check "Restrict where this project can be run" in the General section, enter `stapp02` in the Label Expression field. Only agents labeled `stapp02` (which is only `App_server_2`) will execute this job. In a Declarative Pipeline:
```groovy
pipeline {
    agent { label 'stapp02' }
    stages {
        stage('Run on stapp02') {
            steps { sh 'hostname' }  // output: stapp02
        }
    }
}
```
This is exactly how Day 71's `install-packages` job could be improved: instead of SSHing from Jenkins master to stapp01, run the job directly on the `stapp01` agent where the `yum install` runs natively without needing a secondary SSH hop.

---

**Q6: What are ephemeral/dynamic agents and when would you use them over permanent agents?**

Permanent agents (today's task) are always-on servers that remain connected to Jenkins regardless of whether builds are running — they consume resources continuously. Ephemeral agents are created on-demand for each build and terminated when complete. With the Kubernetes plugin, Jenkins spins up a fresh Pod for each build, runs it, and deletes it — perfectly clean environment every time, scales to zero when idle. With the Amazon EC2 plugin, Jenkins launches an EC2 instance for each build. Ephemeral agents are preferred for: inconsistent build load (don't pay for idle capacity), clean environment requirements (no state contamination between builds), and environments where agent count varies wildly. Permanent agents are preferred for: specialized hardware (bare metal, specific GPU), stateful caches, licensed tools that can't be dynamically installed, or low-latency build starts.

---

## 🔗 References

- [Jenkins Distributed Builds](https://www.jenkins.io/doc/book/using/using-agents/)
- [SSH Build Agents Plugin](https://plugins.jenkins.io/ssh-slaves/)
- [Jenkins Node Configuration](https://www.jenkins.io/doc/book/managing/nodes/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
