variable "aws_region" {
  description = "AWS region for deployment"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  default     = "security-hub-dashboard"
}

variable "alert_email" {
  description = "Email for SNS notifications"
  type        = string
}

variable "securityhub_standards_arns" {
  description = "List of Security Hub standards ARNs to enable"
  type        = set(string)
  default     = [
    "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
  ]
}

variable "securityhub_severity_labels" {
  description = "List of Security Hub severity labels to trigger notifications"
  type        = list(string)
  default     = ["CRITICAL", "HIGH"]
  validation {
    condition     = alltrue([for label in var.securityhub_severity_labels : contains(["CRITICAL", "HIGH", "MEDIUM", "LOW", "INFORMATIONAL"], label)])
    error_message = "Severity labels must be one of: CRITICAL, HIGH, MEDIUM, LOW, INFORMATIONAL."
  }
}