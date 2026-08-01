// 1. Declare EventBridge Rule for AccessDenied Alerts
resource "aws_cloudwatch_event_rule" "siem_access_denied_rule" {
  name        = "SIEM-AccessDenied-Detection-Rule"
  description = "Triggers alerts when AccessDenied or UnauthorizedOperation errors occur"

  event_pattern = jsonencode({
    source = ["aws.s3", "custom.siem"]
    detail = {
      errorCode = ["AccessDenied", "UnauthorizedOperation"]
    }
  })

  tags = {
    Name        = "SIEM AccessDenied Detection Rule"
    Environment = "Production"
  }
}

// 2. Declare EventBridge Target to SNS Topic
resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.siem_access_denied_rule.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.siem_alerts.arn
}