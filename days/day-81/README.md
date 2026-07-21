# Day 81 — Jenkins Two-Stage Pipeline: Deploy + Test

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** CI/CD / Jenkins / Pipeline / Testing  
**Difficulty:** Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create Jenkins pipeline job `deploy-job` with two stages:
- `Deploy` — `git reset --hard origin/master` in `/var/www/html`
- `Test` — `curl -f http://stlb01:8091` validates the deployment

**index.html content:** `Welcome to xFusionCorp Industries`
**Java version:** `java-17-openjdk` (specified by task)

---

## 🧠 Concept — Two-Stage Pipeline: Deploy + Test

### Why a Test Stage?

Adding a Test stage after Deploy changes the pipeline from "we deployed something" to "we deployed something and confirmed it works." The curl command is the simplest possible smoke test — if the LBR URL returns HTTP 200, the entire stack is functioning:

```
curl -f http://stlb01:8091
  → HTTP 200: LBR → Apache:8080 → /var/www/html → content ✅
  → HTTP failure: something in the chain is broken ❌ → pipeline fails
```

### `curl -f` — What the `-f` Flag Does

```bash
curl http://stlb01:8091          # Returns content but exits 0 even on 404/500
curl -f http://stlb01:8091       # Exits non-zero on HTTP errors (4xx, 5xx)
```

Without `-f`, curl exits 0 (success) even when the server returns 404 or 500 — the Test stage would pass even on a broken deployment. With `-f` (fail silently), curl exits non-zero on HTTP errors, causing `|| exit 1` to trigger and failing the pipeline. `curl -f` is essential for meaningful HTTP testing in scripts.

### The `sleep 3` Before curl

Apache may take a moment to start serving after `systemctl start`. Without `sleep 3`, a fast Test stage might curl before Apache is fully ready and get a connection refused, failing unnecessarily. Three seconds is a practical buffer — enough time for httpd to bind to port 8080 and begin serving.

### Stage Name Case Sensitivity

The task explicitly states stage names are case-sensitive: `Deploy` and `Test` (capital first letter). `deploy` or `DEPLOY` would be different stage names that might fail validation. Always copy stage names exactly as specified.

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
                    sudo git fetch origin master
                    sudo git reset --hard origin/master
                    sudo chown -R sarah:sarah /var/www/html
                    sudo systemctl start httpd || true
                '''
            }
        }
        stage('Test') {
            steps {
                sh '''
                    sleep 3
                    curl -f http://stlb01:8091 || exit 1
                    echo "Website is accessible ✅"
                '''
            }
        }
    }
}
```

---

## 🔧 Solution — Step by Step

### Update index.html and push

```bash
ssh sarah@stapp01   # Sarah_pass123
cd /var/www/html
echo "Welcome to xFusionCorp Industries" > index.html
git config user.email "sarah@stratos.xfusioncorp.com"
git config user.name "sarah"
git add index.html
git commit -m "Update: Welcome to xFusionCorp Industries"
git push origin master
```

### stapp01 pre-work

```bash
ssh tony@stapp01   # Ir0nM@n
sudo yum install -y java-17-openjdk
sudo bash -c 'echo "sarah ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sarah'
sudo chmod 440 /etc/sudoers.d/sarah
sudo chown -R sarah:sarah /var/www/html
sudo systemctl start httpd && sudo systemctl enable httpd
sudo -u sarah mkdir -p /home/sarah/jenkins_agent
```

### Jenkins setup

```
Nodes → App Server 1
  Root: /home/sarah/jenkins_agent, Label: stapp01
  SSH: stapp01, sarah-creds, Non verifying
→ Online ✅

New Item → deploy-job → Pipeline → OK
Pipeline script: [paste Jenkinsfile]
→ Save → Build Now → SUCCESS ✅
```

---

## ⚠️ Common Mistakes

1. **Wrong stage names** — Must be exactly `Deploy` and `Test`. Case-sensitive.
2. **`curl` without `-f`** — Without it, curl exits 0 even on HTTP errors. Test stage becomes meaningless.
3. **java-11 instead of java-17** — Task specifies java-17-openjdk. Some Jenkins features require Java 17.
4. **Wrong index.html content** — `Welcome to xFusionCorp Industries` (no "the"). Copy exactly.
5. **Test stage before httpd is ready** — `sleep 3` gives httpd time to start before curl runs.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is a smoke test and how does the `curl` step implement one?**

A smoke test is the minimal verification that a system is functioning after a change — just enough to confirm it's not completely broken, not a full functional test suite. `curl -f http://stlb01:8091` is a smoke test: it verifies the load balancer is responding, Apache is serving content, and the document root is readable. It doesn't check the content is correct (that would be `curl | grep "Welcome to xFusionCorp"`) or that forms work or that JavaScript executes — just that something is serving at that URL. Real pipelines layer smoke tests, integration tests, and end-to-end tests in increasing depth, but a curl smoke test is always the first gate.

---

**Q2: What does `curl -f` do and why is it important in CI/CD scripts?**

`curl -f` (or `--fail`) instructs curl to exit with a non-zero status code when the server returns an HTTP error status (4xx or 5xx). Without `-f`, curl exits 0 (success) even when it receives a 404 "Not Found" or 500 "Internal Server Error" — the shell sees success and the pipeline continues as if the deployment worked. With `-f`, a 404 or 500 causes curl to exit with code 22, which bash interprets as failure, causing the pipeline stage to fail. In CI/CD, you always want to know when the server returns an error — `-f` is the flag that ensures curl's exit code reflects the actual HTTP response status.

---

**Q3: How would you improve the Test stage to verify actual content, not just HTTP status?**

```bash
# Check HTTP status AND content
RESPONSE=$(curl -f -s http://stlb01:8091)
if echo "$RESPONSE" | grep -q "Welcome to xFusionCorp Industries"; then
    echo "Content check passed ✅"
else
    echo "Content check FAILED ❌"
    exit 1
fi
```

This verifies both that the server responds (via `curl -f`) and that the response contains the expected content (via `grep`). If someone deployed the wrong branch or the file was empty, this check would catch it while a simple HTTP status check wouldn't. For more sophisticated testing, tools like `htmlproofer`, `selenium`, or `playwright` test full user journeys rather than just content presence.

---

**Q4: What is `git reset --hard origin/master` and why is it preferred over `git pull` for deployments?**

`git pull` performs a fetch + merge — it tries to merge remote changes into the current local state. If there are local uncommitted changes, conflicts, or divergent histories, `git pull` can fail interactively. `git reset --hard origin/master` is non-interactive: it fetches all changes from origin, then forcibly moves the local HEAD to match origin/master exactly, discarding any local changes. The working tree matches the remote perfectly, regardless of prior state. For automated deployments where the deployment target should always reflect origin (not any local modifications), `git reset --hard` is the correct tool — it's idempotent, conflict-free, and always produces a known state.

---

**Q5: How would you add a rollback mechanism if the Test stage fails?**

```groovy
pipeline {
    agent { label 'stapp01' }
    stages {
        stage('Deploy') {
            steps {
                sh '''
                    cd /var/www/html
                    git stash  # save current state before pull
                    sudo git fetch origin master
                    sudo git reset --hard origin/master
                '''
            }
        }
        stage('Test') {
            steps {
                sh 'curl -f http://stlb01:8091 || exit 1'
            }
        }
    }
    post {
        failure {
            sh '''
                cd /var/www/html
                sudo git reset --hard HEAD~1
                sudo systemctl restart httpd
                echo "Rolled back to previous commit"
            '''
        }
    }
}
```

The `post { failure { } }` block runs only when the pipeline fails. `git reset --hard HEAD~1` reverts to the previous commit. In production, a more robust approach maintains a separate "stable" directory and uses atomic symlink switching.

---

**Q6: Why does the task specify java-17-openjdk specifically?**

Jenkins LTS (Long-Term Support) versions from 2.375+ require Java 11 or 17. Java 17 is the current LTS release of OpenJDK and is the recommended Java version for Jenkins as of 2023+. Java 11 support is being phased out. The Jenkins agent (the JAR that runs on stapp01 to communicate with the master) must run on a compatible Java version — using java-17 ensures compatibility with current and upcoming Jenkins LTS versions. Using java-8 or java-11 may work today but will fail when Jenkins is upgraded, so provisioning java-17 from the start is the forward-compatible choice.

---

## 🔗 References

- [Jenkins Declarative Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [curl --fail flag](https://curl.se/docs/manpage.html#-f)
- [Jenkins Java Requirements](https://www.jenkins.io/doc/administration/requirements/java/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
