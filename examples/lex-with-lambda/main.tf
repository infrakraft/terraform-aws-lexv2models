# ============================================================================
# Data Sources
# ============================================================================

# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}

# ============================================================================
# Local Variables
# ============================================================================

locals {
  bot_config = jsondecode(file("${path.module}/bot_config.json"))
  namespace  = "${var.environment}-insurance-bot"

  # Lambda configurations
  lambda_functions = {
    claims_handler = {
      namespace   = local.namespace
      description = "Handles insurance claim submissions"
      handler     = "index.handler"
      runtime     = "python3.11"
      timeout     = 30
      memory_size = 512
      s3_bucket   = var.lambda_s3_bucket
      s3_key      = "claims_handler.zip"

      environment_variables = {
        TABLE_NAME = "claims-table"
      }
    }

    policy_lookup = {
      namespace   = local.namespace
      description = "Looks up policy details"
      handler     = "index.handler"
      runtime     = "python3.11"
      timeout     = 10
      memory_size = 256
      s3_bucket   = var.lambda_s3_bucket
      s3_key      = "policy_lookup.zip"
    }
  }
}

# ============================================================================
# Lambda Fulfillment Module
# ============================================================================

module "lambda_fulfillment" {
  source = "../../modules/lambda-fulfillment"

  lambda_functions = local.lambda_functions

  # Enable Lex to invoke these functions
  enable_lex_invocation = true

  # X-Ray tracing (disabled by default to save costs)
  # Enable for production observability if needed
  enable_xray_tracing = var.enable_xray_tracing

  # Publish versions (required for Lex)
  publish_lambda_versions = true

  # Global environment variables
  global_environment_variables = {
    ENVIRONMENT = var.environment
    LOG_LEVEL   = "INFO"
  }

  tags = {
    Environment = var.environment
    Project     = "Insurance Bot"
    ManagedBy   = "Terraform"
  }
}

# ============================================================================
# Lex Bot Module
# ============================================================================

module "lex_bot" {
  source = "../../modules/lexv2models"

  bot_config          = local.bot_config
  lexv2_bot_role_name = "${local.namespace}-lex-role"

  # Connect Lambda functions
  lambda_arns = module.lambda_fulfillment.lambda_qualified_arns

  # Bot Building
  auto_build_bot_locales    = var.auto_build
  wait_for_build_completion = var.wait_for_build

  # Optional: Bot Versioning
  create_bot_version      = var.create_version
  bot_version_description = var.create_version ? "v1.0.0 - Initial release with Lambda fulfillment" : ""

  tags = {
    Environment = var.environment
    Project     = "Insurance Bot"
    ManagedBy   = "Terraform"
  }

  depends_on = [module.lambda_fulfillment]
}