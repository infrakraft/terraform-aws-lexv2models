# # ============================================================================
# # Bot Outputs
# # ============================================================================

# output "bot_id" {
#   description = "The unique identifier of the Lex bot"
#   value       = module.lex_bot.bot_id
# }

# output "bot_name" {
#   description = "The name of the Lex bot"
#   value       = module.lex_bot.bot_name
# }

# output "bot_arn" {
#   description = "The ARN of the Lex bot"
#   value       = module.lex_bot.bot_arn
# }

# # ============================================================================
# # Custom Vocabulary Outputs
# # ============================================================================

# output "vocabulary_s3_bucket" {
#   description = "S3 bucket used for custom vocabulary"
#   value       = aws_s3_bucket.vocabulary.id
# }

# output "vocabulary_status" {
#   description = "Status of custom vocabulary by locale"
#   value       = module.custom_vocabulary.vocabulary_status
# }

# output "vocabulary_locales" {
#   description = "Locales with custom vocabulary configured"
#   value       = module.custom_vocabulary.vocabulary_locales
# }

# output "vocabulary_item_counts" {
#   description = "Number of vocabulary items per locale"
#   value       = module.custom_vocabulary.vocabulary_item_counts
# }

# # ============================================================================
# # Deployment Info
# # ============================================================================

# output "deployment_info" {
#   description = "Complete deployment information"
#   value = {
#     bot_id                = module.lex_bot.bot_id
#     bot_name              = module.lex_bot.bot_name
#     environment           = var.environment
#     vocabulary_bucket     = aws_s3_bucket.vocabulary.id
#     vocabulary_locales    = module.custom_vocabulary.vocabulary_locales
#     vocabulary_item_count = sum([for count in module.custom_vocabulary.vocabulary_item_counts : count])
#     bot_built             = true
#     vocabulary_ready      = var.wait_for_vocabulary
#   }
# }