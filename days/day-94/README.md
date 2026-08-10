# Day 94 — Terraform: Create AWS VPC (devops-vpc) in us-east-1

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Terraform / AWS / IaC / VPC  
**Difficulty:** Beginner  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create a VPC named `devops-vpc` in `us-east-1` using Terraform.
- Working directory: `/home/bob/terraform`
- File: `main.tf` (only this file)
- Any valid IPv4 CIDR block

---

## 🧠 Concept — Terraform & Infrastructure as Code

### What is Terraform?

Terraform is HashiCorp's Infrastructure as Code (IaC) tool. Instead of clicking through the AWS console or running AWS CLI commands, you declare the desired infrastructure state in `.tf` files — Terraform figures out what to create, modify, or delete to reach that state.

```
main.tf (desired state)
    │
    ▼ terraform plan  → shows what WILL change
    │
    ▼ terraform apply → makes it so in AWS
    │
    ▼ AWS: VPC created ✅
```

### The `main.tf` Structure

```hcl
# 1. Provider — which cloud and region
provider "aws" {
  region = "us-east-1"
}

# 2. Resource — what to create
resource "aws_vpc" "devops_vpc" {  # resource type + local name
  cidr_block = "10.0.0.0/16"       # required argument

  tags = {
    Name = "devops-vpc"             # AWS console display name
  }
}
```

### Resource Block Anatomy

```hcl
resource "aws_vpc" "devops_vpc" {
#        │           │
#        │           └── Local name (used in Terraform references)
#        └── Resource type (maps to AWS VPC)
```

The tag `Name = "devops-vpc"` is what appears as the VPC name in the AWS console. The local name `devops_vpc` is only used within Terraform configs.

### Terraform Workflow

```bash
terraform init    # download AWS provider plugin (~/.terraform/)
terraform plan    # dry run — shows what will change (no actual changes)
terraform apply   # executes the plan — creates/modifies/destroys resources
terraform show    # displays current state
terraform destroy # removes all managed resources (cleanup)
```

---

## 🔧 The `main.tf`

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "devops_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "devops-vpc"
  }
}
```

---

## 🔧 Commands

```bash
cd /home/bob/terraform

# Write main.tf (content above)

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply -auto-approve

# Verify
terraform show
```

**Expected output:**
```
aws_vpc.devops_vpc: Creating...
aws_vpc.devops_vpc: Creation complete after 2s [id=vpc-0abc123def456]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

---

## ⚠️ Common Mistakes to Avoid

1. **Creating extra `.tf` files** — The task says `main.tf` only. Don't create `variables.tf`, `outputs.tf`, etc.
2. **Forgetting `terraform init`** — Without it, the AWS provider isn't downloaded and `terraform plan` fails with "provider not found."
3. **Wrong tag key** — AWS uses the `Name` tag (capital N) to display the VPC name in the console. `name` (lowercase) won't work.
4. **CIDR block format** — Must be valid IPv4 CIDR: `10.0.0.0/16`, `172.16.0.0/16`, or `192.168.0.0/24` etc. The task says "any IPv4 CIDR block" — `10.0.0.0/16` is the standard choice.
5. **Region mismatch** — Must be `us-east-1` as specified.

---

## 💼 Real-World DevOps Q&A

**Q1: What is Terraform and how does it differ from AWS CLI or CloudFormation?**

Terraform is a cloud-agnostic IaC tool — the same workflow (`init`, `plan`, `apply`) works for AWS, Azure, GCP, and 100+ providers. AWS CLI is imperative (you specify commands to run), Terraform is declarative (you specify desired state). CloudFormation is AWS-native declarative IaC — similar concept to Terraform but locked to AWS, uses JSON/YAML, and has different state management. Terraform's key advantages: multi-cloud support, HCL syntax (more readable than CloudFormation JSON), plan/preview before applying, and a large ecosystem of providers and modules.

**Q2: What does `terraform init` do?**

`terraform init` prepares the working directory for Terraform operations: downloads the provider plugins specified in the configuration (AWS provider in this case) into a `.terraform/` directory, initializes the backend (where state is stored — local by default), and validates the configuration structure. It must be run before `plan` or `apply`, and re-run whenever you add new providers or modules. The downloaded providers are specific versions ensuring reproducibility.

**Q3: What is Terraform state and why does it matter?**

Terraform stores a record of everything it manages in a state file (`terraform.tfstate`). This state maps your HCL resource definitions to real AWS resource IDs. When you run `terraform plan`, Terraform compares your config against the current state to determine what changes are needed — not by querying AWS directly for every resource. State enables: detecting drift (someone manually changed something in AWS), safe modifications (update CIDR block → Terraform knows to modify the existing VPC not create a new one), and dependency tracking. For team environments, state should be stored remotely (S3 + DynamoDB for AWS) with locking to prevent concurrent apply conflicts.

**Q4: What CIDR block should you use for a VPC and why does it matter?**

Common choices: `10.0.0.0/16` (65,536 IPs — most common for AWS VPCs), `172.16.0.0/12`, `192.168.0.0/16`. Choose based on: how many subnets and hosts you need, whether the VPC needs to peer with other VPCs (peered VPCs cannot have overlapping CIDRs), and company-wide IP address management policies. `/16` is the standard starting point — it's large enough to subnet into many small `/24` subnets for different environments, AZs, and tiers, while still fitting within private IP ranges. The CIDR block cannot be changed after the VPC is created.

**Q5: How would you extend this to create subnets inside the VPC?**

```hcl
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.devops_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "devops-public-subnet"
  }
}
```

`aws_vpc.devops_vpc.id` references the VPC's ID using Terraform's resource reference syntax (`resource_type.local_name.attribute`). Terraform automatically creates the subnet after the VPC and passes the correct VPC ID — no manual lookups needed. This dependency tracking is one of Terraform's core features.

---

## 🔗 References

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [aws_vpc Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)
- [Terraform Getting Started](https://developer.hashicorp.com/terraform/tutorials/aws-get-started)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
