# AWS Security Hub Compliance Dashboard

## Overview
This project deploys an automated AWS Security Hub compliance dashboard using Terraform. It monitors security findings for the CIS AWS Foundations Benchmark, processes high-severity findings with Lambda, sends alerts via SNS, and visualizes compliance status in a CloudWatch dashboard.

## Features
- **Compliance Monitoring**: Tracks CIS benchmark findings across AWS accounts.
- **Automation**: Lambda processes findings and triggers SNS notifications for critical/high-severity issues.
- **Visualization**: CloudWatch dashboard displays findings by severity and compliance status.
- **Security**: Uses least-privilege IAM roles and encrypted data.

## Prerequisites
- AWS account with administrator access
- Terraform >= 1.0.0
- Python 3.9 for Lambda
- AWS CLI configured

## Setup Instructions
1. Clone the repository:
   ```bash
   git clone <your-repo-url>
   cd aws-security-hub-dashboard