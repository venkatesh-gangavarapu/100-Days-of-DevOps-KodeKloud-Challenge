#!/bin/bash
# Day 100 — Terraform: EC2 + CloudWatch Alarm + SNS Notification
# Files: main.tf, outputs.tf (only two files)

# STEP 1: Navigate
# cd /home/bob/terraform

# STEP 2: Create main.tf and outputs.tf

# STEP 3: Initialize
# terraform init

# STEP 4: Plan — verify 2 resources + 1 data source
# terraform plan
# Expected:
#   data.aws_sns_topic.datacenter_sns        (read existing SNS topic)
#   aws_instance.datacenter_ec2              (create EC2)
#   aws_cloudwatch_metric_alarm.datacenter_alarm  (create alarm)

# STEP 5: Apply
# terraform apply -auto-approve

# STEP 6: REQUIRED — verify no drift
# terraform plan
# Must show: No changes. Your infrastructure matches the configuration. ✅

# STEP 7: Check outputs
# terraform output
# KKE_instance_name = "datacenter-ec2"
# KKE_alarm_name    = "datacenter-alarm"

# CLOUDWATCH ALARM SPECS:
# Metric:             CPUUtilization
# Namespace:          AWS/EC2
# Statistic:          Average
# Period:             300 seconds (5 minutes)
# Evaluation Periods: 1
# Threshold:          >= 90
# Action:             SNS → datacenter-sns-topic
