# Day 70 — Jenkins User Management & Matrix Authorization Strategy

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** CI/CD / Jenkins / Security / RBAC  
**Difficulty:** Intermediate  
**Phase:** Phase 5 — Advanced Kubernetes & CI/CD  
**Status:** ✅ Completed

---

## 📋 Task Summary

Configure Jenkins access control:
1. Create user `jim` (password `BruCStnMT5`, full name `Jim`)
2. Enable **Project-based Matrix Authorization Strategy**
3. Grant `jim` only **Overall Read** permission globally
4. Remove all permissions from **Anonymous**, keep `admin` as full Administer
5. On the existing job, grant `jim` **Read-only** access (no Build/Configure/etc.)

---

## 🧠 Concept — Jenkins Authorization Models

### Authorization Strategy Options

| Strategy | Granularity | Use case |
|----------|-------------|---------|
| **Anyone can do anything** | None | Never use in production |
| **Legacy mode** | Admin vs everyone | Deprecated |
| **Logged-in users can do anything** | Authenticated vs anonymous | Small trusted teams |
| **Matrix Authorization Strategy** | Global, per-permission | Mid-size teams, role separation |
| **Project-based Matrix Authorization Strategy** | Global + per-job override | Multi-team Jenkins, fine-grained control |

Today's task uses **Project-based Matrix Authorization Strategy** — the most granular built-in option. It allows global permissions (who can see Jenkins at all, who's admin) AND per-job overrides (this specific job, this specific user, these specific permissions).

### Permission Categories in the Matrix

```
Overall:        Read, Administer, RunScripts, ...
Credentials:    Create, Delete, Update, View, ManageDomains
Agent:          Build, Configure, Connect, Create, Delete, ...
Job:            Build, Cancel, Configure, Create, Delete,
                Discover, Move, Read, Tag, Workspace
Run:            Delete, Replay, Update
SCM:            Tag
View:           Configure, Create, Delete, Read
```

For `jim`, the task requires **only** `Overall/Read` globally and **only** `Job/Read` on the specific job — every other checkbox stays unchecked.

### Why "Overall Read" Alone Isn't Enough for Job Visibility

`Overall/Read` lets a user log in and see the Jenkins dashboard shell, but without `Job/Read` on a specific job (either globally or via project-based override), that job is invisible to them. This task layers both: global `Overall/Read` (can log in) + job-level `Job/Read` (can see this specific job).

### The Anonymous User Risk

By default, many Jenkins setups (especially with simpler authorization strategies) grant `Anonymous` some read access — meaning anyone who can reach the Jenkins URL, without logging in, can view jobs, build history, even configuration in some cases. Explicitly zeroing out every Anonymous permission closes this exposure entirely — unauthenticated visitors see nothing but a login prompt.

### The Admin Lockout Risk

The single most common mistake when configuring Matrix Authorization: forgetting to grant the admin account `Administer` before saving. Once Project-based Matrix Authorization is active, if no user has Administer permission, **nobody can access Jenkins configuration anymore** — including via the UI. Recovery requires editing `config.xml` directly on the server filesystem. Always verify the current admin account has Administer checked before clicking Save.

> **Real-world context:** Project-based Matrix Authorization is the standard approach for Jenkins instances shared across multiple teams. A platform team might have Administer; individual developers get Job/Build and Job/Read on their team's jobs only; auditors or stakeholders get Job/Read across the board with no build/configure rights. This task's pattern — locked-down Anonymous, minimal-privilege named users, admin retains full control — is the textbook secure Jenkins configuration.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Jenkins access | UI (top bar button) |
| Admin login | `admin` / `Adm!n321` |
| New user | `jim` / `BruCStnMT5`, full name `Jim` |
| Authorization strategy | Project-based Matrix Authorization Strategy |
| `jim` global permission | Overall/Read only |
| `jim` job permission | Job/Read only (on existing job) |
| Anonymous | All permissions removed |
| `admin` | Retains Overall/Administer |

---

## 🔧 Solution — Step by Step

### Step 1: Login and create user jim

```
Manage Jenkins → Users → Create User
  Username:  jim
  Password:  BruCStnMT5
  Full name: Jim
→ Create User
```

### Step 2: Install Matrix Authorization Strategy plugin (if needed)

```
Manage Jenkins → Plugins → Available plugins
  Search: "Matrix Authorization Strategy" → check it
→ Install
→ ☑ Restart Jenkins when installation is complete
   and no jobs are running
→ WAIT for login page to reappear
→ Log back in
```

### Step 3: Configure global Matrix Authorization

```
Manage Jenkins → Security
  Authorization: ● Project-based Matrix Authorization Strategy

  admin row:    ☑ Overall/Administer  (grants everything)
  jim row:      ☑ Overall/Read only
  Anonymous row: (uncheck everything)

⚠️ Verify admin = Administer BEFORE saving
→ Save
```

### Step 4: Configure job-level permissions for jim

```
[existing job] → Configure
  ☑ Enable project-based security

  jim row: ☑ Job/Read only
           (Build, Configure, Delete, etc. all unchecked)
→ Save
```

### Step 5: Verify

```
Log out → log in as jim/BruCStnMT5
  - Can see Dashboard ✅
  - Can see the job ✅
  - Cannot Build/Configure/Delete the job ✅

Open incognito window (anonymous)
  - Redirected to login, no content visible ✅

Log back in as admin
  - Full access retained ✅
```

---

## 📌 Verification Checklist

```
☑ User "jim" created with correct password and full name
☑ Matrix Authorization Strategy plugin installed (if needed)
☑ Project-based Matrix Authorization Strategy enabled globally
☑ admin retains Overall/Administer
☑ jim has ONLY Overall/Read globally
☑ Anonymous has ZERO permissions
☑ Existing job has project-based security enabled
☑ jim has ONLY Job/Read on that job (no Build/Configure/etc.)
☑ Verified by logging in as jim
☑ Verified admin still has full access after save
```

---

## ⚠️ Common Mistakes to Avoid

1. **Locking yourself out** — Forgetting to check `Administer` for `admin` before saving the global security config. Always double-check this row before clicking Save.
2. **Granting jim extra permissions "just in case"** — The task specifies Read only. Checking Build or Configure for jim fails the grading criteria even if functionally harmless.
3. **Leaving Anonymous with any permission checked** — Even a single checkbox like `Overall/Read` for Anonymous defeats the purpose of locking it down.
4. **Confusing global Read with job-level Read** — `jim` needs both: Overall/Read (to log in and see the UI shell) AND Job/Read on the specific job (to actually see that job's page). One without the other results in jim seeing an empty dashboard.
5. **Not waiting for full Jenkins restart** — After installing the plugin, navigating away or refreshing before the login page reappears can cause UI inconsistencies.

---

## 🔍 Matrix Authorization Permission Inheritance

```
Global Matrix (Manage Jenkins → Security):
  jim: Overall/Read  ← baseline, applies everywhere

Job-level Matrix (with "Enable project-based security"):
  jim: Job/Read       ← additional grant, specific to THIS job

Effective permissions for jim on this job:
  Overall/Read (global) + Job/Read (job-specific) = can view job, nothing else

For OTHER jobs without project-based security enabled:
  jim only has whatever the global matrix grants (Overall/Read)
  → jim likely cannot see those other jobs' details at all
```

Project-based security at the job level **adds to** the global matrix — it doesn't replace it. This layered model is what enables "this specific team can access this specific job" patterns at scale.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between Matrix Authorization Strategy and Project-based Matrix Authorization Strategy?**

Matrix Authorization Strategy applies one global permission matrix to the entire Jenkins instance — every user's permissions are the same across all jobs. Project-based Matrix Authorization Strategy extends this by allowing individual jobs to define their own additional permission matrix ("Enable project-based security" checkbox in job configuration), layered on top of the global matrix. This enables scenarios like: a user has no permissions globally, but is granted Build/Read on one specific job they're responsible for. For Jenkins instances shared across multiple teams, project-based is almost always the right choice because it supports per-team, per-job access control without needing separate Jenkins instances.

---

**Q2: Why is it dangerous to leave Anonymous users with any permission in a production Jenkins instance?**

Anonymous represents anyone who can reach the Jenkins URL without authenticating — which, depending on network exposure, could be the entire internet. Even seemingly harmless permissions like `Overall/Read` let unauthenticated visitors see job names, build history, console output (which often contains environment details, partial logs, sometimes accidentally exposed secrets), and the list of configured jobs — valuable reconnaissance information for an attacker. Production Jenkins instances should have zero Anonymous permissions, forcing every interaction through authentication, and ideally sit behind a VPN or internal network rather than being publicly reachable at all.

---

**Q3: What happens if you save a Matrix Authorization configuration with no user granted Administer permission?**

You lock yourself out of the Jenkins UI's configuration screens entirely — there's no way to navigate to Manage Jenkins → Security to fix it because doing so requires Administer permission, which nobody has. Recovery requires direct server access: stopping Jenkins, manually editing `$JENKINS_HOME/config.xml` to either revert the authorization strategy to "Logged-in users can do anything" or add back an Administer grant, then restarting Jenkins. This is why every experienced Jenkins administrator triple-checks the admin row before saving any authorization strategy change — it's one of the most common and most painful Jenkins misconfigurations.

---

**Q4: How would you grant a CI/CD pipeline service account minimal permissions to trigger builds without full admin access?**

Create a dedicated Jenkins user (or API token) for the service account — never use a human admin's credentials for automation. In the Matrix Authorization table, grant this service account only the specific permissions needed: `Overall/Read` (to authenticate), `Job/Build` (to trigger builds), and possibly `Job/Read` (to check build status) — scoped to the specific jobs it needs to trigger, using project-based security on those jobs. Avoid granting `Job/Configure` or `Job/Delete` since the automation never needs to modify job definitions, only trigger them. This follows the principle of least privilege — the blast radius of a compromised service account credential is limited to triggering builds on specific jobs, not modifying Jenkins configuration.

---

**Q5: What is the difference between `Overall/Read` and `Job/Read` permissions?**

`Overall/Read` is a global permission that allows a user to log into Jenkins and see the basic UI shell — the dashboard, navigation, their own user settings. Without any `Job/Read` permission (either globally or per-job via project-based security), the user sees an empty dashboard with no jobs listed, even though they're successfully authenticated. `Job/Read` (whether granted globally in the matrix or specifically per-job) is what actually makes individual job entries visible and accessible. This separation lets administrators grant broad login access while still controlling exactly which jobs each user can see — useful for onboarding new team members with access only to their team's specific jobs.

---

**Q6: How would you audit who has access to what in a Jenkins instance with many users and jobs?**

Use the **Audit Trail plugin** to log every configuration change, including who modified permissions and when. For reviewing current state: `Manage Jenkins → Security` shows the global matrix; each job's `Configure` page shows its project-based overrides if enabled. For larger Jenkins instances, the **Role-based Authorization Strategy** plugin (an alternative to Matrix) groups permissions into named roles (e.g., "developer", "viewer", "admin") and assigns users to roles — this is more maintainable at scale than per-user matrix checkboxes because you update one role definition instead of every individual user's row. For very large organizations, integrating Jenkins authentication with LDAP/SSO and mapping group membership to Jenkins roles automates access provisioning entirely.

---

## 🔗 References

- [Jenkins Authorization](https://www.jenkins.io/doc/book/security/access-control/authorization/)
- [Matrix Authorization Strategy Plugin](https://plugins.jenkins.io/matrix-auth/)
- [Jenkins Security Best Practices](https://www.jenkins.io/doc/book/security/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
