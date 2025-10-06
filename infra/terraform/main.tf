# Main Terraform configuration for EPL Live Pipeline on AWS

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Store Terraform state in S3 (you'll need to create this bucket first)
  backend "s3" {
    bucket = "epl-live-terraform-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
    # dynamodb_table = "terraform-state-lock"  # Optional: for state locking
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "EPL-Live"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}
