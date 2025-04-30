provider "aws" {
  region = var.aws_region
}

# Enable AWS Config
resource "aws_s3_bucket" "config_bucket" {
  bucket = "${var.project_name}-config-${random_string.suffix.result}"
}

resource "aws_s3_bucket_ownership_controls" "config_bucket" {
  bucket = aws_s3_bucket.config_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "config_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.config_bucket]
  bucket     = aws_s3_bucket.config_bucket.id
  acl        = "private"
}

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.config_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config_bucket.arn
      }
    ]
  })
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_config_configuration_recorder" "default" {
  name     = "default"
  role_arn = aws_iam_role.config_role.arn
  recording_group {
    all_supported                 = true
  }
}

resource "aws_iam_role" "config_role" {
  name = "${var.project_name}-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_role_policy" "config_s3_policy" {
  name = "${var.project_name}-config-s3-policy"
  role = aws_iam_role.config_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketAcl"
        ]
        Resource = [
          "${aws_s3_bucket.config_bucket.arn}",
          "${aws_s3_bucket.config_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_config_delivery_channel" "default" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
  depends_on     = [aws_config_configuration_recorder.default]
}

resource "aws_config_configuration_recorder_status" "default" {
  name       = aws_config_configuration_recorder.default.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.default]
}

# Enable AWS Security Hub
resource "aws_securityhub_account" "main" {
  depends_on = [aws_config_configuration_recorder_status.default]
}

resource "aws_securityhub_standards_subscription" "standards" {
  for_each      = var.securityhub_standards_arns
  depends_on    = [aws_securityhub_account.main]
  standards_arn = each.value
}

# SNS topic for notifications
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-security-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# EventBridge rule to trigger SNS on Security Hub findings
resource "aws_cloudwatch_event_rule" "securityhub_findings" {
  name        = "${var.project_name}-securityhub-findings"
  description = "Send Security Hub findings to SNS"
  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = var.securityhub_severity_labels
        }
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.securityhub_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.alerts.arn
  input_transformer {
    input_paths = {
      severity    = "$.detail.findings[0].Severity.Label"
      title       = "$.detail.findings[0].Title"
      description = "$.detail.findings[0].Description"
    }
    input_template = <<EOF
{
  "message": "Security Hub Finding Description: <description>",
  "subject": "<severity> Severity Finding: <title>"
}
EOF
  }
}

resource "aws_sns_topic_policy" "sns_topic_policy" {
  arn = aws_sns_topic.alerts.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}