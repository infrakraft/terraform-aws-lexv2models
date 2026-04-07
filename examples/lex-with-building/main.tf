locals {
  bot_config = jsondecode(file("${path.module}/bot_config.json"))
}

module "lex_bot_with_building" {
  source = "../../modules/lexv2models"

  bot_config          = local.bot_config
  lexv2_bot_role_name = "${var.environment}-${local.bot_config.name}-lex-role"

  # Bot Building Configuration (v1.2.0)
  auto_build_bot_locales    = true # Build automatically
  wait_for_build_completion = true # Wait for build to finish
  build_timeout_seconds     = 300  # 5 minutes max

  tags = {
    Environment = var.environment
    Feature     = "auto-building"
    ManagedBy   = "Terraform"
  }
}
