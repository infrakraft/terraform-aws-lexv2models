
# ============================================================================
# Bot Version Outputs (v1.1.0)
# ============================================================================

output "bot_version" {
  description = "The version number of the bot (if created). Returns null if no version was created."
  value       = module.lex_with_versioning.bot_version
}

output "bot_version_id" {
  description = "The full version identifier including bot ID (if created)"
  value       = module.lex_with_versioning.bot_version_id
}

output "bot_version_arn" {
  description = "The ARN of the bot version (if created)"
  value       = try(module.lex_with_versioning.bot_version_arn, null)
}

output "bot_version_status" {
  description = "The status of the bot version creation"
  value       = try(module.lex_with_versioning.bot_version_status, null)
}