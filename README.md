# 🚀 100 Days of AWS & DevOps Challenge

> **Learning in public. Building in production-style. Every single day.**

[![Challenge](https://img.shields.io/badge/Challenge-KodeKloud%20100%20Days-orange?style=for-the-badge)](https://kodekloud.com)
[![Status](https://img.shields.io/badge/Status-In%20Progress-brightgreen?style=for-the-badge)]()
[![Days Completed](https://img.shields.io/badge/Days%20Completed-38%2F100-blue?style=for-the-badge)]()
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
| **Phase 1** | Linux, Bash Scripting, Networking Fundamentals | 1–15 | ✅ Complete |
| **Phase 2** | Docker & Containerization | 16–30 | ✅ Complete |
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
| [Day 06](./days/day-06/README.md) | Linux Task Scheduling | Installed `cronie`, started `crond`, and added root cron job (`*/5 * * * *`) on all 3 App Servers | ✅ |
| [Day 07](./days/day-07/README.md) | SSH / Access Management | Configured passwordless SSH from `thor` (jump host) to all 3 App Servers via `ssh-keygen` + `ssh-copy-id` | ✅ |
| [Day 08](./days/day-08/README.md) | Configuration Management / Ansible | Installed `ansible==4.10.0` globally on jump host via `sudo pip3` — accessible to all users | ✅ |
| [Day 09](./days/day-09/README.md) | Incident Response / MariaDB | Diagnosed and restored MariaDB service on DB server — root cause analysis + `systemctl enable` | ✅ |
| [Day 10](./days/day-10/README.md) | Bash Scripting / Backup Automation | Wrote `news_backup.sh` — zip archive + local save + passwordless SCP to storage server | ✅ |
| [Day 11](./days/day-11/README.md) | Application Server / Tomcat | Installed Tomcat on App Server 3, configured port `8083`, deployed `ROOT.war` to base URL | ✅ |
| [Day 12](./days/day-12/README.md) | Linux Networking / Apache / Firewall | Four-layer diagnosis: Apache config + firewall + SELinux — restored service on port `6300` | ✅ |
| [Day 13](./days/day-13/README.md) | Linux Security / iptables | Installed iptables, whitelisted LBR (`172.16.238.14`) on port `6000`, blocked all others — rules persisted | ✅ |
| [Day 14](./days/day-14/README.md) | Apache / Fleet Operations | Fleet-wide triage, identified faulty server, fixed Apache and configured port `3002` on all 3 app servers | ✅ |
| [Day 15](./days/day-15/README.md) | nginx / SSL/TLS | Installed nginx, deployed self-signed SSL cert, configured HTTPS — Phase 1 complete 🏁 | ✅ |
| [Day 16](./days/day-16/README.md) | Load Balancing / nginx | Configured nginx as LBR on `stlb01` with upstream pool across all 3 app servers — Phase 2 begins 🚀 | ✅ |
| [Day 17](./days/day-17/README.md) | Database Administration / PostgreSQL | Created user `kodekloud_rin`, database `kodekloud_db2`, granted full privileges — no service restart | ✅ |
| [Day 18](./days/day-18/README.md) | Database Administration / MariaDB | Installed MariaDB, created `kodekloud_db8`, user `kodekloud_tim` with full privileges | ✅ |
| [Day 19](./days/day-19/README.md) | Web Server / Apache | Path-based multi-site hosting — `blog` and `apps` served on port `5002` from single Apache instance | ✅ |
| [Day 20](./days/day-20/README.md) | nginx / PHP-FPM / Application Stack | nginx on port `8098` + PHP-FPM 8.2 via Unix socket `/var/run/php-fpm/default.sock` — full PHP stack | ✅ |
| [Day 21](./days/day-21/README.md) | Version Control / Git | Installed `git`, created bare repository `/opt/official.git` on Storage Server | ✅ |
| [Day 22](./days/day-22/README.md) | Version Control / Git | Cloned `/opt/beta.git` to `/usr/src/kodekloudrepos/beta` as `natasha` — no permission changes | ✅ |
| [Day 23](./days/day-23/README.md) | Version Control / Gitea | Forked `sarah/story-blog` into `jon` account on self-hosted Gitea server | ✅ |
| [Day 24](./days/day-24/README.md) | Version Control / Git | Created branch `xfusioncorp_beta` from `master` in `/usr/src/kodekloudrepos/beta` | ✅ |
| [Day 25](./days/day-25/README.md) | Version Control / Git | Full workflow: branch → add `index.html` → commit → merge → push both branches to origin | ✅ |
| [Day 26](./days/day-26/README.md) | Version Control / Git | Added `dev_news` remote → committed `index.html` → pushed `master` to new remote | ✅ |
| [Day 27](./days/day-27/README.md) | Version Control / Git | Reverted HEAD to `initial commit` using `git revert` — commit message `revert games` | ✅ |
| [Day 28](./days/day-28/README.md) | Version Control / Git | Cherry-picked `Update info.txt` commit from `feature` branch into `master` — pushed to origin | ✅ |
| [Day 29](./days/day-29/README.md) | Version Control / Gitea / PR Workflow | Full PR lifecycle: max pushed branch → PR created → tom reviewed & approved → merged to master | ✅ |
| [Day 30](./days/day-30/README.md) | Version Control / Git | `git reset --hard` to `add data.txt file` + force push — history cleaned to 2 commits — Phase 2 🏁 | ✅ |
| [Day 31](./days/day-31/README.md) | Version Control / Git | Applied `stash@{1}` using `git stash apply`, committed and pushed to origin | ✅ |
| [Day 32](./days/day-32/README.md) | Version Control / Git | Rebased `feature` branch onto `master` — linear history, no merge commit, force pushed | ✅ |
| [Day 33](./days/day-33/README.md) | Version Control / Git | Resolved push rejection + merge conflict in `story-index.txt` — fixed typo, all 4 stories present | ✅ |
| [Day 34](./days/day-34/README.md) | Git Hooks / Automation | Created `post-update` hook for auto release tagging on master push — `release-2026-04-16` created | ✅ |
| [Day 35](./days/day-35/README.md) | Containerization / Docker | Installed `docker-ce` + `docker-compose-plugin` on App Server 3 — service started and enabled | ✅ |
| [Day 36](./days/day-36/README.md) | Containerization / Docker | Deployed `nginx:alpine` container named `nginx_1` on App Server 1 — running state verified | ✅ |
| [Day 37](./days/day-37/README.md) | Containerization / Docker | Copied encrypted file `/tmp/nautilus.txt.gpg` from host to `ubuntu_latest` container — integrity verified with `md5sum` | ✅ |
| [Day 38](./days/day-38/README.md) | Containerization / Docker | Pulled `busybox:musl` image and re-tagged as `busybox:blog` — same Image ID, no duplication | ✅ |
| Day 39 | — | Coming Soon | — |

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
  <strong>Day 38 of 100 — The journey starts now.</strong><br/>
  <em>Built with consistency, not perfection.</em>
</p>
