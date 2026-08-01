// Declare Terraform & Provider block
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

// Declare AWS Provider
provider "aws" {
  region = var.aws_region
}

// Get current AWS Account ID dynamically
data "aws_caller_identity" "current" {}