# Day 72 — Jenkins Parameterized Build: String & Choice Parameters

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** CI/CD / Jenkins / Parameterized Builds  
**Difficulty:** Beginner  
**Phase:** Phase 5 — Advanced Kubernetes & CI/CD  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create a Jenkins freestyle job `parameterized-job` with:
- String parameter `Stage` (default: `Build`)
- Choice parameter `env` (choices: `Development`, `Staging`, `Production`)
- Shell build step that echoes both parameter values
- Successful build with `env=Production`

**Expected Console Output:**
```
Stage: Build
Environment: Production
```

---

## 🧠 Concept — Jenkins Parameter Types

### Why Parameterized Builds?

Static jobs are single-purpose — run and produce the same output every time. Parameterized jobs are templates — they accept input and behave differently based on what's provided. The same job can deploy to Development, Staging, or Production. The same job can install any package. The same job can build any branch.

```
Without parameters:
  deploy-to-staging    (separate job)
  deploy-to-production (separate job)
  deploy-to-dev        (separate job)

With parameters:
  deploy                ← one job, env parameter selects target
    env: Development
    env: Staging
    env: Production
```

### Jenkins Parameter Types

| Type | UI | Best for |
|------|-----|---------|
| **String** | Text field | Free-text input (package name, branch, version) |
| **Choice** | Dropdown | Fixed set of options (environment, region, action) |
| **Boolean** | Checkbox | Feature flags, skip steps |
| **Password** | Masked field | Credentials (though Credentials plugin is better) |
| **File** | File upload | Config file injection |
| **Multi-line String** | Text area | Multi-line input, lists |

### String vs Choice — When to Use Which

```
String parameter:  When the value is open-ended and user-defined
  e.g. Stage = "Build", "Test", "Release", "Hotfix-v1.2.3"

Choice parameter:  When only specific values should be allowed
  e.g. env = Development | Staging | Production
       (prevents typos, prevents deploying to invalid targets)
```

### Variable Substitution in Shell Steps

In the Execute Shell build step, Jenkins parameter values are available as environment variables — accessed using standard shell syntax:

```bash
echo "Stage: $Stage"        # Standard variable expansion
echo "Stage: ${Stage}"      # Braces form — safer in complex strings
echo "Stage: $Stage"        # Both work identically in simple cases
```

Jenkins sets these before the shell script runs, so they behave exactly like any other environment variable in bash.

> **Real-world context:** Parameterized builds are one of the most useful Jenkins features for keeping job count manageable. A single parameterized pipeline job (deploy, environment, branch, version) replaces what would otherwise be dozens of near-identical jobs. Combined with Choice parameters for environment selection and String parameters for version tags, parameterized Jenkins jobs drive the bulk of real-world CI/CD pipelines.

---

## 🖥️ Environment

| Detail | Value |
|--------|-------|
| Jenkins access | UI (top bar button) |
| Login | `admin` / `Adm!n321` |
| Job name | `parameterized-job` |
| String parameter | `Stage` (default: `Build`) |
| Choice parameter | `env` (Development / Staging / Production) |
| Build step | `echo "Stage: $Stage"` and `echo "Environment: $env"` |
| Test build | `Stage=Build`, `env=Production` |

---

## 🔧 Solution — Step by Step

### Step 1: Create new Freestyle job

```
Dashboard → New Item
  Name: parameterized-job
  Type: Freestyle project
→ OK
```

### Step 2: Add String Parameter

```
General → ☑ This project is parameterized
  → Add Parameter → String Parameter
      Name:          Stage
      Default Value: Build
```

### Step 3: Add Choice Parameter

```
  → Add Parameter → Choice Parameter
      Name: env
      Choices (one per line):
        Development
        Staging
        Production
```

### Step 4: Add Execute Shell build step

```
Build Steps → Add build step → Execute shell
[O  Command:
    echo "Stage: $Stage"
    echo "Environment: $env"
→ Save
```

### Step 5: Build with Parameters

```
Build with Parameters:
  Stage: Build          ← default, keep as is
  env:   Production     ← select from dropdown
→ Build
```

### Step 6: Verify Console Output

```
Build #1 → Console Output:
  + echo 'Stage: Build'
  Stage: Build
  + echo 'Environment: Production'
  Environment: Production
  Finished: SUCCESS ✅
```

---

## 📌 Verification Checklist

```
☑ Job "parameterized-job" created as Freestyle project
☑ String Parameter "Stage" with default value "Build"
☑ Choice Parameter "env" with exactly 3 choices: Development, Staging, Production
☑ Execute shell step with echo of both parameters
☑ Built with env=Production
☑ Console Output shows "Stage: Build" and "Environment: Production"
☑ Build status: SUCCESS
```

---

## ⚠️ Common Mistakes to Avoid

1. **Wrong order of choices** — The first choice in the Choice Parameter list is the default shown in the dropdown. If Production should NOT be the default, ensure Development is listed first.
2. **Spaces or blank lines between choices** — Extra blank lines in the choices text area create an empty string as a valid choice. Type each choice on its own line with no extra blank lines.
3. **Variable name case sensitivity** — `$Stage` and `$stage` are different in bash. The shell step must use exactly the same case as the parameter name defined in the job configuration.
4. **Not building with env=Production** — The task requires at least one build with `Production` selected. The grading validation will check build history for this specific parameter value.
5. **Using `${STAGE}` instead of `${Stage}`** — Jenkins preserves the exact case of parameter names. Define it as `Stage`, use it as `$Stage` — not `$STAGE`.

---

## 🔍 How Jenkins Passes Parameters to Shell

```
Job configured with:
  Stage (String, default: Build)
  env   (Choice: Development/Staging/Production)

User builds with:
  Stage = Build
  env   = Production

Jenkins sets before executing shell:
  export Stage="Build"
  export env="Production"

Shell script runs:
  echo "Stage: $Stage"       → Stage: Build
  echo "Environment: $env"   → Environment: Production
```

Jenkins injects every parameter as an environment variable. The shell script runs with these variables pre-set, identical to how any environment variable works in bash.

---

## 💼 Real-World DevOps Q&A

> Practical questions and answers from the perspective of a working DevOps engineer — great for interview prep and deepening your understanding.

---

**Q1: What is the difference between a String Parameter and a Choice Parameter, and when should you use each?**

A String Parameter is a free-text field — the user can type anything. Use it when the valid values are open-ended or user-defined: a branch name, a version tag, a package name, a custom message. A Choice Parameter is a dropdown — the user selects from a predefined list. Use it when only specific values are valid and allowing arbitrary input would be dangerous or meaningless: a deployment environment (Development/Staging/Production), an AWS region, an action type (create/update/delete). String parameters maximize flexibility; Choice parameters maximize safety by preventing invalid or mistyped inputs. For environment selection specifically, Choice is almost always the right call.

---

**Q2: How do Jenkins parameters become available in shell scripts?**

Jenkins automatically exports each parameter as an environment variable before executing build steps. A parameter named `Stage` with value `Build` becomes `export Stage=Build` in the shell environment — accessible as `$Stage` or `${Stage}` in any bash script in the build steps, and also in any environment variable field in other build step types. This injection happens for every parameter type: String, Choice, Boolean (appears as `"true"` or `"false"` string), File, etc. The parameter names are case-sensitive and match exactly what was defined in the job configuration.

---

**Q3: What is the default behavior when a Choice Parameter job is triggered automatically (not by a human)?**

When a job with a Choice Parameter is triggered by a webhook, schedule, or upstream trigger without explicit parameter values, Jenkins uses the first choice in the list as the default. This means the order of choices matters significantly for automated triggers. If Production is listed first, automated triggers deploy to Production by default — potentially dangerous. Best practice: list the safest, lowest-risk option first (Development or Staging), ensuring automated triggers default to the non-production target. For truly critical parameters, use a `Not Applicable` or `None` as the first choice to make the automation fail safely if no value is explicitly provided.

---

**Q4: How would you pass parameters to a downstream Jenkins job triggered from this job?**

Use the **Parameterized Trigger plugin** (`build` step in Pipeline, or "Trigger/call builds on other projects" post-build action in Freestyle). In the trigger configuration, you specify the downstream job name and parameter values to pass — which can be literal values, references to the current job's parameters (`$Stage`, `$env`), or dynamically computed values. Example: this job builds with `env=Production`, then triggers a `deploy` job also with `env=Production`. The downstream job receives `env` as its own parameter. This enables parameterized pipeline chains where each stage passes context to the next without hardcoding environment selection anywhere.

---

**Q5: How are parameterized builds used in real deployment pipelines?**

Production deployment pipelines typically look like: a `deploy` job with parameters `ENVIRONMENT` (Choice: dev/staging/prod), `VERSION` (String: docker image tag or artifact version), and `ROLLBACK` (Boolean). The pipeline uses `ENVIRONMENT` to select the right kubeconfig context or AWS account, `VERSION` to pull the specific artifact, and `ROLLBACK` to trigger a rollback instead of a forward deploy. This single parameterized job replaces what would otherwise be separate `deploy-to-dev`, `deploy-to-staging`, `deploy-to-prod` jobs. Approval gates can be inserted for Production specifically: `if (env.ENVIRONMENT == 'Production') { input message: 'Deploy to production?' }`.

---

**Q6: What is the difference between build parameters and environment variables in Jenkins?**

Build parameters are user-provided values specific to a particular job run — defined in job configuration and entered (or defaulted) at build time. They're scoped to that build instance. Jenkins environment variables are predefined values Jenkins automatically provides to every build: `BUILD_NUMBER`, `BUILD_URL`, `JOB_NAME`, `WORKSPACE`, `GIT_BRANCH` (if using Git SCM), etc. Both are accessible in shell steps using `$VARIABLE_NAME` syntax. In a shell step, `echo $BUILD_NUMBER` prints the current build number (Jenkins-provided), while `echo $Stage` prints the user-defined parameter. The distinction matters for debugging and logging — knowing which variables came from Jenkins itself vs which came from user input.

---

## 🔗 References

- [Jenkins Parameterized Builds](https://www.jenkins.io/doc/book/pipeline/syntax/#parameters)
- [Jenkins Environment Variables](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#using-environment-variables)
- [Parameterized Trigger Plugin](https://plugins.jenkins.io/parameterized-trigger/)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
