// 1. Declare Athena Workgroup with Encrypted S3 Output
resource "aws_athena_workgroup" "siem_workgroup" {
  name = "siem_workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.siem_datalake.id}/athena-query-results/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = aws_kms_key.siem_datalake_kms.arn
      }
    }
  }
}

// 2. Query 1: Live CloudTrail Stream
resource "aws_athena_named_query" "siem_01_live_cloudtrail_stream" {
  name      = "SIEM_01_Live_CloudTrail_Stream"
  workgroup = aws_athena_workgroup.siem_workgroup.id
  database  = "default"
  query     = "SELECT eventtime, eventsource, eventname, sourceipaddress, useridentity.username AS actor FROM default.cloudtrail_logs_cloud_siem_security_datalake_cloudtrail ORDER BY eventtime DESC LIMIT 10;"
}

// 3. Query 2: Hunt Access Denied Anomalies
resource "aws_athena_named_query" "siem_02_hunt_access_denied" {
  name      = "SIEM_02_Hunt_Access_Denied"
  workgroup = aws_athena_workgroup.siem_workgroup.id
  database  = "default"
  query     = "SELECT eventtime, useridentity.username AS actor, sourceipaddress, eventsource, eventname, errorcode, errormessage FROM default.cloudtrail_logs_cloud_siem_security_datalake_cloudtrail WHERE errorcode IS NOT NULL AND (errorcode LIKE '%Denied%' OR errorcode LIKE '%Unauthorized%') ORDER BY eventtime DESC LIMIT 20;"
}

// 4. Query 3: Detect Root Account Usage
resource "aws_athena_named_query" "siem_03_detect_root_account" {
  name      = "SIEM_03_Detect_Root_Account"
  workgroup = aws_athena_workgroup.siem_workgroup.id
  database  = "default"
  query     = "SELECT eventtime, eventsource, eventname, sourceipaddress, useragent FROM default.cloudtrail_logs_cloud_siem_security_datalake_cloudtrail WHERE useridentity.type = 'Root' ORDER BY eventtime DESC;"
}

// 5. Query 4: Hunt Rejected VPC Flow Logs
resource "aws_athena_named_query" "siem_04_hunt_rejected_vpc" {
  name      = "SIEM_04_Hunt_Rejected_VPC"
  workgroup = aws_athena_workgroup.siem_workgroup.id
  database  = aws_glue_catalog_database.cloud_siem_db.name
  query     = "SELECT srcaddr AS attacker_ip, dstaddr AS target_internal_ip, dstport AS targeted_port, action, COUNT(*) AS total_blocked_packets FROM cloud_siem_db.vpc_flow_logs WHERE action = 'REJECT' GROUP BY srcaddr, dstaddr, dstport, action ORDER BY total_blocked_packets DESC LIMIT 20;"
}