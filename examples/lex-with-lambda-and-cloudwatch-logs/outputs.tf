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

# ============================================================================
# Lambda Outputs
# ============================================================================

output "lambda_function_names" {
  description = "Names of all Lambda functions"
  value       = module.lambda_fulfillment.lambda_function_names
}

output "lambda_function_arns" {
  description = "ARNs of all Lambda functions"
  value       = module.lambda_fulfillment.lambda_qualified_arns
}

# ============================================================================
# CloudWatch Logs Outputs
# ============================================================================

output "lex_log_group_name" {
  description = "Name of the Lex conversation log group"
  value       = module.lex_logs.cloudwatch_log_group_name
}

output "lex_log_group_arn" {
  description = "ARN of the Lex conversation log group"
  value       = module.lex_logs.cloudwatch_log_group_arn
}

output "lambda_log_groups" {
  description = "Map of Lambda function names to log group names"
  value = {
    for k, v in module.lambda_logs : k => v.cloudwatch_log_group_name
  }
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
    lambda_functions   = module.lambda_fulfillment.lambda_function_names
    lex_log_group      = module.lex_logs.cloudwatch_log_group_name
    log_retention_days = var.log_retention_days
    logs_encrypted     = var.kms_key_id != null
    logs_protected     = var.environment == "prod"
    bot_built          = var.auto_build
    version_created    = var.create_version
  }
}