# Day 29 — The Complete Pull Request Workflow: Branch Protection & Code Review

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Version Control / Git / Gitea / Code Review  
**Difficulty:** Intermediate  
**Phase:** Phase 2 — Infrastructure & Networking  
**Status:** ✅ Completed

---

## 📋 Task Summary

Implement a proper code review workflow for the `story-blog` repository:

1. Verify max's branch `story/fox-and-grapes` exists on the remote
2. Create a Pull Request from `story/fox-and-grapes` → `master` with title `Added fox-and-grapes story`
3. Assign `tom` as a reviewer
4. Log in as `tom`, review and approve the PR
5. Merge the PR into master

---

## 🧠 Concept — Pull Requests & Branch Protection

### Why Direct Pushes to Master Are Dangerous

`master` (or `main`) is the production-ready branch — the code that's actually running. Allowing anyone to push directly to it means:

- Unreviewed code goes live immediately
- No second set of eyes catches bugs
- No audit trail of who approved what
- One bad push can break production for everyone

### The PR Workflow Solution

```
Developer (max)                 Reviewer (tom)              master
      │                               │                        │
      │── push story/fox-and-grapes   │                        │
      │                               │                        │
      │── Create PR ─────────────────►│                        │
      │   (story/fox-and-grapes        │                        │
      │    → master)                  │                        │
      │                               │── Review changes       │
      │                               │── Approve PR           │
      │                               │── Merge ──────────────►│
      │                                                        │
      │                                        master now has max's story ✅
```

### What a Pull Request Actually Is

A Pull Request is NOT a Git feature — it's a **platform feature** (Gitea, GitHub, GitLab, Bitbucket). Git itself only knows about commits and branches. The PR is a web UI construct that:

- Shows the diff between two branches
- Provides a threaded discussion for code review comments
- Tracks review approvals
- Enforces required reviewers before merge is allowed
- Creates an audit log of who reviewed and approved

### Branch Protection Rules (Production Reality)

In real organizations, `master`/`main` is protected with rules like:

| Rule | Effect |
|------|--------|
| Require PR before merging | No direct pushes allowed |
| Require X approvals | Minimum number of reviewers must approve |
| Require status checks | CI/CD tests must pass before merge |
| Restrict who can merge | Only senior engineers or leads |
| Require linear history | No merge commits — squash or rebase only |

> **Real-world context:** Every mature engineering team uses protected branches and PR workflows. GitHub calls them Branch Protection Rules, GitLab calls them Protected Branches, Gitea has the same concept. As a DevOps engineer, you'll configure these rules when setting up repositories, onboarding teams, and building CI/CD pipelines. The PR workflow is also what GitHub Actions, GitLab CI, and Jenkins pipelines trigger on — a push to a PR branch kicks off tests, and the pipeline result appears as a status check on the PR.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Storage Server | `ststor01` |
| Developer | `max` / `Max_pass123` |
| Reviewer | `tom` / `Tom_pass123` |
| Source branch | `story/fox-and-grapes` |
| Target branch | `master` |
| PR title | `Added fox-and-grapes story` |

---

## 🔧 Solution — Step by Step

### Phase 1: Verify on Storage Server

#### Step 1: SSH as max

```bash
ssh max@ststor01
```

#### Step 2: Find and inspect the cloned repository

```bash
ls ~/
cd <repo-directory>
```

#### Step 3: Review commit history

```bash
git log --oneline
```

Confirms Sarah's story is in history along with max's commits.

```bash
git log --format="%h | %an | %ae | %s"
```

Shows: hash | author name | author email | commit message — validates author information as required.

#### Step 4: Confirm max's branch exists on remote

```bash
git branch -a
```

**Expected:**
```
* story/fox-and-grapes
  remotes/origin/master
  remotes/origin/story/fox-and-grapes
```

`origin/story/fox-and-grapes` confirms the branch is pushed to Gitea. ✅

---

### Phase 2: Create Pull Request as max (Gitea UI)

#### Step 5: Log in to Gitea as max

```
Username: max
Password: Max_pass123
```

#### Step 6: Navigate to the repository and create PR

- Click **Pull Requests** tab → **New Pull Request**
- **Base branch (destination):** `master`
- **Compare branch (source):** `story/fox-and-grapes`
- Click **New Pull Request**

#### Step 7: Fill in PR details

- **Title:** `Added fox-and-grapes story`
- Review the diff — confirm max's story file is visible
- Click **Create Pull Request**

#### Step 8: Add tom as reviewer

- On the PR page → right sidebar → **Reviewers** → click gear icon ⚙️
- Search for `tom` → select
- Tom is now assigned as reviewer ✅

📸 **Take a screenshot** of the PR page showing tom as reviewer.

---

### Phase 3: Review and Merge as tom (Gitea UI)

#### Step 9: Log out as max, log in as tom

```
Username: tom
Password: Tom_pass123
```

#### Step 10: Navigate to the PR

- Go to the repository → **Pull Requests** → find `Added fox-and-grapes story`

#### Step 11: Review the changes

- Click **Files Changed** tab — review max's story content
- Add a review comment if desired

#### Step 12: Approve the PR

- Click **Review** button
- Select **Approve**
- Submit review

#### Step 13: Merge the PR

- Click **Merge Pull Request**
- Confirm the merge
- Master now contains max's fox-and-grapes story ✅

📸 **Take a screenshot** of the merged PR page.

---

## 📌 Terminal Commands Reference

```bash
# ─── Verify repository state ─────────────────────────────
ssh max@ststor01
cd ~/                               # find repo directory
git log --oneline                   # commit history
git log --format="%h | %an | %s"    # hash | author | message
git branch -a                       # confirm remote branch exists
git show origin/story/fox-and-grapes # see branch contents

# ─── Useful git log formats ──────────────────────────────
git log --oneline --graph --all     # visual branch diagram
git log --format="%h %an %ae %s"    # hash author email message
git log -1 --format="%s"            # just latest commit message
```

---

## ⚠️ Key Points for This Task

1. **Screenshots are required** — UI tasks need visual evidence. Capture the PR creation, reviewer assignment, and merged state.
2. **PR title must be exact** — `Added fox-and-grapes story` — copy precisely.
3. **Log out between users** — Gitea sessions can persist. Always log out as max before logging in as tom to avoid review being attributed to the wrong user.
4. **Check Files Changed before approving** — In real reviews, always read the diff. Rubber-stamping without reading is how bugs get to production.
5. **The merge creates a merge commit on master** — After the PR merges, master's history includes both the original commits and the merge commit. `git log` on master will show max's story.

---

## 🔍 The PR Lifecycle

```
1. BRANCH    developer pushes feature branch to remote
2. PR OPEN   developer creates PR → source into target
3. REVIEW    reviewer reads diff, leaves comments
4. ITERATE   developer addresses comments, pushes fixes
5. APPROVE   reviewer approves the PR
6. MERGE     PR is merged → target branch updated
7. CLOSE     PR marked as merged, branch can be deleted
```

Each stage is tracked and timestamped — creating a full audit trail of who proposed what, who reviewed it, who approved it, and when it merged.

---

## 🔗 References

- [Gitea — Pull Requests](https://docs.gitea.com/usage/pull-request)
- [GitHub — About Pull Requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)

---

## 💼 Real-World DevOps Q&A

*Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.*

---

**Q1: Your team wants to enforce that every merge to `main` requires at least two approved reviews and all CI checks to pass. How do you configure this in GitHub?**

```bash
# Via GitHub UI: Settings → Branches → Add rule for "main"
# Or via GitHub CLI:
gh api repos/{owner}/{repo}/branches/main/protection \
  --method PUT \
  --field required_pull_request_reviews[required_approving_review_count]=2 \
  --field required_status_checks[strict]=true \
  --field required_status_checks[contexts][]="ci/tests" \
  --field enforce_admins=true
```

> Branch protection rules are the gatekeeper mechanism every mature team uses. Setting `required_approving_review_count=2` means no single engineer can approve their own change unilaterally. `enforce_admins=true` is critical — without it, repository admins can bypass all rules, which defeats the purpose in a compliance context.

---

**Q2: A developer bypassed the PR process by pushing directly to `main`. How does this happen, and how do you prevent it permanently?**

> Direct pushes to protected branches happen when: (1) branch protection rules aren't configured, (2) the pusher has admin privileges and `enforce_admins` is off, or (3) the rule was temporarily disabled and never re-enabled.
>
> Prevention:
> ```bash
> # Gitea: Repository Settings → Branches → Protected Branches
> # Enable "Require pull request" for master/main
> # Check "Restrict push" to no one
>
> # GitHub: enforce_admins: true ensures even admins can't bypass
> # Audit log: Settings → Audit Log to see who disabled protection
> ```
>
> For critical repos, set up an alert (webhook or audit log monitoring) that fires when branch protection rules change — a rule being disabled is a high-severity security event.

---

**Q3: Tom approved the PR without reading the diff. In a production incident, bad code gets merged. What process change prevents this?**

> Rubber-stamp approvals are a real organizational problem. Technical fixes:
>
> 1. **Required number of reviewers > 1** — If two people must approve, the odds both rubber-stamp drop significantly
> 2. **CODEOWNERS files** — Automatically assign domain experts as required reviewers for their areas
> 3. **Review checklists** — PR templates that list items reviewers must verify before approving
> 4. **Dismiss stale reviews** — When new commits are pushed, old approvals are invalidated (reviewers must re-approve)
>
> Process fix: Make review effectiveness a metric. Track incident post-mortems back to which PR introduced the bug and who approved it — accountability through visibility.

---

**Q4: A PR has been open for two weeks with no reviews. How do you handle stale PRs in a large team?**

```bash
# GitHub: Use GitHub Actions to auto-remind reviewers
# .github/workflows/stale-pr.yml
on:
  schedule:
    - cron: '0 9 * * 1'  # Every Monday at 9am
jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/stale@v8
        with:
          stale-pr-message: 'This PR has been inactive for 7 days. Please review or close.'
          days-before-pr-stale: 7
          days-before-pr-close: 14
```

> Stale PRs are a team health indicator — they pile up when reviews aren't prioritized. Automated reminders help, but the real fix is cultural: schedule a daily PR review window, keep PRs small (< 400 lines), and set team agreements on review SLAs (e.g., "reviews within 1 business day").

---

**Q5: After a PR is merged, the feature branch still exists on the remote. How do you clean it up automatically?**

```bash
# GitHub: Repository Settings → "Automatically delete head branches" ✅
# This deletes the feature branch immediately after merge

# Manual cleanup:
git push origin --delete story/fox-and-grapes   # Delete remote branch
git branch -d story/fox-and-grapes              # Delete local branch

# List and clean up all stale remote branches:
git remote prune origin                          # Remove tracking refs for deleted remotes
git branch -r                                    # Confirm cleanup

# Bulk delete merged branches:
git branch --merged main | grep -v main | xargs git branch -d
```

> Accumulated stale branches are a maintenance burden — they clutter `git branch -a` output, make CI slower (if CI runs on all branches), and confuse new team members. Enable auto-delete after merge; developers can always recreate a branch if needed.

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
