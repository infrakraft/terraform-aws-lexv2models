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
# CloudWatch Log Groups
# ============================================================================

# Lex conversation logs
module "lex_logs" {
  source = "../../modules/cloudwatch-logs"

  name              = "/aws/lex/${local.bot_config.name}"
  retention_in_days = var.log_retention_days
  prevent_destroy   = var.environment == "prod"
  kms_key_id        = var.kms_key_id

  tags = {
    Environment = var.environment
    LogType     = "LexConversations"
    ManagedBy   = "Terraform"
  }
}

# Lambda function logs
module "lambda_logs" {
  source   = "../../modules/cloudwatch-logs"
  for_each = local.lambda_functions

  name              = "/aws/lambda/${each.key}"
  retention_in_days = var.log_retention_days
  prevent_destroy   = var.environment == "prod"
  kms_key_id        = var.kms_key_id

  tags = {
    Environment  = var.environment
    LogType      = "LambdaFunction"
    FunctionName = each.key
    ManagedBy    = "Terraform"
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

  # Global environment variables
  global_environment_variables = {
    ENVIRONMENT = var.environment
    LOG_LEVEL   = var.environment == "prod" ? "INFO" : "DEBUG"
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
  source = "../.."

  bot_config          = local.bot_config
  lexv2_bot_role_name = "${local.namespace}-lex-role"

  # Connect Lambda functions
  lambda_arns = module.lambda_fulfillment.lambda_qualified_arns

  # CloudWatch Logging
  enable_cloudwatch_logging = true
  cloudwatch_log_group_arn  = module.lex_logs.cloudwatch_log_group_arn

  # Bot Building
  auto_build_bot_locales    = var.auto_build
  wait_for_build_completion = var.wait_for_build

  # Optional: Bot Versioning
  create_bot_version      = var.create_version
  bot_version_description = var.create_version ? "v1.0.0 - Production release with logging" : ""

  tags = {
    Environment = var.environment
    Project     = "Insurance Bot"
    ManagedBy   = "Terraform"
  }

  depends_on = [
    module.lambda_fulfillment,
    module.lex_logs,
    module.lambda_logs
  ]
}