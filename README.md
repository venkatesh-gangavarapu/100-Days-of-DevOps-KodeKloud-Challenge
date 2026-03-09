# 🚀 100 Days of AWS & DevOps Challenge

> **Learning in public. Building in production-style. Every single day.**

[![Challenge](https://img.shields.io/badge/Challenge-KodeKloud%20100%20Days-orange?style=for-the-badge)](https://kodekloud.com)
[![Status](https://img.shields.io/badge/Status-In%20Progress-brightgreen?style=for-the-badge)]()
[![Days Completed](https://img.shields.io/badge/Days%20Completed-0%2F100-blue?style=for-the-badge)]()
[![LinkedIn](https://img.shields.io/badge/Follow%20Journey-LinkedIn-0077B5?style=for-the-badge&logo=linkedin)](https://www.linkedin.com/in/venkatesh-gangavarapu)

---

## 👋 About This Challenge

This repository documents my **100-day hands-on AWS & DevOps journey** through [KodeKloud's free challenge](https://kodekloud.com).

The goal isn't just to complete tasks — it's to approach each day the way you would in a real engineering team: understand the *why*, not just the *how*, and document it well enough that someone else could learn from it too.

Every day includes:
- ✅ What was built or configured
- 🔍 Key concepts applied
- 🧱 Real-world production context
- ⚠️ What broke and how it was fixed
- 📎 References and further reading

---

## 🗺️ Roadmap Overview

| Phase | Topics | Days | Status |
|-------|--------|------|--------|
| **Phase 1** | Linux, Bash Scripting, Networking Fundamentals | 1–15 | 🟡 In Progress |
| **Phase 2** | Docker & Containerization | 16–30 | 🔜 Upcoming |
| **Phase 3** | Kubernetes & Orchestration | 31–45 | 🔜 Upcoming |
| **Phase 4** | AWS Core Services (EC2, S3, VPC, IAM) | 46–60 | 🔜 Upcoming |
| **Phase 5** | CI/CD Pipelines (GitHub Actions, Jenkins) | 61–70 | 🔜 Upcoming |
| **Phase 6** | Infrastructure as Code (Terraform) | 71–80 | 🔜 Upcoming |
| **Phase 7** | Monitoring & Observability | 81–90 | 🔜 Upcoming |
| **Phase 8** | Security, IAM Best Practices & Final Projects | 91–100 | 🔜 Upcoming |

---

## 📅 Daily Log

| Day | Topic | Summary | Notes |
|-----|-------|---------|-------|
| [Day 01](./days/day-01/README.md) | Non-Interactive Shell User | Created user `rose` with `/sbin/nologin` on App Server 1 | ✅ |
| [Day 02](./days/day-02/README.md) | Linux User Management | Created temporary user `anita` with account expiry `2027-01-28` on App Server 2 | ✅ |
| [Day 03](./days/day-03/README.md) | Linux Security Hardening | Disabled direct SSH root login on all 3 App Servers — `PermitRootLogin no` | ✅ |
| [Day 04](./days/day-04/README.md) | Linux File Permissions | Granted execute permissions (`chmod 755`) to backup script for all users on App Server 2 | ✅ |
| [Day 05](./days/day-05/README.md) | Linux Security / SELinux | Installed SELinux packages and permanently disabled via `/etc/selinux/config` on App Server 3 | ✅ |
| Day 06 | — | Coming Soon | — |

> 📌 This table updates daily. Each day links to a dedicated folder with full notes, commands, and screenshots.

---

## 📁 Repository Structure

```
100-days-devops-challenge/
│
├── README.md                  # You are here
├── days/
│   ├── day-01/
│   │   ├── README.md          # Daily notes & learnings
│   │   ├── commands.sh        # Commands used that day
│   │   └── screenshots/       # Terminal or console screenshots
│   ├── day-02/
│   └── ...
│
├── projects/                  # Mini-projects built during the challenge
│   └── ...
│
└── resources/
    └── references.md          # Useful links, docs, cheat sheets
```

---

## 🛠️ Tools & Technologies

![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat-square&logo=linux&logoColor=black)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=flat-square&logo=amazon-aws&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat-square&logo=terraform&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat-square&logo=github-actions&logoColor=white)
![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=flat-square&logo=jenkins&logoColor=white)

---

## 🎯 Why I'm Doing This in Public

I've seen too many engineers treat learning as something you do privately, then show up with a certificate. That's fine — but it misses something.

**Doing this in public means:**
- Every mistake is documented and learned from, not hidden
- Other engineers at any stage can follow along and benefit
- The work speaks for itself — no need to oversell it on a resume

If you're early in your DevOps journey, **fork this repo and run the challenge yourself.** The best time to start was yesterday. The second best time is now.

---

## 📬 Connect & Follow Along

- 💼 [LinkedIn](https://www.linkedin.com/in/venkatesh-gangavarapu) — Daily posts throughout the challenge
- 🐙 [GitHub](https://github.com/venkatesh-gangavarapu) — All code and notes live here

---

## ⭐ Support

If this repo is helping you or inspiring you to start your own journey — **drop a star.** It costs nothing and it means a lot.

---

<p align="center">
  <strong>Day 5 of 100 — The journey starts now.</strong><br/>
  <em>Built with consistency, not perfection.</em>
</p>
