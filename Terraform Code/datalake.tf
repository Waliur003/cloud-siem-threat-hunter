// Declare SIEM Datalake S3 Bucket
resource "aws_s3_bucket" "siem_datalake" {
  bucket        = var.siem_datalake_bucket
  force_destroy = true

  tags = {
    Name        = "SIEM Datalake Bucket"
    Environment = "Production"
  }
}

// Declare KMS Key for SIEM Datalake Bucket & CloudTrail Encryption
resource "aws_kms_key" "siem_datalake_kms" {
  description             = "KMS key for SIEM datalake bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail to Encrypt Logs"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "SIEM Datalake KMS Key"
    Environment = "Production"
  }
}

// Declare KMS Key Alias
resource "aws_kms_alias" "siem_datalake_kms_alias" {
  name          = "alias/siem-datalake-key"
  target_key_id = aws_kms_key.siem_datalake_kms.key_id
}

// Declare Server-Side Encryption Configuration using KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "siem_datalake_encryption" {
  bucket = aws_s3_bucket.siem_datalake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.siem_datalake_kms.arn
    }
  }
}

// Declare Public Access Block Configuration for SIEM Datalake Bucket
resource "aws_s3_bucket_public_access_block" "siem_datalake_public_access_block" {
  bucket = aws_s3_bucket.siem_datalake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// Declare S3 Bucket Policy to Allow CloudTrail Log Delivery
resource "aws_s3_bucket_policy" "siem_datalake_policy" {
  bucket = aws_s3_bucket.siem_datalake.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.siem_datalake.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.siem_datalake.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

// Declare AWS CloudTrail Resource Pointing to SIEM Datalake Bucket
resource "aws_cloudtrail" "siem_datalake_trail" {
  name                          = "siem-cloudtrail-stream"
  s3_bucket_name                = aws_s3_bucket.siem_datalake.id
  kms_key_id                    = aws_kms_key.siem_datalake_kms.arn
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.siem_datalake.arn}/"]
    }
  }

  tags = {
    Name        = "SIEM Datalake CloudTrail"
    Environment = "Production"
  }

  depends_on = [
    aws_s3_bucket_policy.siem_datalake_policy
  ]
}
