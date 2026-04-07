output "bot_id" {
  description = "The unique ID of the Lex V2 bot."
  value       = aws_lexv2models_bot.this.id
}

output "bot_name" {
  description = "The name of the Lex V2 bot."
  value       = aws_lexv2models_bot.this.name
}

output "bot_arn" {
  description = "The ARN of the Lex V2 bot."
  value       = aws_lexv2models_bot.this.arn
}

output "lex_role_arn" {
  description = "ARN of the IAM role Lex V2 assumes. Useful for attaching additional policies."
  value       = aws_iam_role.lex_role.arn
}

output "lex_role_name" {
  description = "Name of the IAM role Lex V2 assumes."
  value       = aws_iam_role.lex_role.name
}

output "bot_locales" {
  description = "List of locale IDs configured on the bot (e.g. en_US, en_GB)."
  value       = keys(local.locales)
}

output "intents" {
  description = "Map of created intents. Key is '{locale}-{intent_name}'. Value contains intent_id, name, and locale."
  value = {
    for k, v in aws_lexv2models_intent.intents :
    k => {
      intent_id = v.intent_id
      name      = v.name
      locale    = v.locale_id
    }
  }
}

output "slots" {
  description = "Map of created slots. Key is '{locale}-{intent}-{slot_name}'. Value contains slot_id, name, intent_id, and locale."
  value = {
    for k, v in aws_lexv2models_slot.slots :
    k => {
      slot_id   = v.slot_id
      name      = v.name
      intent_id = v.intent_id
      locale    = v.locale_id
    }
  }
}

output "slot_types" {
  description = "Map of created custom slot types. Key is '{locale}-{slot_type_name}'."
  value = {
    for k, v in aws_lexv2models_slot_type.slot_types :
    k => {
      slot_type_id = v.slot_type_id
      name         = v.name
      locale       = v.locale_id
    }
  }
}

# ==============================================================================
# Bot Version Outputs (v1.1.0)
# ==============================================================================

output "bot_version" {
  description = "The version number of the bot (e.g., '1', '2', '3'). Returns null if no version was created."
  value       = var.create_bot_version ? aws_lexv2models_bot_version.this[0].bot_version : null
}

output "bot_version_id" {
  description = "The full bot version identifier. Returns null if no version was created."
  value       = var.create_bot_version ? aws_lexv2models_bot_version.this[0].id : null
}

# output "bot_version_arn" {
#   description = "The ARN of the bot version. Returns null if no version was created."
#   value       = var.create_bot_version ? aws_lexv2models_bot_version.this[0].bot_version_arn : null
# }

output "bot_version_arn" {
  description = "The ARN of the bot version. Returns null if no version was created."
  value       = var.create_bot_version ? aws_lexv2models_bot_version.this[0].id : null
}

# ==============================================================================
# Bot Building Outputs (v1.2.0)
# ==============================================================================

output "bot_build_triggered" {
  description = "Whether bot locale builds were triggered. Returns true if auto_build_bot_locales is enabled."
  value       = var.auto_build_bot_locales
}

output "bot_locales_to_build" {
  description = "List of locale IDs that were triggered for building"
  value       = var.auto_build_bot_locales ? keys(local.locales) : []
}