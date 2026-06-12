#!/bin/bash
# Day 68 — Jenkins Installation on Jenkins Server
# Challenge: KodeKloud 100 Days of DevOps — Phase 5
# Task: Install Jenkins via apt, start with service, create admin user

# ─────────────────────────────────────────
# From Jump Host → SSH into Jenkins server
# ssh root@jenkins    (Password: S3curePass)
# ─────────────────────────────────────────

# STEP 1: Update package list
apt update

# STEP 2: Install Java (Jenkins requires JRE)
apt install -y fontconfig openjdk-21-jre
java -version
# Expected: openjdk version "21.x.x"

# STEP 3: Add Jenkins apt repository key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
  tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# STEP 4: Add Jenkins apt repository
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | \
  tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# STEP 5: Update and install Jenkins
apt update
apt install -y jenkins
# Expected: Setting up jenkins ... done

# STEP 6: Start Jenkins service
service jenkins start
service jenkins status
# Expected: Active: active (running)

# If timeout — check logs:
# cat /var/log/jenkins/jenkins.log | tail -50

# STEP 7: Get initial admin password for UI setup
cat /var/lib/jenkins/secrets/initialAdminPassword
# Copy this password for the Jenkins UI setup

# ─────────────────────────────────────────
# JENKINS UI SETUP (browser)
# ─────────────────────────────────────────
# 1. Click Jenkins button on top bar
# 2. Paste initial admin password
# 3. Install suggested plugins
# 4. Create admin user:
#    Username:  theadmin
#    Password:  Adm!n321
#    Full name: Yousuf
#    Email:     yousuf@jenkins.stratos.xfusioncorp.com
# 5. Set Jenkins URL (accept default)
# 6. Start using Jenkins ✅
