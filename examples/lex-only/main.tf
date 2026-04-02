locals {
  bot_config = jsondecode(file("${path.module}/bot_config.json"))
}

module "lex" {
  source = "../../modules/lexv2models"

  bot_config          = local.bot_config
  lexv2_bot_role_name = "${var.environment}-${local.bot_config.name}-lex-role"

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ----------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------

output "bot_id" {
  value = module.lex.bot_id
}

output "bot_arn" {
  value = module.lex.bot_arn
}
