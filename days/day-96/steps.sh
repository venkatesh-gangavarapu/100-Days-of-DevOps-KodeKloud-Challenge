#!/bin/bash
# Day 96 — Terraform: Launch EC2 Instance with RSA Key Pair
# Working directory: /home/bob/terraform
# File: main.tf only

# STEP 1: Navigate
# cd /home/bob/terraform

# STEP 2: Create main.tf (see main.tf)

# STEP 3: Initialize (downloads AWS + TLS providers)
# terraform init

# STEP 4: Plan — verify resources to create
# terraform plan
# Expected resources:
#   tls_private_key.nautilus_key        (generate RSA key)
#   aws_key_pair.nautilus_kp            (upload public key to AWS)
#   data.aws_security_group.default     (fetch existing default SG)
#   aws_instance.nautilus_ec2           (launch EC2)

# STEP 5: Apply
# terraform apply -auto-approve

# STEP 6: Verify
# terraform show
# Check: instance state, key_name, tags.Name, security_groups

# EXPECTED OUTPUT:
# tls_private_key.nautilus_key: Creating...
# aws_key_pair.nautilus_kp: Creating...
# aws_instance.nautilus_ec2: Creating...
# aws_instance.nautilus_ec2: Creation complete [id=i-0abc123def456]
# Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
