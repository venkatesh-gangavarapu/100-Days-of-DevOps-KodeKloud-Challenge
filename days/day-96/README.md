# Day 96 — Terraform: Launch EC2 Instance with RSA Key Pair

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Terraform / AWS / EC2 / Key Pair  
**Difficulty:** Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed

---

## 📋 Task Summary

| Requirement | Value |
|------------|-------|
| Instance Name | `nautilus-ec2` (Name tag) |
| AMI | `ami-0c101f26f147fa7fd` (Amazon Linux) |
| Instance Type | `t2.micro` |
| Key Pair | `nautilus-kp` (new RSA key) |
| Security Group | Default SG |
| Region | `us-east-1` |

---

## 🧠 Concept — EC2, Key Pairs, and Data Sources

### Three Resources + One Data Source

```
tls_private_key  →  generates RSA private/public key pair (in Terraform)
aws_key_pair     →  uploads public key to AWS as "nautilus-kp"
data.aws_security_group  →  reads existing default SG from AWS
aws_instance     →  launches EC2 with the key and SG attached
```

### `tls_private_key` + `aws_key_pair` Pattern

AWS key pairs require a public key uploaded to AWS. The `tls` provider generates an RSA key pair within Terraform, then we pass the public key to `aws_key_pair`:

```hcl
resource "tls_private_key" "nautilus_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "nautilus_kp" {
  key_name   = "nautilus-kp"
  public_key = tls_private_key.nautilus_key.public_key_openssh
}
```

### Data Sources vs Resources

```hcl
# resource = CREATE something new in AWS
resource "aws_instance" "nautilus_ec2" { ... }

# data = READ something that already EXISTS in AWS
data "aws_security_group" "default" {
  name = "default"
}
```

Data sources don't create or modify infrastructure — they fetch information about existing resources. The default security group already exists in every AWS account/VPC, so we fetch it rather than creating it.

### Resource Dependencies

Terraform automatically detects dependencies from references:

```
tls_private_key.nautilus_key
       ↓ (public_key reference)
aws_key_pair.nautilus_kp
       ↓ (key_name reference)
aws_instance.nautilus_ec2
       ↑ (id reference)
data.aws_security_group.default
```

Terraform creates resources in the correct order: key pair before instance, data source fetched before instance.

---

## 🔧 The `main.tf`

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "tls_private_key" "nautilus_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "nautilus_kp" {
  key_name   = "nautilus-kp"
  public_key = tls_private_key.nautilus_key.public_key_openssh
}

data "aws_security_group" "default" {
  name = "default"
}

resource "aws_instance" "nautilus_ec2" {
  ami                    = "ami-0c101f26f147fa7fd"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.nautilus_kp.key_name
  vpc_security_group_ids = [data.aws_security_group.default.id]

  tags = {
    Name = "nautilus-ec2"
  }
}
```

---

## 🔧 Commands

```bash
cd /home/bob/terraform
terraform init     # downloads AWS + TLS providers
terraform plan     # verify 3 resources + 1 data source
terraform apply -auto-approve
terraform show     # confirm instance running
```

**Expected resources created:**
```
tls_private_key.nautilus_key         ← RSA key generated
aws_key_pair.nautilus_kp             ← public key uploaded to AWS
aws_instance.nautilus_ec2            ← EC2 running
data.aws_security_group.default      ← (read only, not created)

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

---

## ⚠️ Common Mistakes to Avoid

1. **Forgetting `required_providers` for `tls`** — `tls_private_key` is from the `hashicorp/tls` provider. Without declaring it, `terraform init` won't download it and the resource fails.
2. **Hardcoding a public key** — Don't paste a fixed public key string. Generate it dynamically with `tls_private_key` and reference `public_key_openssh`.
3. **Using `security_groups` instead of `vpc_security_group_ids`** — `security_groups` uses SG names and only works in EC2-Classic (deprecated). Always use `vpc_security_group_ids` with SG IDs for VPC instances.
4. **AMI region-specific** — `ami-0c101f26f147fa7fd` is only valid in `us-east-1`. Using it in a different region fails with "InvalidAMIID.NotFound."
5. **`tags = { Name = "nautilus-ec2" }`** — The `Name` tag (capital N) is what AWS uses for the instance name display. Lowercase `name` won't appear as the instance name.

---

## 💼 Real-World DevOps Q&A

**Q1: What is a `data` source in Terraform and when do you use it?**

A `data` source reads information from existing infrastructure without creating or modifying anything. Use it when: the resource already exists and wasn't created by your Terraform config (default VPC, default security group, an AMI you want to look up by name), when you need to reference resources managed by a different Terraform state, or when you want to look up dynamic values (latest AMI ID for Amazon Linux). Data sources are declared with `data` instead of `resource` and referenced as `data.resource_type.local_name.attribute`.

**Q2: Why generate the RSA key with `tls_private_key` instead of using an existing key?**

The task requires creating a new RSA key named `nautilus-kp`. `tls_private_key` generates a fresh key pair entirely within Terraform — the private key is stored in Terraform state (sensitive), and the public key is uploaded to AWS via `aws_key_pair`. The alternative is pre-generating a key outside Terraform and hardcoding the public key in HCL — less portable and ties the config to a specific machine. The `tls_private_key` pattern is reproducible and self-contained.

**Q3: What is the security implication of storing private keys in Terraform state?**

The private key generated by `tls_private_key` is stored in plain text in `terraform.tfstate`. Anyone with access to the state file can extract the private key and SSH into any instance using `nautilus-kp`. Mitigations: (1) Store state remotely in S3 with encryption at rest and strict IAM policies. (2) Enable S3 server-side encryption. (3) Use Vault provider to store the key in HashiCorp Vault instead of state. (4) For production, generate keys outside Terraform and pass only the public key. Local state files should never be committed to version control.

**Q4: How would you extract and save the private key to SSH into the instance?**

Add an output to save the private key:
```hcl
output "private_key_pem" {
  value     = tls_private_key.nautilus_key.private_key_pem
  sensitive = true
}
```
Then extract it:
```bash
terraform output -raw private_key_pem > nautilus-kp.pem
chmod 400 nautilus-kp.pem
ssh -i nautilus-kp.pem ec2-user@<instance-public-ip>
```
The `sensitive = true` prevents the key from being displayed in normal `terraform output` but allows extraction with `-raw`.

**Q5: What determines the AWS region where the EC2 instance is created?**

The `provider "aws" { region = "us-east-1" }` block sets the default region for all resources in that provider configuration. The AMI (`ami-0c101f26f147fa7fd`) must exist in that region — AMI IDs are region-specific. The default security group fetched by the data source is also region/VPC specific. To deploy to multiple regions, define multiple provider configurations with aliases and reference them in each resource with `provider = aws.alias`.

---

## 🔗 References

- [aws_instance Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [aws_key_pair Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair)
- [tls_private_key Resource](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key)
- [Terraform Data Sources](https://developer.hashicorp.com/terraform/language/data-sources)

---

*Part of my [100 Days of DevOps Challenge](../../README.md) — learning in public, one day at a time.*
