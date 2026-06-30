# Day 76 — Jenkins Per-Job Permissions: Granular Access Control for Packages Job

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** CI/CD / Jenkins / Security / RBAC  
**Difficulty:** Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

Grant granular per-job permissions to two users on the existing `Packages` job:

| User | Password | Permissions |
|------|----------|------------|
| `sam` | `sam@pass12345` | Build, Configure, Read |
| `rohan` | `rohan@pass12345` | Build, Cancel, Configure, Read, Update, Tag |

**Inheritance Strategy:** Inherit permissions from parent ACL

---

## 🧠 Concept — Project-Based Permission Inheritance

### Inheritance Strategies — What Each Does

When project-based security is enabled on a job, you choose how the job's permission matrix relates to the global matrix:

| Strategy | Behavior |
|----------|---------|
| **Inherit permissions from parent ACL** | Job permissions ADD to whatever the user already has from the global matrix. A user with global `Overall/Read` plus job `Job/Build` can read Jenkins AND build this job. |
| **Inherit global ACL** | Similar to parent — inherits from the global (top-level) matrix. |
| **Do not inherit permission from other ACLs** | Job-level matrix is standalone — users only have the permissions explicitly listed here, nothing from global. Useful for complete isolation. |

Today's task requires **"Inherit permissions from parent ACL"** — the most common production choice. It layers job-level grants on top of global grants rather than replacing them.

### Sam vs Rohan — Permission Difference Analysis

```
Both get:    Build, Configure, Read (can trigger, modify, and view)
Rohan adds:  Cancel (stop running builds)
             Update  (update job description/metadata)
             Tag     (create Git tags from the build)
```

The principle: Rohan is a more senior developer — trusted with additional destructive capabilities (cancel, which can interrupt in-progress deployments) and release-related capabilities (tag, which creates permanent Git markers).

### All Jenkins Job Permission Types

| Permission | What it allows |
|-----------|---------------|
| **Build** | Trigger new builds manually |
| **Cancel** | Abort a running or queued build |
| **Configure** | Modify job configuration |
| **Delete** | Delete the job entirely |
| **Discover** | See the job exists (even without Read) |
| **Move** | Move job to a different folder |
| **Read** | View job page, build history, configuration |
| **Tag** | Create tags (SCM tagging from build) |
| **Update** | Update job descriptions, properties |
| **Workspace** | Browse/wipe build workspace |

> **Real-world context:** Per-job permission matrices are the standard approach for multi-team Jenkins instances where different teams own different jobs. The ops team owns deployment jobs (full permissions), developers own their CI jobs (Build/Read), auditors get Read-only access to specific compliance jobs, and release managers get Tag permissions for release pipelines. This granular model prevents accidental or unauthorized modification of critical jobs while still enabling the right people to do their work.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Jenkins access | UI (top bar button) |
| Login | `admin` / `Adm!n321` |
| Target job | `Packages` |
| sam | Build, Configure, Read |
| rohan | Build, Cancel, Configure, Read, Update, Tag |
| Inheritance | Inherit permissions from parent ACL |

---

## 🔧 Solution — Step by Step

### Step 1: Login and navigate to Packages job

```
Dashboard → Packages → Configure
```

### Step 2: Enable project-based security

```
General → ☑ Enable project-based security
```

### Step 3: Set inheritance strategy

```
Inheritance Strategy: ● Inherit permissions from parent ACL
```

### Step 4: Add sam with correct permissions

```
Add user → sam → Add
  ☑ Job/Build
  ☑ Job/Configure
  ☑ Job/Read
  (all others unchecked)
```

### Step 5: Add rohan with correct permissions

```
Add user → rohan → Add
  ☑ Job/Build
  ☑ Job/Cancel
  ☑ Job/Configure
  ☑ Job/Read
  ☑ Job/Update
  ☑ Job/Tag
  (Delete, Discover, Move, Workspace unchecked)
```

### Step 6: Save

```
→ Save
```

### Step 7: Verify

```
Log in as sam / sam@pass12345
  - Packages job visible ✅
  - Build Now present ✅
  - Configure accessible ✅
  - No Delete option ✅

Log in as rohan / rohan@pass12345
  - All sam permissions ✅
  - Can cancel builds ✅
  - Tag and Update available ✅
```

---

## 📌 Permission Matrix

```
Permission     | sam | rohan | Notes
Job/Build      |  ✅ |   ✅  | Trigger builds
Job/Cancel     |  ❌ |   ✅  | Abort running builds
Job/Configure  |  ✅ |   ✅  | Modify job settings
Job/Delete     |  ❌ |   ❌  | Neither can delete
Job/Read       |  ✅ |   ✅  | View job/history
Job/Tag        |  ❌ |   ✅  | Create SCM tags
Job/Update     |  ❌ |   ✅  | Update metadata
Job/Workspace  |  ❌ |   ❌  | Browse workspace
```

---

## ⚠️ Common Mistakes to Avoid

1. **Wrong inheritance strategy** — The task specifically requires "Inherit permissions from parent ACL." Selecting "Do not inherit" means users may lose access they should have from global settings.
2. **Checking permissions not in the list** — sam should NOT get Cancel, Tag, or Update. Only check exactly what's listed. Extra permissions fail the validation criteria.
3. **Modifying other jobs** — The task says "do not modify any other existing job configuration." Only touch the `Packages` job.
4. **Typing usernames wrong** — "sam" and "rohan" must match existing users exactly (lowercase). A typo creates a grant for a non-existent user.
5. **Forgetting to enable "Enable project-based security"** — Without this checkbox, the job uses the global matrix for all users. The per-job matrix is only active when this checkbox is checked.
6. **Not verifying by logging in as the users** — Always test the configuration actually works as expected. Admin's view doesn't reflect what the restricted users see.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between the three inheritance strategies in Jenkins project-based security?**

"Inherit permissions from parent ACL" means the job's permission matrix adds to the user's existing global permissions — a user with no global job access but a job-level `Job/Read` grant can see this specific job. "Inherit global ACL" is functionally similar, inheriting from the top-level global matrix. "Do not inherit permission from other ACLs" makes the job-level matrix standalone — users have only the permissions explicitly listed in the job configuration, regardless of global settings. The standalone option provides complete isolation and is useful when a job should be accessible only to specific users and hidden from everyone else, even those with broad global access.

---

**Q2: Why would you give a user `Job/Configure` without `Job/Delete`?**

This follows the principle of least privilege — allowing modification without allowing destruction. A developer with `Configure` can update the job's build steps, parameters, SCM settings, triggers, and post-build actions. They can iterate on and improve the job. `Delete` is an irreversible action — once a job is deleted, its history and configuration are gone (unless backed up). Separating these means developers can fully own their build configuration without the risk of accidental or impulsive deletion. In practice, `Job/Delete` is typically restricted to team leads, the ops team, or admins. For critical production deployment jobs, sometimes not even team leads have Delete — only the Jenkins admin can remove them.

---

**Q3: What does `Job/Tag` permission enable and why is it restricted?**

`Job/Tag` allows creating Source Control Management tags from within a Jenkins build — Jenkins can automatically create a Git tag (e.g., `release-1.2.3`) on the repository after a successful build. Tagging is a release action — it marks a specific commit as a versioned release in the Git history, permanently. Allowing developers to create tags arbitrarily can pollute the repository with spurious tags or create tags that conflict with release processes. Restricting `Job/Tag` to senior developers or release managers (like Rohan in this task) ensures tags are created intentionally as part of a release workflow, not accidentally by someone testing the build.

---

**Q4: How does `Job/Cancel` differ from not having it, and when is it important?**

Without `Job/Cancel`, a user can trigger a build but cannot stop it once running — even if they realize it was triggered incorrectly or is stuck. With `Job/Cancel`, they can abort in-progress builds and remove queued builds. This matters for deployment jobs: if a developer triggers a production deployment and immediately realizes it's the wrong branch, `Job/Cancel` lets them abort before it completes. Without it, they'd need to contact an admin to intervene. The risk: `Job/Cancel` can also be used to interfere with others' builds if misused. For collaborative pipelines, granting it to developers on their own team's jobs is reasonable; for shared infrastructure jobs, it's typically restricted.

---

**Q5: How would you audit who has what permissions on Jenkins jobs in a large installation?**

Jenkins doesn't have a built-in "show all permissions for all users" view — you'd need to check each job's configuration individually, which doesn't scale. Options: (1) **Script Console** — `Manage Jenkins → Script Console` allows Groovy scripting against the Jenkins model. A script can iterate all jobs and their permission configurations and output a report. (2) **Role Strategy plugin** (alternative to Matrix Authorization) — uses named roles assigned to users, making the "who has what" question answerable by listing role definitions. (3) **Jenkins Configuration as Code (JCasC)** — if all configuration is declared in YAML and stored in Git, the access control model is fully auditable in version control. (4) **Audit Trail plugin** — logs who changed what configuration and when, providing change history rather than current state snapshot.

---

**Q6: How would this per-job security model scale for a large organization with hundreds of jobs and dozens of users?**

It doesn't scale well as individual per-job matrices — maintaining hundreds of independent permission tables becomes unmanageable. The production approach: **Role-Based Authorization Strategy plugin**. Instead of per-user, per-job matrices, you define named roles (`developer`, `senior-developer`, `release-manager`, `viewer`) with specific permission sets. Users are assigned to roles globally or per-project. A new hire gets the `developer` role — immediately has appropriate access to all jobs configured for that role. Senior developers get promoted to `senior-developer` role and gain Cancel/Tag/Update across all relevant jobs. This role-based model reduces the maintenance overhead from O(users × jobs) to O(roles + assignments), making it practical for large organizations.

---

## 🔗 References

- [Jenkins Project-Based Matrix Authorization](https://plugins.jenkins.io/matrix-auth/)
- [Jenkins Authorization](https://www.jenkins.io/doc/book/security/access-control/authorization/)
- [Role Strategy Plugin](https://plugins.jenkins.io/role-strategy/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
