# Outputs
output "bot_id" {
  description = "The bot ID"
  value       = module.lex_bot_with_building.bot_id
}

output "bot_name" {
  description = "The bot name"
  value       = module.lex_bot_with_building.bot_name
}

output "bot_role_arn" {
  description = "The bot IAM role ARN"
  value       = module.lex_bot_with_building.lex_role_arn
}

output "bot_build_triggered" {
  description = "Whether bot build was triggered"
  value       = module.lex_bot_with_building.bot_build_triggered
}

output "bot_locales_to_build" {
  description = "Locales that were built"
  value       = module.lex_bot_with_building.bot_locales_to_build
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    bot_id             = module.lex_bot_with_building.bot_id
    build_triggered    = module.lex_bot_with_building.bot_build_triggered
    locales_built      = module.lex_bot_with_building.bot_locales_to_build
    deployment_message = "Bot is built and ready for testing!"
  }
}