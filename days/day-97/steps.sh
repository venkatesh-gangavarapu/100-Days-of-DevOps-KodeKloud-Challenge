#!/bin/bash
# Day 97 — Terraform: Create IAM Policy (iampolicy_james)
# EC2 read-only: DescribeInstances, DescribeImages, DescribeSnapshots

# STEP 1: Navigate
# cd /home/bob/terraform

# STEP 2: Create main.tf (see file)

# STEP 3: Initialize
# terraform init

# STEP 4: Plan
# terraform plan
# Expected: 1 resource to create (aws_iam_policy.iampolicy_james)

# STEP 5: Apply
# terraform apply -auto-approve

# STEP 6: Verify
# terraform show
# Check: name = "iampolicy_james", policy contains Describe actions

# EXPECTED OUTPUT:
# aws_iam_policy.iampolicy_james: Creating...
# aws_iam_policy.iampolicy_james: Creation complete [id=arn:aws:iam::XXXX:policy/iampolicy_james]
# Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

# IAM Policy Actions:
# ec2:DescribeInstances  → view all instances in EC2 console
# ec2:DescribeImages     → view all AMIs
# ec2:DescribeSnapshots  → view all snapshots
