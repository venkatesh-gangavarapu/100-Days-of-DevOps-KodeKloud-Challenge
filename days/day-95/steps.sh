#!/bin/bash
# Day 95 — Terraform: Create Security Group with HTTP + SSH Rules
# Working directory: /home/bob/terraform
# File: main.tf only

# STEP 1: Navigate to working directory
# cd /home/bob/terraform

# STEP 2: Create main.tf
# (see main.tf content)

# STEP 3: Initialize Terraform
# terraform init

# STEP 4: Plan (verify the SG config)
# terraform plan
# Check:
#   name        = "xfusion-sg"
#   description = "Security group for Nautilus App Servers"
#   ingress: port 80 tcp 0.0.0.0/0
#   ingress: port 22 tcp 0.0.0.0/0

# STEP 5: Apply
# terraform apply -auto-approve

# STEP 6: Verify
# terraform show
# Check: id, name, ingress rules

# EXPECTED OUTPUT:
# aws_security_group.xfusion_sg: Creating...
# aws_security_group.xfusion_sg: Creation complete [id=sg-xxxxxxxxx]
# Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
