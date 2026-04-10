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
# Deployment Info
# ============================================================================

output "deployment_info" {
  description = "Complete deployment information"
  value = {
    bot_id           = module.lex_bot.bot_id
    bot_name         = module.lex_bot.bot_name
    environment      = var.environment
    lambda_functions = module.lambda_fulfillment.lambda_function_names
    bot_built        = var.auto_build
    version_created  = var.create_version
  }
}