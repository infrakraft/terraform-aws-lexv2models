locals {
  bot_config = jsondecode(file("${path.module}/bot_config.json"))
}
# CloudWatch Logs Module - Create log group for conversation logs
module "cloudwatch_logs" {
  source = "../../modules/cloudwatch-logs"

  name              = "/aws/lex/${local.bot_config.name}"
  retention_in_days = var.log_retention_days
  prevent_destroy   = var.environment == "prod"
  kms_key_id        = var.kms_key_id # Optional encryption

  tags = {
    Environment = var.environment
    Feature     = "ConversationLogs"
    BotName     = local.bot_config.name
    ManagedBy   = "Terraform"
  }
}

# Lex Bot Module - Create bot with CloudWatch logging enabled
module "lex_bot" {
  source = "../../modules/lexv2models"

  bot_config          = local.bot_config
  lexv2_bot_role_name = "${var.environment}-${local.bot_config.name}-role"

  # CloudWatch Logging (v1.3.0)
  enable_cloudwatch_logging = true
  cloudwatch_log_group_arn  = module.cloudwatch_logs.cloudwatch_log_group_arn

  # Bot Building (v1.2.0)
  auto_build_bot_locales    = var.auto_build
  wait_for_build_completion = var.wait_for_build

  # Optional: Bot Versioning (v1.1.0)
  create_bot_version      = var.create_version
  bot_version_description = var.create_version ? "v1.0.0 - Initial release with CloudWatch logging" : ""


  tags = {
    Environment = var.environment
    Feature     = "ConversationLogs"
    BotName     = local.bot_config.name
    ManagedBy   = "Terraform"
  }
}