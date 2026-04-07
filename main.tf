# ============================================================================
# AWS Lex V2 Bot Module
# ============================================================================
# This is the root module that wraps the lexv2models submodule
# ============================================================================

module "lexv2models" {
  source = "./modules/lexv2models"

  # Bot configuration object (passed through from variable)
  bot_config = var.bot_config

  # IAM Role name for Lex bot
  lexv2_bot_role_name = var.lexv2_bot_role_name

  # Lambda integration (optional)
  lambda_functions = var.lambda_functions
  lambda_arns      = var.lambda_arns
  lex_bot_alias_id = var.lex_bot_alias_id

  # IAM permissions (optional)
  polly_arn                = var.polly_arn
  cloudwatch_log_group_arn = var.cloudwatch_log_group_arn

  # Bot Version Configuration (v1.1.0)
  create_bot_version               = var.create_bot_version
  bot_version_description          = var.bot_version_description
  bot_version_locale_specification = var.bot_version_locale_specification

  # Bot Building Configuration (v1.2.0)
  auto_build_bot_locales    = var.auto_build_bot_locales
  wait_for_build_completion = var.wait_for_build_completion
  build_timeout_seconds     = var.build_timeout_seconds

  # Tags
  tags = var.tags
}