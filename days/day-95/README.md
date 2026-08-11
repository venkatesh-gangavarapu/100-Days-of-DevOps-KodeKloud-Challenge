# Day 95 — Terraform: AWS Security Group with HTTP & SSH Rules

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Terraform / AWS / Security Group / IaC  
**Difficulty:** Beginner–Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

Create security group `xfusion-sg` in the default VPC (us-east-1) with:

| Rule | Type | Port | Protocol | Source |
|------|------|------|----------|--------|
| Inbound | HTTP | 80 | tcp | 0.0.0.0/0 |
| Inbound | SSH | 22 | tcp | 0.0.0.0/0 |

---

## 🧠 Concept — Security Groups in Terraform

### Security Group Block Structure

```hcl
resource "aws_security_group" "xfusion_sg" {
  name        = "xfusion-sg"           # SG name in AWS
  description = "..."                   # Required field

  ingress { ... }  # inbound rules (can have multiple)
  egress  { ... }  # outbound rules

  tags = { Name = "xfusion-sg" }
}
```

### `ingress` Block Parameters

```hcl
ingress {
  description = "HTTP"         # label — good practice
  from_port   = 80             # start of port range
  to_port     = 80             # end of port range (same = single port)
  protocol    = "tcp"          # tcp, udp, icmp, or "-1" (all)
  cidr_blocks = ["0.0.0.0/0"] # source IP range — list format
}
```

### Why Include an `egress` Rule?

Without an explicit `egress` block, Terraform removes all outbound rules when managing the security group — leaving the instances unable to make any outbound connections. The standard `egress` block allows all outbound traffic:

```hcl
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"           # -1 = all protocols
  cidr_blocks = ["0.0.0.0/0"]
}
```

### Default VPC

No `vpc_id` is specified in the resource — Terraform uses the default VPC in the region automatically. If you needed a specific VPC, you'd add: `vpc_id = aws_vpc.devops_vpc.id` (referencing Day 94's VPC).

---

## 🔧 The `main.tf`

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "xfusion_sg" {
  name        = "xfusion-sg"
  description = "Security group for Nautilus App Servers"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "xfusion-sg"
  }
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
aws_security_group.xfusion_sg: Creating...
aws_security_group.xfusion_sg: Creation complete [id=sg-0abc123def456]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

---

## ⚠️ Common Mistakes to Avoid

1. **`cidr_blocks` is a list** — Must be `["0.0.0.0/0"]` (square brackets), not `"0.0.0.0/0"` (plain string).
2. **Missing `description`** — AWS requires a description for security groups. Terraform will fail without it.
3. **No `egress` block** — Terraform's AWS provider removes all outbound rules if `egress` isn't specified, breaking outbound connectivity.
4. **`protocol = "-1"` for all** — Use `"-1"` for all protocols in egress. Don't use `"all"`.
5. **`from_port`/`to_port` must match for single ports** — For port 80, both `from_port = 80` and `to_port = 80`. For a range like 8000-9000, use `from_port = 8000, to_port = 9000`.

---

## 💼 Real-World DevOps Q&A

**Q1: What is an AWS Security Group and how does it work?**

A Security Group is a virtual firewall for AWS resources (EC2 instances, RDS, etc.). It controls inbound and outbound traffic at the instance level. Security groups are stateful — if you allow inbound traffic on port 80, the return traffic is automatically allowed regardless of outbound rules. Rules are evaluated as a set (no ordering/priority) — the most permissive matching rule wins. Security groups can only allow traffic — there's no explicit deny (unlike Network ACLs). An instance can have multiple security groups applied, and the rules from all of them are combined.

**Q2: What is the difference between `from_port`/`to_port` and how do you specify port ranges?**

`from_port` and `to_port` define the port range. For a single port: both are the same (`from_port = 80, to_port = 80`). For a range: `from_port = 8000, to_port = 9000` allows all ports 8000-9000. For protocols that don't use ports (like ICMP): use `-1` for both (or specific ICMP type/code). For all traffic (`protocol = "-1"`): set both to `0`. The `protocol` field values are: `"tcp"`, `"udp"`, `"icmp"`, `"icmpv6"`, or `"-1"` (all protocols).

**Q3: Why is `cidr_blocks` a list in Terraform?**

`cidr_blocks` accepts multiple CIDR ranges for the same rule, so it's designed as a list:
```hcl
cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
```
This allows a single rule to cover multiple source networks. `["0.0.0.0/0"]` is a single-element list meaning "all IPv4 addresses." For IPv6, use `ipv6_cidr_blocks = ["::/0"]` separately. The list syntax is required even for a single CIDR — `"0.0.0.0/0"` (without brackets) causes a Terraform validation error.

**Q4: How would you attach this security group to an EC2 instance in Terraform?**

```hcl
resource "aws_instance" "app_server" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.xfusion_sg.id]

  tags = {
    Name = "nautilus-app-server"
  }
}
```

`aws_security_group.xfusion_sg.id` references the security group's ID using Terraform's resource reference syntax. Terraform automatically creates the security group first (dependency detected from the reference) and passes its ID to the EC2 instance.

**Q5: What is the difference between Security Groups and Network ACLs in AWS?**

Security Groups operate at the instance level and are stateful — return traffic is automatically allowed. Network ACLs operate at the subnet level and are stateless — return traffic must be explicitly allowed with separate rules. NACLs evaluate rules in order (by rule number) and can explicitly deny traffic. Security groups can only allow. In practice: Security Groups are the primary access control for most use cases (attached to instances, RDS, ELBs). NACLs provide an additional subnet-level layer, useful for blocking specific IPs or implementing defense-in-depth. Most production setups use both in combination.

---

## 🔗 References

- [aws_security_group Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
- [AWS Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
