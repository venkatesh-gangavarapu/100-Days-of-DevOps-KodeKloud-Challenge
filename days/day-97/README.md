# Day 97 — Terraform: IAM Policy for EC2 Read-Only Access

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Terraform / AWS / IAM / Security  
**Difficulty:** Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create IAM policy `iampolicy_james` that allows read-only access to the EC2 console:
- View all instances (`ec2:DescribeInstances`)
- View all AMIs (`ec2:DescribeImages`)
- View all snapshots (`ec2:DescribeSnapshots`)

---

## 🧠 Concept — IAM Policies in Terraform

### What is an IAM Policy?

An IAM policy is a JSON document that defines permissions — what actions are allowed or denied on which AWS resources. Policies are attached to users, groups, or roles to grant them those permissions.

### IAM Policy JSON Structure

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeImages",
        "ec2:DescribeSnapshots"
      ],
      "Resource": "*"
    }
  ]
}
```

| Field | Value | Meaning |
|-------|-------|---------|
| `Version` | `2012-10-17` | Policy language version (always this value) |
| `Effect` | `Allow` | Permit these actions |
| `Action` | list | What API calls are allowed |
| `Resource` | `"*"` | Apply to all resources of this type |

### `jsonencode()` in Terraform

Instead of writing raw JSON strings (error-prone), Terraform's `jsonencode()` function converts HCL maps/lists to valid JSON:

```hcl
policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect   = "Allow"
      Action   = ["ec2:DescribeInstances", ...]
      Resource = "*"
    }
  ]
})
```

Terraform validates the structure at plan time, making policy errors easier to catch before applying.

### Why `Resource = "*"` for Describe Actions

EC2 Describe actions don't operate on specific resource ARNs — they list resources. AWS requires `"*"` for these actions since they don't target a single resource instance. Trying to scope `ec2:DescribeInstances` to a specific instance ARN would cause an error.

---

## 🔧 The `main.tf`

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_policy" "iampolicy_james" {
  name        = "iampolicy_james"
  description = "Read-only access to EC2 console - view instances, AMIs, and snapshots"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeSnapshots"
        ]
        Resource = "*"
      }
    ]
  })
}
```

---

## 🔧 Commands

```bash
cd /home/bob/terraform
terraform init
terraform plan
terraform apply -auto-approve
terraform show
```

**Expected output:**
```
aws_iam_policy.iampolicy_james: Creating...
aws_iam_policy.iampolicy_james: Creation complete
[id=arn:aws:iam::123456789:policy/iampolicy_james]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

---

## ⚠️ Common Mistakes to Avoid

1. **Wrong policy Version** — Always use `"2012-10-17"`. This is the policy language version, not a date you choose.
2. **Using raw JSON string** — HCL heredoc strings for JSON are error-prone. Always use `jsonencode()` — it produces valid JSON and is validated at plan time.
3. **Scoping Describe actions to specific ARNs** — `ec2:Describe*` actions require `"*"` as resource. They list/describe all resources and cannot be ARN-scoped.
4. **Confusing IAM policy name and description** — `name` is the unique identifier in AWS. `description` is human-readable metadata. The name must be unique per account.
5. **Creating extra `.tf` files** — Task says `main.tf` only.

---

## 💼 Real-World DevOps Q&A

**Q1: What is the difference between an IAM policy, role, user, and group?**

An IAM **policy** is the permission document — it defines what actions are allowed. A **user** is a person or service account identity. A **group** is a collection of users that share permissions. A **role** is an identity that can be assumed by AWS services or external identities (no permanent credentials). Policies are attached to users, groups, or roles to grant them permissions. Best practice: never attach policies directly to users — create groups with appropriate policies and add users to groups. Roles are used for EC2 instances, Lambda functions, and cross-account access.

**Q2: What is the principle of least privilege and how does it apply to this policy?**

Least privilege means granting only the minimum permissions needed for a user to perform their job — no more. This IAM policy grants only three specific Describe actions, not broad `ec2:*` or `"*"` access. A user with this policy can view EC2 resources in the console but cannot start/stop instances, create AMIs, delete snapshots, or perform any write operation. In practice: start with the minimum required permissions, add more only when a specific need arises, and regularly audit permissions to remove unused access.

**Q3: How would you attach this policy to an IAM user in Terraform?**

```hcl
resource "aws_iam_user" "james" {
  name = "james"
}

resource "aws_iam_user_policy_attachment" "james_ec2_readonly" {
  user       = aws_iam_user.james.name
  policy_arn = aws_iam_policy.iampolicy_james.arn
}
```

`aws_iam_policy.iampolicy_james.arn` references the policy's ARN using Terraform's resource reference syntax. Terraform creates the user and policy first, then attaches them.

**Q4: What is the difference between managed policies and inline policies in AWS IAM?**

**Managed policies** (what we created today) are standalone policy documents with their own ARN — they can be attached to multiple users, groups, or roles. Changes to a managed policy automatically apply to everything it's attached to. **Inline policies** are embedded directly in a user, group, or role — they can't be reused and are deleted when the entity is deleted. AWS has two types of managed policies: **AWS managed** (created and maintained by AWS, like `AmazonEC2ReadOnlyAccess`) and **customer managed** (created by you, like `iampolicy_james`). Customer managed policies give you full control over the permissions and version history.

**Q5: How would you add this policy to an IAM role for an EC2 instance (instance profile)?**

```hcl
resource "aws_iam_role" "ec2_role" {
  name = "ec2-readonly-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_readonly" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.iampolicy_james.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-readonly-profile"
  role = aws_iam_role.ec2_role.name
}
```

This creates a role that EC2 can assume, attaches our policy, and wraps it in an instance profile (required for EC2). The instance would have read-only EC2 access without storing credentials on the instance.

---

## 🔗 References

- [aws_iam_policy Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)
- [IAM Policy Reference](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html)
- [EC2 Actions Reference](https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonec2.html)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
