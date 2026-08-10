#!/bin/bash
# Day 94 — Terraform: Create VPC in AWS us-east-1
# Working directory: /home/bob/terraform
# File to create: main.tf (only this file, no other .tf files)

# STEP 1: Navigate to working directory
# cd /home/bob/terraform

# STEP 2: Create main.tf
# cat > /home/bob/terraform/main.tf << 'EOF'
# provider "aws" {
#   region = "us-east-1"
# }
#
# resource "aws_vpc" "devops_vpc" {
#   cidr_block = "10.0.0.0/16"
#
#   tags = {
#     Name = "devops-vpc"
#   }
# }
# EOF

# STEP 3: Initialize Terraform
# terraform init
# Downloads AWS provider plugin

# STEP 4: Plan
# terraform plan
# Shows what will be created — verify aws_vpc resource

# STEP 5: Apply
# terraform apply -auto-approve
# Creates the VPC in us-east-1

# STEP 6: Verify
# terraform show
# Check: id, cidr_block, tags.Name = "devops-vpc"

# EXPECTED OUTPUT:
# aws_vpc.devops_vpc: Creating...
# aws_vpc.devops_vpc: Creation complete after Xs [id=vpc-xxxxxxxxx]
# Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
