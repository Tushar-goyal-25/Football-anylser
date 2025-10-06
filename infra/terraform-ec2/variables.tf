variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "epl-live"
}

variable "instance_type" {
  description = "EC2 instance type (t3.micro is free tier eligible)"
  type        = string
  default     = "t3.small" # Free tier: t3.micro, Recommended: t3.small ($15/month)
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair to access EC2 instance"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Change this to your IP for security
}

variable "football_api_key" {
  description = "Football-Data.org API key"
  type        = string
  sensitive   = true
}

variable "convex_url" {
  description = "Convex deployment URL"
  type        = string
}

variable "convex_deploy_key" {
  description = "Convex deployment key (optional)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_mock_data" {
  description = "Enable mock data for testing"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs (costs extra)"
  type        = bool
  default     = false
}
