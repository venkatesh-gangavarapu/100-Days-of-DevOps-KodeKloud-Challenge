# Day 99 — Terraform: DynamoDB + IAM Role + Read-Only Policy

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Terraform / AWS / DynamoDB / IAM  
**Difficulty:** Advanced  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## Task Summary

| Resource | Name | Config |
|----------|------|--------|
| DynamoDB Table | xfusion-table | PAY_PER_REQUEST, hash_key: id |
| IAM Role | xfusion-role | Trusted by ec2.amazonaws.com |
| IAM Policy | xfusion-readonly-policy | GetItem, Scan, Query on table ARN |
| Policy Attachment | — | Policy attached to role |

**4 Terraform files:** main.tf + variables.tf + outputs.tf + terraform.tfvars

---

## File Structure

```
/home/bob/terraform/
├── main.tf            ← DynamoDB + IAM role + policy + attachment
├── variables.tf       ← KKE_TABLE_NAME, KKE_ROLE_NAME, KKE_POLICY_NAME
├── outputs.tf         ← kke_dynamodb_table, kke_iam_role_name, kke_iam_policy_name
└── terraform.tfvars   ← actual values for all variables
```

---

## terraform.tfvars

```hcl
KKE_TABLE_NAME  = "xfusion-table"
KKE_ROLE_NAME   = "xfusion-role"
KKE_POLICY_NAME = "xfusion-readonly-policy"
```

## variables.tf

```hcl
variable "KKE_TABLE_NAME" {
  description = "Name of the DynamoDB table"
}

variable "KKE_ROLE_NAME" {
  description = "Name of the IAM role"
}

variable "KKE_POLICY_NAME" {
  description = "Name of the IAM policy"
}
```

## outputs.tf

```hcl
output "kke_dynamodb_table" {
  value = aws_dynamodb_table.xfusion_table.name
}

output "kke_iam_role_name" {
  value = aws_iam_role.xfusion_role.name
}

output "kke_iam_policy_name" {
  value = aws_iam_policy.xfusion_readonly_policy.name
}
```

## main.tf

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_table" "xfusion_table" {
  name         = var.KKE_TABLE_NAME
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = { Name = var.KKE_TABLE_NAME }
}

resource "aws_iam_role" "xfusion_role" {
  name = var.KKE_ROLE_NAME

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "xfusion_readonly_policy" {
  name        = var.KKE_POLICY_NAME
  description = "Read-only access to xfusion DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem", "dynamodb:Scan", "dynamodb:Query"]
      Resource = aws_dynamodb_table.xfusion_table.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "xfusion_attach" {
  role       = aws_iam_role.xfusion_role.name
  policy_arn = aws_iam_policy.xfusion_readonly_policy.arn
}
```

---

## Commands

```bash
cd /home/bob/terraform
terraform init
terraform apply -auto-approve

# Required verification
terraform plan
# No changes. Your infrastructure matches the configuration. ✅

terraform output
# kke_dynamodb_table  = "xfusion-table"
# kke_iam_role_name   = "xfusion-role"
# kke_iam_policy_name = "xfusion-readonly-policy"
```

---

## Key Concepts

**`terraform.tfvars`** — the values file. Variables declared in `variables.tf`,
actual values defined in `terraform.tfvars`. Terraform automatically loads this
file. Keeps values separate from declarations — different tfvars files per environment.

**DynamoDB minimal config** — requires only `name`, `billing_mode`, `hash_key`,
and the `attribute` block for the hash key. `PAY_PER_REQUEST` billing means no
capacity unit provisioning needed — serverless, scales automatically.

**Policy scoped to specific table ARN** — `Resource = aws_dynamodb_table.xfusion_table.arn`
limits the policy to exactly this one table. Using `"*"` would grant access to
ALL DynamoDB tables — a least privilege violation.

**aws_iam_role_policy_attachment** — links the standalone policy to the role.
Separate from both — allows the same policy to be attached to multiple roles
without duplication.

---

## Q&A

**Q: What is the difference between variables.tf and terraform.tfvars?**
`variables.tf` declares variables — name, type, description, optional default.
`terraform.tfvars` provides the actual values. This separation enables the same
Terraform config to deploy different environments (dev/staging/prod) by swapping
tfvars files — the module logic stays identical.

**Q: Why `billing_mode = "PAY_PER_REQUEST"` for minimal DynamoDB config?**
PAY_PER_REQUEST (on-demand mode) requires no capacity planning — AWS scales
automatically. The alternative, PROVISIONED, requires specifying
`read_capacity` and `write_capacity` units, creating unnecessary complexity
for a minimal setup. On-demand is the right default for new tables.

**Q: Why is `Resource = aws_dynamodb_table.xfusion_table.arn` better than `"*"`?**
Least privilege — the policy grants access to exactly one table. Using `"*"` would
allow GetItem, Scan, and Query on every DynamoDB table in the account. If this role
is ever compromised, the blast radius is limited to one table's read operations
rather than the entire database service.

**Q: What is aws_iam_role_policy_attachment vs inline policies?**
`aws_iam_role_policy_attachment` attaches a standalone managed policy to a role.
The policy has its own ARN and can be attached to multiple roles. An inline policy
is embedded in the role — deleted when the role is deleted, not reusable. Managed
policies via attachment are preferred: they have version history, can be audited,
and reused across roles. Inline policies are used when the policy is specific to
exactly one role and should never be reused.

---

*Part of my 100 Days of DevOps Challenge — learning in public, one day at a time.*
