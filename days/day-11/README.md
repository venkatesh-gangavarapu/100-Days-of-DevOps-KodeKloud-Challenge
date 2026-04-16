# Day 11 — Installing Tomcat, Configuring Custom Port & Deploying a WAR File

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Application Server Deployment / Java / Tomcat  
**Difficulty:** Intermediate  
**Status:** ✅ Completed

---

## 📋 Task Summary

The Nautilus development team needed their Java application deployed on **App Server 3** (`stapp03`). The requirements:

- Install **Tomcat** application server
- Configure it to run on port **8083** (not the default 8080)
- Deploy `ROOT.war` from Jump Host so the app is accessible directly at the base URL
- Verify with: `curl http://stapp03:8083`

---

## 🧠 Concept — Tomcat Architecture & WAR Deployment

### What is Tomcat?

Apache Tomcat is a **Java Servlet Container** — it hosts Java web applications packaged as WAR (Web Application Archive) files. Unlike a standard web server (Nginx, Apache httpd), Tomcat understands Java EE and executes Java code.

```
Browser / curl
      │
      ▼
  Tomcat (port 8083)
      │
      ▼
  webapps/
    └── ROOT/          ← served at http://host:8083/
          ├── index.jsp
          ├── WEB-INF/
          └── ...
```

### WAR File Deployment — How it Works

A **WAR (Web Application Archive)** is a ZIP file containing a Java web application. Tomcat auto-deploys WAR files placed in the `webapps/` directory:

| WAR filename | Deployed context path | Access URL |
|-------------|----------------------|------------|
| `ROOT.war` | `/` (root) | `http://host:port/` |
| `myapp.war` | `/myapp` | `http://host:port/myapp` |
| `api.war` | `/api` | `http://host:port/api` |

**This is why `ROOT.war` is used** — it deploys to the root context, making the application accessible directly at `http://stapp03:8083` without any path suffix.

### Key Configuration File — `server.xml`

Tomcat's entire network configuration lives in `/etc/tomcat/server.xml`. The HTTP port is defined in the `Connector` element:

```xml
<Connector port="8083" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="8443" />
```

Changing this value and restarting Tomcat is all that's needed to change the listening port.

### Important Directory Structure

```
/etc/tomcat/
  └── server.xml          ← Main config — ports, connectors, virtual hosts

/var/lib/tomcat/
  └── webapps/            ← Drop WAR files here for deployment
        ├── ROOT/         ← Serves http://host:port/
        ├── ROOT.war      ← Auto-exploded to ROOT/ on startup
        └── manager/      ← Tomcat manager app (if installed)

/var/log/tomcat/
  └── catalina.out        ← Main application log — check here for errors

/usr/share/tomcat/        ← Tomcat binaries and libraries
```

> **Real-world context:** Tomcat is the backbone of a huge percentage of enterprise Java applications — banking systems, government portals, internal business applications. Knowing how to install it, tune it, and deploy WAR files is a fundamental DevOps skill when supporting Java development teams. Even in containerized environments (Docker/K8s), Tomcat runs inside containers and the same deployment concepts apply.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Jump Host | WAR file source — `/tmp/ROOT.war` |
| App Server 3 | `stapp03` — user `banner` |
| Service | Apache Tomcat |
| HTTP Port | `8083` (changed from default `8080`) |
| WAR File | `ROOT.war` → deploys to root context `/` |
| Web Apps Dir | `/var/lib/tomcat/webapps/` |
| Config File | `/etc/tomcat/server.xml` |

---

## 🔧 Solution — Step by Step

### Phase 1: Transfer ROOT.war from Jump Host to App Server 3

```bash
# Run from jump host as thor
scp /tmp/ROOT.war banner@stapp03:/tmp/
```

### Phase 2: Configure Tomcat on App Server 3

#### Step 1: SSH into App Server 3

```bash
ssh banner@stapp03
```

#### Step 2: Install Java (Tomcat prerequisite)

```bash
sudo yum install -y java-1.8.0-openjdk
java -version
```

**Expected output:**
```
openjdk version "1.8.0_xxx"
```

#### Step 3: Install Tomcat

```bash
sudo yum install -y tomcat
```

#### Step 4: Verify installation paths

```bash
rpm -ql tomcat | grep -E "webapps|conf|server"
```

Confirms `server.xml` location and `webapps/` directory.

#### Step 5: Change Tomcat port from 8080 to 8083

```bash
sudo sed -i 's/Connector port="8080"/Connector port="8083"/' /etc/tomcat/server.xml
```

**Verify the change:**
```bash
grep 'Connector port' /etc/tomcat/server.xml
```

**Expected output:**
```xml
<Connector port="8083" protocol="HTTP/1.1"
```

#### Step 6: Deploy ROOT.war to webapps directory

```bash
# Remove existing ROOT directory to ensure clean deployment
sudo rm -rf /var/lib/tomcat/webapps/ROOT

# Copy WAR file into webapps
sudo cp /tmp/ROOT.war /var/lib/tomcat/webapps/ROOT.war
```

Tomcat will auto-explode `ROOT.war` into `ROOT/` on startup.

#### Step 7: Start and enable Tomcat

```bash
sudo systemctl start tomcat
sudo systemctl enable tomcat
```

#### Step 8: Verify service is running

```bash
sudo systemctl status tomcat
```

**Expected output:**
```
● tomcat.service - Apache Tomcat Web Application Container
   Active: active (running)
   Loaded: loaded ... enabled
```

#### Step 9: Confirm port 8083 is bound

```bash
sudo ss -tlnp | grep 8083
```

**Expected output:**
```
LISTEN  0  100  *:8083  *:*  users:(("java",pid=XXXX,...))
```

#### Step 10: Test the deployed application

```bash
curl http://stapp03:8083
```

**Expected:** HTML response from the ROOT.war application — no 404, no connection refused. ✅

---

## 📌 Commands Reference

```bash
# ─── Jump Host ───────────────────────────────────────────
scp /tmp/ROOT.war banner@stapp03:/tmp/

# ─── App Server 3 Setup ──────────────────────────────────
sudo yum install -y java-1.8.0-openjdk tomcat

# ─── Port Configuration ──────────────────────────────────
sudo sed -i 's/Connector port="8080"/Connector port="8083"/' /etc/tomcat/server.xml
grep 'Connector port' /etc/tomcat/server.xml     # Verify

# ─── WAR Deployment ──────────────────────────────────────
sudo rm -rf /var/lib/tomcat/webapps/ROOT
sudo cp /tmp/ROOT.war /var/lib/tomcat/webapps/ROOT.war

# ─── Service Management ──────────────────────────────────
sudo systemctl start tomcat
sudo systemctl enable tomcat
sudo systemctl status tomcat

# ─── Verification ────────────────────────────────────────
sudo ss -tlnp | grep 8083                         # Port bound
curl http://stapp03:8083                          # App responds
sudo tail -f /var/log/tomcat/catalina.out         # Live logs

# ─── Debugging ───────────────────────────────────────────
sudo cat /var/log/tomcat/catalina.out             # Deployment errors
sudo ls -la /var/lib/tomcat/webapps/              # Confirm WAR exploded
```

---

## ⚠️ Common Mistakes to Avoid

1. **Not removing the existing `ROOT/` directory before deploying** — If a `ROOT/` directory already exists, Tomcat may not redeploy the WAR correctly. Always `rm -rf webapps/ROOT` before placing `ROOT.war`.
2. **Forgetting to restart after port change** — `server.xml` is only read at startup. Changing the port without restarting does nothing.
3. **Deploying as the wrong filename** — `myapp.war` ≠ `ROOT.war`. The filename determines the context path. If you need the app at `/`, the file must be `ROOT.war`.
4. **Port 8083 blocked by firewall** — On some systems, `firewalld` blocks non-standard ports. If `curl` fails but Tomcat is running, check: `sudo firewall-cmd --list-ports`
5. **Java not installed** — Tomcat will install but fail to start without a JDK/JRE. Always install Java first.
6. **Checking the wrong log** — `systemctl status tomcat` shows systemd-level status. Actual deployment errors (bad WAR, class loading failures) only appear in `/var/log/tomcat/catalina.out`.

---

## 🔍 Tomcat `server.xml` — Key Connector Attributes

```xml
<Connector port="8083"           <!-- HTTP listening port -->
           protocol="HTTP/1.1"
           connectionTimeout="20000"   <!-- ms before idle connection drops -->
           redirectPort="8443"         <!-- redirect HTTP→HTTPS on this port -->
           maxThreads="150"            <!-- max concurrent request threads -->
           URIEncoding="UTF-8" />
```

---

## 🔗 References

- [Apache Tomcat Official Documentation](https://tomcat.apache.org/tomcat-9.0-doc/)
- [Tomcat server.xml Configuration Reference](https://tomcat.apache.org/tomcat-9.0-doc/config/http.html)
- [WAR File Deployment — Tomcat Docs](https://tomcat.apache.org/tomcat-9.0-doc/deployer-howto.html)
- [Java Installation on RHEL/CentOS](https://access.redhat.com/documentation/en-us/openjdk/)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: Tomcat starts successfully but `curl http://stapp03:8083` returns connection refused. How do you diagnose this?**

```bash
# Step 1: Is Tomcat actually running?
sudo systemctl status tomcat

# Step 2: What port is it actually bound to?
sudo ss -tlnp | grep java

# Step 3: Did the WAR deploy correctly?
sudo ls -la /var/lib/tomcat/webapps/
# Should show ROOT/ directory (exploded WAR)

# Step 4: Check deployment logs
sudo cat /var/log/tomcat/catalina.out | tail -50
# Look for: INFO: Starting ProtocolHandler or ERROR messages

# Step 5: Firewall?
sudo iptables -L INPUT -n | grep 8083
```

> "Connection refused" means either: the process isn't running, it's bound to a different port, or a firewall is blocking it. Work through each layer — process → port → firewall.

---

**Q2: What's the difference between `ROOT.war` and `myapp.war` deployment in Tomcat?**

| WAR Name | Context Path | Access URL |
|----------|-------------|------------|
| `ROOT.war` | `/` | `http://host:8083/` |
| `myapp.war` | `/myapp` | `http://host:8083/myapp` |
| `api.war` | `/api` | `http://host:8083/api` |

> `ROOT.war` is special — it deploys to the root context. Any other filename becomes a URL path. For applications that should be accessible at the base URL (no path suffix), the file must be named `ROOT.war`.

---

**Q3: How do you check Tomcat deployment logs when a WAR deploys but the application returns 404?**

```bash
# Main deployment log
sudo tail -100 /var/log/tomcat/catalina.out

# Look for specific patterns:
sudo grep -E "ERROR|SEVERE|Exception|Deployment" /var/log/tomcat/catalina.out

# Check if ROOT was exploded (WAR was unpacked)
ls -la /var/lib/tomcat/webapps/ROOT/

# Check if index page exists
ls /var/lib/tomcat/webapps/ROOT/index.*
```

> 404 after deployment usually means: the WAR didn't explode (check catalina.out for ClassNotFound or XML parsing errors), the application's URL mapping is different from what you expect, or the `ROOT/` directory was missing after placement.

---

**Q4: Tomcat is running on port 8080 and you need to change it to 8083 without downtime. What's the approach?**

```bash
# 1. Edit server.xml
sudo sed -i 's/Connector port="8080"/Connector port="8083"/' /etc/tomcat/server.xml

# 2. Validate the change
grep 'Connector port' /etc/tomcat/server.xml

# 3. Restart (brief downtime — Tomcat has no hot reload for port changes)
sudo systemctl restart tomcat

# 4. Verify binding
sudo ss -tlnp | grep 8083
```

> Port changes in `server.xml` require a restart — there's no reload mechanism for network listeners. For zero-downtime in production, you'd use a load balancer to drain the server, change the port, restart, then re-add it to the pool.

---

**Q5: In a containerized environment (Docker/Kubernetes), how does Tomcat WAR deployment differ?**

> The concept is identical — Tomcat still deploys WARs from `webapps/`. The difference is packaging: instead of copying a WAR to a running server, you build it into the Docker image:
>
> ```dockerfile
> FROM tomcat:9-jdk11
> COPY ROOT.war /usr/local/tomcat/webapps/ROOT.war
> EXPOSE 8080
> ```
>
> In Kubernetes, you'd build this image, push to a registry, and deploy via a Deployment manifest. The WAR still becomes `ROOT/` when the container starts — same Tomcat auto-deploy behavior, just containerized.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
