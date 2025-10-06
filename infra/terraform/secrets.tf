# AWS Secrets Manager for sensitive credentials

# Football API Key Secret
resource "aws_secretsmanager_secret" "football_api_key" {
  name        = "${var.project_name}-football-api-key"
  description = "Football-Data.org API key for EPL match data"

  tags = {
    Name = "${var.project_name}-football-api-key"
  }
}

resource "aws_secretsmanager_secret_version" "football_api_key" {
  secret_id     = aws_secretsmanager_secret.football_api_key.id
  secret_string = var.football_api_key
}

# Convex URL Secret
resource "aws_secretsmanager_secret" "convex_url" {
  name        = "${var.project_name}-convex-url"
  description = "Convex deployment URL for real-time database"

  tags = {
    Name = "${var.project_name}-convex-url"
  }
}

resource "aws_secretsmanager_secret_version" "convex_url" {
  secret_id     = aws_secretsmanager_secret.convex_url.id
  secret_string = var.convex_url
}

# Convex Deploy Key Secret (optional)
resource "aws_secretsmanager_secret" "convex_deploy_key" {
  count       = var.convex_deploy_key != "" ? 1 : 0
  name        = "${var.project_name}-convex-deploy-key"
  description = "Convex deployment key (optional)"

  tags = {
    Name = "${var.project_name}-convex-deploy-key"
  }
}

resource "aws_secretsmanager_secret_version" "convex_deploy_key" {
  count         = var.convex_deploy_key != "" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.convex_deploy_key[0].id
  secret_string = var.convex_deploy_key
}

# Outputs for secret ARNs
output "football_api_key_secret_arn" {
  value       = aws_secretsmanager_secret.football_api_key.arn
  description = "ARN of the Football API key secret"
  sensitive   = true
}

output "convex_url_secret_arn" {
  value       = aws_secretsmanager_secret.convex_url.arn
  description = "ARN of the Convex URL secret"
  sensitive   = true
}

output "convex_deploy_key_secret_arn" {
  value       = var.convex_deploy_key != "" ? aws_secretsmanager_secret.convex_deploy_key[0].arn : ""
  description = "ARN of the Convex deploy key secret"
  sensitive   = true
}
