// Output SIEM Datalake S3 Bucket Name
output "siem_datalake_bucket_name" {
  description = "The name of the SIEM Datalake S3 Bucket"
  value       = aws_s3_bucket.siem_datalake.id
}

// Output SIEM Datalake KMS Key ARN
output "siem_datalake_kms_arn" {
  description = "The ARN of the KMS Key used for SIEM Datalake encryption"
  value       = aws_kms_key.siem_datalake_kms.arn
}

// Output Glue Database Name
output "glue_database_name" {
  description = "The name of the AWS Glue Catalog Database"
  value       = aws_glue_catalog_database.cloud_siem_db.name
}

// Output SNS Topic ARN
output "sns_topic_arn" {
  description = "The ARN of the SNS Topic for security alerts"
  value       = aws_sns_topic.siem_alerts.arn
}

// Output EventBridge Rule Name
output "eventbridge_rule_name" {
  description = "The name of the EventBridge detection rule"
  value       = aws_cloudwatch_event_rule.siem_access_denied_rule.name
}