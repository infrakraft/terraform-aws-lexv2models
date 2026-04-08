
# ============================================================================
# Bot Outputs
# ============================================================================

output "bot_id" {
  description = "The unique identifier of the Lex bot"
  value       = module.lex_bot.bot_id
}

output "bot_name" {
  description = "The name of the Lex bot"
  value       = module.lex_bot.bot_name
}

output "bot_arn" {
  description = "The ARN of the Lex bot"
  value       = module.lex_bot.bot_arn
}

output "bot_role_arn" {
  description = "The ARN of the IAM role used by the bot"
  value       = module.lex_bot.lex_role_arn
}

# ============================================================================
# CloudWatch Logs Outputs
# ============================================================================

output "log_group_name" {
  description = "The name of the CloudWatch log group for conversation logs"
  value       = module.cloudwatch_logs.cloudwatch_log_group_name
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = module.cloudwatch_logs.cloudwatch_log_group_arn
}

# ============================================================================
# Configuration Outputs
# ============================================================================

output "environment" {
  description = "The deployment environment"
  value       = var.environment
}

output "log_retention_days" {
  description = "Number of days logs are retained"
  value       = var.log_retention_days
}

output "logs_protected" {
  description = "Whether logs are protected from deletion"
  value       = var.environment == "prod"
}

# ============================================================================
# Deployment Info
# ============================================================================

output "deployment_info" {
  description = "Complete deployment information"
  value = {
    bot_id             = module.lex_bot.bot_id
    bot_name           = module.lex_bot.bot_name
    environment        = var.environment
    log_group_name     = module.cloudwatch_logs.cloudwatch_log_group_name
    log_retention_days = var.log_retention_days
    logs_encrypted     = var.kms_key_id != null
    logs_protected     = var.environment == "prod"
    auto_build_enabled = var.auto_build
    version_created    = var.create_version
  }
}