# ============================================================================
# Bot Outputs
# ============================================================================

output "bot_id" {
  description = "The unique identifier of the bot"
  value       = module.lexv2models.bot_id
}

output "bot_arn" {
  description = "The ARN of the bot"
  value       = module.lexv2models.bot_arn
}

output "bot_name" {
  description = "The name of the bot"
  value       = module.lexv2models.bot_name
}

# ============================================================================
# IAM Role Outputs
# ============================================================================

output "lex_role_arn" {
  description = "ARN of the IAM role created for the Lex bot"
  value       = module.lexv2models.lex_role_arn
}

output "lex_role_name" {
  description = "Name of the IAM role created for the Lex bot"
  value       = module.lexv2models.lex_role_name
}

# ============================================================================
# Locale Outputs
# ============================================================================

output "bot_locales" {
  description = "Map of bot locale IDs and their details"
  value       = module.lexv2models.bot_locales
}

# output "bot_locale_ids" {
#   description = "Map of locale keys to their locale IDs"
#   value       = module.lexv2models.bot_locale_ids
# }

# ============================================================================
# Intent Outputs
# ============================================================================

output "intent_details" {
  description = "Map of intent names to their IDs across all locales"
  value       = module.lexv2models.intents
}

# output "intent_details" {
#   description = "Detailed information about all intents"
#   value       = module.lexv2models.intent_details
# }

# ============================================================================
# Slot Outputs
# ============================================================================

output "slots" {
  description = "Map of slot names to their IDs across all intents and locales"
  value       = module.lexv2models.slots
}

# output "slot_type_ids" {
#   description = "Map of slot type names to their IDs across all locales"
#   value       = module.lexv2models.slot_type_ids
# }

# ============================================================================
# Slot Priority Outputs
# ============================================================================

output "slot_types" {
  description = "Map of created custom slot types. Key is '{locale}-{slot_type_name}'."
  value       = module.lexv2models.slot_types
  sensitive   = false
}

# ============================================================================
# Lambda Permission Outputs
# ============================================================================

# output "lambda_permissions" {
#   description = "Lambda permissions created for bot fulfillment"
#   value       = module.lexv2models.lambda_permissions
# }