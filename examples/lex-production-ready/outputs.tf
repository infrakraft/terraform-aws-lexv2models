# ==============================================================================
# Bot Outputs
# ==============================================================================

output "bot_id" {
  description = "Lex bot ID"
  value       = module.lex_bot.bot_id
}

output "bot_arn" {
  description = "Lex bot ARN"
  value       = module.lex_bot.bot_arn
}

output "bot_name" {
  description = "Lex bot name"
  value       = module.lex_bot.bot_name
}

output "bot_version" {
  description = "Bot version number (if created)"
  value       = module.lex_bot.bot_version
}

# ==============================================================================
# Conversation Logs Outputs
# ==============================================================================

output "cloudwatch_log_group" {
  description = "CloudWatch log group for conversation logs"
  value       = module.conversation_logs.cloudwatch_log_group_name
}

output "audio_logs_bucket" {
  description = "S3 bucket for audio logs"
  value       = module.conversation_logs.s3_bucket_name
}

output "logging_iam_role_arn" {
  description = "IAM role ARN for Lex logging"
  value       = module.conversation_logs.iam_role_arn
}

# ==============================================================================
# Lambda Outputs
# ==============================================================================

# output "lambda_function_name" {
#   description = "Lambda fulfillment function name"
#   value       = var.enable_lambda_fulfillment ? module.lambda_fulfillment[0].function_name : null
# }
output "lambda_function_names" {
  description = "Names of all Lambda functions"
  value       = module.lambda_fulfillment.lambda_function_names
}


# output "lambda_function_arn" {
#   description = "Lambda fulfillment function ARN"
#   value       = var.enable_lambda_fulfillment ? module.lambda_fulfillment[0].function_arn : null
# }

output "lambda_function_arns" {
  description = "ARNs of all Lambda functions"
  value       = module.lambda_fulfillment.lambda_qualified_arns
}

# ==============================================================================
# Deployment Information
# ==============================================================================

output "deployment_info" {
  description = "Complete deployment information"
  value = {
    environment           = var.environment
    bot_id                = module.lex_bot.bot_id
    bot_version           = module.lex_bot.bot_version
    text_logging_enabled  = var.enable_text_logs
    audio_logging_enabled = var.enable_audio_logs
    lambda_enabled        = var.enable_lambda_fulfillment
    cloudwatch_log_group  = module.conversation_logs.cloudwatch_log_group_name
    audio_logs_bucket     = module.conversation_logs.s3_bucket_name
    logging_role_arn      = module.conversation_logs.iam_role_arn
    region                = data.aws_region.current.id
    account_id            = data.aws_caller_identity.current.account_id
  }
}