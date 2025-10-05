# Terraform configuration for Live EPL AWS infrastructure
# This is a starter template - customize for your needs

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  default     = "live-epl"
}

# VPC for MSK and ECS
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Subnets
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.project_name}-private-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "${var.project_name}-private-2"
  }
}

# DynamoDB Table
resource "aws_dynamodb_table" "matches" {
  name         = "epl-live-matches"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "match_id"

  attribute {
    name = "match_id"
    type = "S"
  }

  tags = {
    Name = "${var.project_name}-matches"
  }
}

# S3 Bucket for snapshots
resource "aws_s3_bucket" "snapshots" {
  bucket = "${var.project_name}-match-snapshots-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-snapshots"
  }
}

resource "aws_s3_bucket_versioning" "snapshots" {
  bucket = aws_s3_bucket.snapshots.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ECR Repositories
resource "aws_ecr_repository" "producer" {
  name                 = "${var.project_name}-producer"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "consumer" {
  name                 = "${var.project_name}-consumer"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Data sources
data "aws_caller_identity" "current" {}

# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.matches.name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.snapshots.bucket
}

output "producer_ecr_url" {
  value = aws_ecr_repository.producer.repository_url
}

output "consumer_ecr_url" {
  value = aws_ecr_repository.consumer.repository_url
}
