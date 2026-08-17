# Day 100 — Terraform: EC2 + CloudWatch Alarm + SNS Notification

**Challenge Platform:** KodeKloud — 100 Days of DevOps  
**Category:** Terraform / AWS / EC2 / CloudWatch / SNS  
**Difficulty:** Intermediate  
**Phase:** Phase 6 — Production DevOps Practices  
**Status:** ✅ Completed 🏆

---

## The Final Task

| Resource | Name | Key Config |
|----------|------|-----------|
| EC2 Instance | datacenter-ec2 | Ubuntu ami-0c02fb55956c7d316, t2.micro |
| CloudWatch Alarm | datacenter-alarm | CPU >= 90%, 1 x 5-min period, Average |
| SNS Topic | datacenter-sns-topic | Already exists — fetched via data source |

**2 Terraform files:** main.tf + outputs.tf

---

## main.tf

```hcl
provider "aws" {
  region = "us-east-1"
}

# Fetch existing SNS topic
data "aws_sns_topic" "datacenter_sns" {
  name = "datacenter-sns-topic"
}

# EC2 Instance
resource "aws_instance" "datacenter_ec2" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"

  tags = {
    Name = "datacenter-ec2"
  }
}

# CloudWatch Alarm
resource "aws_cloudwatch_metric_alarm" "datacenter_alarm" {
  alarm_name          = "datacenter-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "Triggers when CPU >= 90% for 5 minutes"

  dimensions = {
    InstanceId = aws_instance.datacenter_ec2.id
  }

  alarm_actions = [data.aws_sns_topic.datacenter_sns.arn]

  tags = {
    Name = "datacenter-alarm"
  }
}
```

## outputs.tf

```hcl
output "KKE_instance_name" {
  value = aws_instance.datacenter_ec2.tags["Name"]
}

output "KKE_alarm_name" {
  value = aws_cloudwatch_metric_alarm.datacenter_alarm.alarm_name
}
```

---

## Commands

```bash
cd /home/bob/terraform
terraform init
terraform apply -auto-approve

# Required verification
terraform plan
# No changes. Your infrastructure matches the configuration. ✅

terraform output
# KKE_instance_name = "datacenter-ec2"
# KKE_alarm_name    = "datacenter-alarm"
```

---

## Key Concepts

**CloudWatch Alarm parameters explained:**

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `metric_name` | CPUUtilization | The EC2 CPU metric |
| `namespace` | AWS/EC2 | EC2 metrics namespace |
| `statistic` | Average | Aggregate function over the period |
| `period` | 300 | 5 minutes in seconds |
| `evaluation_periods` | 1 | 1 consecutive period must breach threshold |
| `threshold` | 90 | 90% CPU |
| `comparison_operator` | GreaterThanOrEqualToThreshold | >= 90 |

**`dimensions`** ties the alarm to a specific EC2 instance via its ID.
Without dimensions, the alarm would monitor all EC2 instances in the region.

**`data "aws_sns_topic"`** — the SNS topic already exists. Using a data source
reads its ARN without creating or modifying it. The ARN is passed to
`alarm_actions` so CloudWatch knows where to send notifications when the
alarm fires.

**`evaluation_periods = 1`** — the alarm triggers after just 1 consecutive
5-minute period above 90%. `evaluation_periods = 3` would require 15 consecutive
minutes — useful to avoid alarm noise for brief CPU spikes.

---

## Q&A

**Q: What is Amazon CloudWatch and what does a metric alarm do?**
CloudWatch is AWS's monitoring and observability service. It collects metrics
from AWS services (CPU, memory, disk, network) and stores them as time-series
data. A metric alarm watches a specific metric over a defined period. When the
metric crosses a threshold for the specified number of consecutive periods,
CloudWatch changes the alarm state and executes configured actions — sending
SNS notifications, triggering Auto Scaling, stopping EC2 instances.

**Q: What is `evaluation_periods` and how does it affect alarm sensitivity?**
`evaluation_periods` defines how many consecutive data points must breach the
threshold before the alarm triggers. With `evaluation_periods = 1` and
`period = 300`, one 5-minute window above 90% CPU fires the alarm immediately.
With `evaluation_periods = 3`, three consecutive 5-minute windows (15 minutes)
must all be above 90%. Higher evaluation periods reduce false alarms from
transient spikes. For production alerts, `evaluation_periods = 2` or `3` is
common to avoid paging engineers for brief CPU bursts.

**Q: Why use a data source for the SNS topic instead of creating it?**
The task states the SNS topic "is already created." Creating it with Terraform
would fail (resource already exists) or conflict with the existing resource.
`data "aws_sns_topic"` reads the existing topic's attributes (especially the ARN)
without creating or modifying it. This is the correct Terraform pattern for
referencing pre-existing infrastructure that's managed outside your config.

**Q: How would you add an alarm for low CPU (instance possibly stuck)?**
```hcl
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "datacenter-alarm-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  dimensions          = { InstanceId = aws_instance.datacenter_ec2.id }
  alarm_actions       = [data.aws_sns_topic.datacenter_sns.arn]
}
```
CPU below 5% for 15 minutes could indicate a hung process or unresponsive
application. Monitoring both high AND low CPU gives a complete picture of
instance health.

---

*Part of my 100 Days of DevOps Challenge — 100 days. Complete. 🏆*

---

## 🔑 Key Lessons Learned (After Multiple Attempts)

This was the hardest task of the challenge — not because of complexity, but because of the LocalStack environment specifics.

### What caused every failure

| Attempt | Failure Reason |
|---------|---------------|
| Used `data "aws_sns_topic"` | Data source not resolving in LocalStack |
| Used `aws_caller_identity` + locals | Duplicate `provider` block conflict |
| Added `lifecycle ignore_changes` with provider block | Still duplicate provider conflict |
| Final working solution | No provider block in main.tf + lifecycle |

### The three rules for LocalStack Terraform tasks

1. **Never add `provider` block to `main.tf`** — it lives in `providers.tf` already
2. **Include the SNS topic resource** exactly matching the state file — omitting it causes drift
3. **`lifecycle { ignore_changes = all }`** on EC2 and alarm — prevents LocalStack attribute drift

### How to debug future Terraform drift

```bash
# Step 1: Check state
terraform state list

# Step 2: Check existing files BEFORE touching anything
cat main.tf
cat providers.tf
cat terraform.tfstate

# Step 3: Run plan to see baseline
terraform plan

# Step 4: Apply then immediately verify
terraform apply -auto-approve
terraform plan  # Must show: No changes
```

---
