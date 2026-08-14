# Day 98 — Terraform: Private VPC + Subnet + EC2 (3-File Structure)

**Challenge Platform:** KodeKloud — 100 Days of DevOps
**Category:** Terraform / AWS / VPC / EC2 / Variables / Outputs
**Difficulty:** Advanced
**Phase:** Phase 6 — Production DevOps Practices
**Status:** ✅ Completed

---

## Task Summary

| Resource | Name | Key Config |
|----------|------|-----------|
| VPC | datacenter-priv-vpc | 10.0.0.0/16 |
| Subnet | datacenter-priv-subnet | 10.0.1.0/24, no auto public IP |
| Security Group | datacenter-priv-sg | ingress from VPC CIDR only |
| EC2 | datacenter-priv-ec2 | t2.micro, inside private subnet |

Three Terraform files: main.tf + variables.tf + outputs.tf

---

## File Structure

```
/home/bob/terraform/
├── main.tf         ← VPC, subnet, SG, EC2, data source
├── variables.tf    ← KKE_VPC_CIDR, KKE_SUBNET_CIDR
└── outputs.tf      ← KKE_vpc_name, KKE_subnet_name, KKE_ec2_private
```

---

## variables.tf

```hcl
variable "KKE_VPC_CIDR" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "KKE_SUBNET_CIDR" {
  description = "CIDR block for the subnet"
  default     = "10.0.1.0/24"
}
```

## outputs.tf

```hcl
output "KKE_vpc_name" {
  value = aws_vpc.datacenter_priv_vpc.tags["Name"]
}

output "KKE_subnet_name" {
  value = aws_subnet.datacenter_priv_subnet.tags["Name"]
}

output "KKE_ec2_private" {
  value = aws_instance.datacenter_priv_ec2.tags["Name"]
}
```

## main.tf

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "datacenter_priv_vpc" {
  cidr_block = var.KKE_VPC_CIDR
  tags = { Name = "datacenter-priv-vpc" }
}

resource "aws_subnet" "datacenter_priv_subnet" {
  vpc_id                  = aws_vpc.datacenter_priv_vpc.id
  cidr_block              = var.KKE_SUBNET_CIDR
  map_public_ip_on_launch = false
  tags = { Name = "datacenter-priv-subnet" }
}

resource "aws_security_group" "datacenter_priv_sg" {
  name   = "datacenter-priv-sg"
  vpc_id = aws_vpc.datacenter_priv_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.KKE_VPC_CIDR]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "datacenter_priv_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.datacenter_priv_subnet.id
  vpc_security_group_ids = [aws_security_group.datacenter_priv_sg.id]
  tags = { Name = "datacenter-priv-ec2" }
}
```

---

## Commands

```bash
cd /home/bob/terraform
terraform init
terraform apply -auto-approve
terraform plan   # must show: No changes ✅
terraform output
```

---

## Key Concepts

**`map_public_ip_on_launch = false`** — Disables auto-assignment of public IPs.
Instances in this subnet get only a private IP — no direct internet access.
This is what makes it a "private" subnet.

**Security group ingress `cidr_blocks = [var.KKE_VPC_CIDR]`** — Only allows
traffic from within the VPC CIDR (10.0.0.0/16). External traffic is blocked.

**Variables** — CIDRs defined once in variables.tf, referenced in main.tf
as `var.KKE_VPC_CIDR` and `var.KKE_SUBNET_CIDR`. The security group rule
references `var.KKE_VPC_CIDR` directly — change the variable and all references
update automatically.

**Outputs** — Values extracted from Terraform state after apply, available via
`terraform output`. KKE_vpc_name, KKE_subnet_name, KKE_ec2_private all return
the Name tag string of the respective resource.

**"No changes" requirement** — After `terraform apply`, running `terraform plan`
again should show no drift between config and state. This confirms the Terraform
config accurately describes the deployed infrastructure.

---

## Q&A

**Q: What makes a subnet "private" in AWS?**
No route to an Internet Gateway (IGW) and `map_public_ip_on_launch = false`.
Public subnets have an IGW route and assign public IPs. Private subnets have
neither — instances can only communicate within the VPC or via NAT Gateway.

**Q: Why use Terraform variables instead of hardcoding CIDRs?**
Variables make configs reusable across environments. Change `KKE_VPC_CIDR`
to `172.16.0.0/16` and every resource using `var.KKE_VPC_CIDR` updates —
the VPC, subnet references, security group rules. No manual find-and-replace.

**Q: What do Terraform outputs do?**
Outputs expose values from Terraform state — useful for: referencing values in
other Terraform configs (remote state), passing values to scripts, and displaying
key information after apply. `terraform output KKE_vpc_name` returns the string
directly. Sensitive outputs can be marked `sensitive = true`.

---

*Part of my 100 Days of DevOps Challenge — learning in public, one day at a time.*
