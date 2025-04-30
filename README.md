# AWS Security Hub Compliance Dashboard

This project deploys an automated compliance monitoring system using AWS Security Hub, AWS Config, Amazon EventBridge, and Amazon SNS. It detects security misconfigurations in your AWS environment and sends email notifications for findings based on configurable severity levels, leveraging the CIS AWS Foundations Benchmark.

## Features
- **Automated Compliance Monitoring**: Uses AWS Security Hub and AWS Config to continuously evaluate AWS resources against the CIS AWS Foundations Benchmark.
- **Flexible Notifications**: Sends SNS email alerts for Security Hub findings with customizable severity levels (e.g., CRITICAL, HIGH, MEDIUM, LOW) defined in Terraform variables.
- **Streamlined Architecture**: Direct EventBridge-to-SNS integration for efficient, low-maintenance notifications, eliminating Lambda dependencies.
- **Robust AWS Config Setup**: Configured with the AWS-managed `AWS_ConfigRole` policy to record all resource types, ensuring comprehensive Security Hub findings.
- **Terraform-Driven**: Fully automated deployment with parameterized configuration for region, project name, email, and severity levels.

## Architecture
- **AWS Config**: Records resource configurations and changes, stored in an S3 bucket.
- **Security Hub**: Analyzes configurations against CIS standards and generates findings.
- **EventBridge**: Triggers SNS notifications for findings matching specified severity levels.
- **SNS**: Sends email alerts to a configurable email address.

## Prerequisites
- AWS account with permissions for IAM, S3, Config, Security Hub, EventBridge, and SNS.
- Terraform (>= 1.2.0) installed.
- AWS CLI configured with credentials.

## Setup Instructions
1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd aws-security-hub-dashboard
   ```

2. **Configure terraform.tfvars**:
   ```
   aws_region = "us-east-1"
   project_name = "security-hub-dashboard"
   alert_email = "your.email@example.com"
   securityhub_standards_arns = [
   "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
   ]
   securityhub_severity_labels = ["CRITICAL", "HIGH", "MEDIUM", "LOW"]
   ```

3. **Deploy with Terraform**:
   ```
   terraform init
   terraform plan
   terraform apply
   ```

4. **Confirm SNS Subscription**:
   ```
   aws sns list-subscriptions-by-topic --topic-arn $(terraform output -raw sns_topic_arn) --region us-east-1
   ```

5. **Test the System**:
   ```
   aws s3api create-bucket --bucket test-security-hub-unencrypted-$(date +%s) --region us-east-1
   aws ec2 create-security-group --group-name test-security-hub-public --description "Test public SG" --region us-east-1
   aws ec2 authorize-security-group-ingress --group-name test-security-hub-public --protocol -1 --port -1 --cidr 0.0.0.0/0 --region us-east-1
   ```

6. **Clean Up**:
   ```
   terraform destroy
   aws s3 rb s3://test-security-hub-unencrypted-<random-string> --region us-east-1
   aws ec2 delete-security-group --group-name test-security-hub-public --region us-east-1
   ```

## Files
- `main.tf`: Defines AWS resources (Config, Security Hub, EventBridge, SNS).
- `variables.tf`: Declares variables for region, project name, email, standards, and severity levels.
- `terraform.tfvars`: Configures deployment settings.
- `outputs.tf`: Outputs SNS topic ARN and other resource details.
- `.terraformignore`: Excludes unnecessary files from Terraform.

## Cost Considerations
- Estimated Costs (post-free tier, us-east-1):
- AWS Config: ~$30/month (100 resources).
- Security Hub: ~$12/month (CIS standard).
- SNS: ~$0.01/month (100 emails).
- Total: ~$42.01/month.
- Free Tier: ~$12/month during Security Hub 30-day trial (Config + SNS).
- Optimization: Test with fewer resources; use terraform destroy to avoid charges.

## Troubleshooting
- No Email Notifications:
   - Confirm SNS subscription is “Confirmed” (see Setup step 4).
   - Verify securityhub_severity_labels in terraform.tfvars matches finding severities.
   - Check EventBridge rule:
   ```bash
   aws events describe-rule --name security-hub-dashboard-securityhub-findings --region us-east-1
   ```


- No Findings:
   - Ensure AWS Config is enabled:
   ```bash
   aws configservice describe-configuration-recorders --region us-east-1
   ```

   - Verify Security Hub is active:
   ```bash
   aws securityhub describe-hub --region us-east-1
   ```

