// Declare aws_region variable
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

// Declare siem_datalake_bucket variable
variable "siem_datalake_bucket" {
  description = "The name of the SIEM datalake bucket"
  type        = string
  default     = "cloud-siem-security-datalake"
}

// Declare SNS topic email address variable  
variable "alert_email" {
  description = "The email address to send security alerts to"
  type        = string
  default     = "waliurrahmansun003@gmail.com"
}