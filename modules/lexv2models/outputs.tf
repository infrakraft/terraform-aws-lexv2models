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
