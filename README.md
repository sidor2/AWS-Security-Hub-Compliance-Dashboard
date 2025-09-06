# AWS Security Hub Compliance Dashboard

![Terraform](https://img.shields.io/badge/Terraform-1.2.0+-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazonaws)

A robust, automated compliance monitoring system leveraging **AWS Security Hub**, **AWS Config**, **Amazon EventBridge**, and **Amazon SNS**. This project detects security misconfigurations in your AWS environment and sends email notifications for findings based on configurable severity levels, aligned with the **CIS AWS Foundations Benchmark**.

## ✨ Features

- **Automated Compliance Monitoring**: Continuously evaluates AWS resources against the CIS AWS Foundations Benchmark using AWS Security Hub and AWS Config.
- **Flexible Notifications**: Sends customizable SNS email alerts for Security Hub findings based on severity levels (e.g., CRITICAL, HIGH, MEDIUM, LOW) defined in Terraform variables.
- **Streamlined Architecture**: Utilizes direct EventBridge-to-SNS integration for efficient, low-maintenance notifications without Lambda dependencies.
- **Robust AWS Config Setup**: Configured with the AWS-managed `AWS_ConfigRole` policy to record all resource types, ensuring comprehensive Security Hub findings.
- **Terraform-Driven**: Fully automated deployment with parameterized configuration for region, project name, email, and severity levels.

## 🏗️ Architecture

The system integrates the following AWS services:

- **AWS Config**: Captures resource configurations and changes, stored in an S3 bucket.
- **AWS Security Hub**: Analyzes configurations against CIS standards and generates findings.
- **Amazon EventBridge**: Triggers SNS notifications for findings matching specified severity levels.
- **Amazon SNS**: Delivers email alerts to a configurable email address.

![Architecture Diagram](https://via.placeholder.com/600x200?text=AWS+Security+Hub+Architecture)

## 📋 Prerequisites

- An AWS account with permissions for IAM, S3, AWS Config, Security Hub, EventBridge, and SNS.
- [Terraform](https://www.terraform.io/downloads.html) (version >= 1.2.0) installed.
- [AWS CLI](https://aws.amazon.com/cli/) configured with valid credentials.

## 🚀 Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd aws-security-hub-dashboard
```

### 2. Configure `terraform.tfvars`

Create or edit the `terraform.tfvars` file with your desired settings:

```hcl
aws_region = "us-east-1"
project_name = "security-hub-dashboard"
alert_email = "your.email@example.com"
securityhub_standards_arns = [
  "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
]
securityhub_severity_labels = ["CRITICAL", "HIGH", "MEDIUM", "LOW"]
```

### 3. Deploy with Terraform

```bash
terraform init
terraform plan
terraform apply
```

### 4. Confirm SNS Subscription

Verify the SNS subscription is active:

```bash
aws sns list-subscriptions-by-topic --topic-arn $(terraform output -raw sns_topic_arn) --region us-east-1
```

### 5. Test the System

Create test resources to trigger Security Hub findings:

```bash
aws s3api create-bucket --bucket test-security-hub-unencrypted-$(date +%s) --region us-east-1
aws ec2 create-security-group --group-name test-security-hub-public --description "Test public SG" --region us-east-1
aws ec2 authorize-security-group-ingress --group-name test-security-hub-public --protocol -1 --port -1 --cidr 0.0.0/0 --region us-east-1
```

### 6. Clean Up

Remove resources to avoid charges:

```bash
terraform destroy
aws s3 rb s3://test-security-hub-unencrypted-<random-string> --region us-east-1
aws ec2 delete-security-group --group-name test-security-hub-public --region us-east-1
```

## 📂 Project Structure

| File                | Description                                              |
|---------------------|----------------------------------------------------------|
| `main.tf`           | Defines AWS resources (Config, Security Hub, EventBridge, SNS). |
| `variables.tf`      | Declares variables for region, project name, email, etc.  |
| `terraform.tfvars`  | Configures deployment settings.                          |
| `outputs.tf`        | Outputs SNS topic ARN and other resource details.        |
| `.terraformignore`  | Excludes unnecessary files from Terraform.               |

## 💰 Cost Considerations

Estimated monthly costs (post-free tier, us-east-1):

- **AWS Config**: ~$30 (100 resources)
- **AWS Security Hub**: ~$12 (CIS standard)
- **Amazon SNS**: ~$0.01 (100 emails)
- **Total**: ~$42.01/month
- **Free Tier**: ~$12/month during Security Hub 30-day trial (Config + SNS)

**Optimization Tips**:
- Test with fewer resources to reduce costs.
- Use `terraform destroy` to remove resources when not in use.

## 🛠️ Troubleshooting

### No Email Notifications

1. Verify SNS subscription status:
   ```bash
   aws sns list-subscriptions-by-topic --topic-arn $(terraform output -raw sns_topic_arn) --region us-east-1
   ```
   Ensure the subscription is "Confirmed."

2. Check `securityhub_severity_labels` in `terraform.tfvars` matches finding severities.

3. Inspect the EventBridge rule:
   ```bash
   aws events describe-rule --name security-hub-dashboard-securityhub-findings --region us-east-1
   ```

### No Findings Generated

1. Confirm AWS Config is enabled:
   ```bash
   aws configservice describe-configuration-recorders --region us-east-1
   ```

2. Verify Security Hub is active:
   ```bash
   aws securityhub describe-hub --region us-east-1
   ```