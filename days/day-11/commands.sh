#!/bin/bash
# Day 11 — Tomcat Installation, Port Config & WAR Deployment
# Challenge: KodeKloud 100 Days of DevOps
# Task: Install Tomcat on stapp03, run on port 8083, deploy ROOT.war

# ─────────────────────────────────────────
# PHASE 1: JUMP HOST — Transfer ROOT.war
# ─────────────────────────────────────────
# Run from jump host as thor:
scp /tmp/ROOT.war banner@stapp03:/tmp/

# ─────────────────────────────────────────
# PHASE 2: APP SERVER 3 — ssh banner@stapp03
# ─────────────────────────────────────────

# STEP 1: Install Java (Tomcat requires JRE)
sudo yum install -y java-1.8.0-openjdk
java -version

# STEP 2: Install Tomcat
sudo yum install -y tomcat

# STEP 3: Change port 8080 → 8083 in server.xml
sudo sed -i 's/Connector port="8080"/Connector port="8083"/' /etc/tomcat/server.xml

# Verify port change
grep 'Connector port' /etc/tomcat/server.xml
# Expected: <Connector port="8083" protocol="HTTP/1.1"

# STEP 4: Deploy ROOT.war (root context = base URL /)
sudo rm -rf /var/lib/tomcat/webapps/ROOT
sudo cp /tmp/ROOT.war /var/lib/tomcat/webapps/ROOT.war

# STEP 5: Start and enable Tomcat
sudo systemctl start tomcat
sudo systemctl enable tomcat

# STEP 6: Verify service status
sudo systemctl status tomcat
# Expected: active (running) + enabled

# STEP 7: Confirm port 8083 is bound
sudo ss -tlnp | grep 8083
# Expected: java process listening on 8083

# STEP 8: Test application responds
curl http://stapp03:8083
# Expected: HTML response — no connection refused, no 404

# ─────────────────────────────────────────
# DEBUGGING (if needed)
# ─────────────────────────────────────────
# Check deployment logs
sudo tail -50 /var/log/tomcat/catalina.out

# Verify WAR was exploded
sudo ls -la /var/lib/tomcat/webapps/

# Check firewall if curl fails but Tomcat is running
sudo firewall-cmd --list-ports
sudo firewall-cmd --permanent --add-port=8083/tcp
sudo firewall-cmd --reload
