// Declare SNS Topic for SIEM Alerts
resource "aws_sns_topic" "siem_alerts" {
  name = "siem-security-alerts"

  tags = {
    Name        = "SIEM Security Alerts Topic"
    Environment = "Production"
  }
}

// Declare SNS Topic Email Subscription
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.siem_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

// Declare SNS Topic Access Policy Allowing EventBridge Publishing
resource "aws_sns_topic_policy" "siem_alerts_policy" {
  arn = aws_sns_topic.siem_alerts.arn

  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "__default_policy_ID"
    Statement = [
      {
        Sid    = "__default_statement_ID"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "SNS:Publish",
          "SNS:RemovePermission",
          "SNS:SetTopicAttributes",
          "SNS:DeleteTopic",
          "SNS:ListSubscriptionsByTopic",
          "SNS:GetTopicAttributes",
          "SNS:AddPermission",
          "SNS:Subscribe"
        ]
        Resource = aws_sns_topic.siem_alerts.arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AllowEventBridgeToPublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.siem_alerts.arn
      }
    ]
  })
}