# ============================================================================
# Data Sources
# ============================================================================

# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}

# ============================================================================
# Local Variables
# ============================================================================
# Get current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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
# Lex Bot Module
# ============================================================================

module "lex_bot" {
  source = "../../modules/lexv2models"

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

# ==============================================================================
# Conversation Logs (CloudWatch + S3)
# ==============================================================================

module "conversation_logs" {
  source = "../../modules/conversation-logs"

  bot_id = module.lex_bot.bot_id

  # Text logs to CloudWatch
  enable_text_logs   = var.enable_text_logs
  log_retention_days = var.log_retention_days

  # Audio logs to S3 (optional)
  enable_audio_logs = var.enable_audio_logs
  s3_bucket_name    = var.enable_audio_logs ? "${var.environment}-lex-audio-logs-${data.aws_caller_identity.current.account_id}" : null
  s3_lifecycle_days = var.audio_log_retention_days

  # Encryption (optional)
  kms_key_id = var.kms_key_id

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "ConversationLogs"
  }

  depends_on = [module.lex_bot]
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

  # X-Ray tracing configuration
  # Development: false (save costs)
  # Production: true (observability)
  enable_xray_tracing = var.environment == "prod" && var.enable_xray_tracing

  # Publish versions (required for Lex)
  publish_lambda_versions = true

  # Global environment variables
  global_environment_variables = {
    ENVIRONMENT = var.environment
    LOG_LEVEL   = var.environment == "prod" ? "INFO" : "DEBUG"
  }

  # Optional: Ephemeral storage (if needed for large file processing)
  ephemeral_storage_size = var.ephemeral_storage_size

  tags = {
    Environment = var.environment
    Project     = "Insurance Bot"
    ManagedBy   = "Terraform"
  }
}



# # ==============================================================================
# # Production-Ready Lex Bot Example
# # ==============================================================================
# # Demonstrates:
# # - Bot versioning for deployments
# # - Conversation logs (CloudWatch + S3)
# # - Advanced slot validation
# # - Lambda fulfillment integration
# # ==============================================================================

# terraform {
#   required_version = ">= 1.0"

#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = ">= 4.0"
#     }
#   }
# }

# provider "aws" {
#   region = var.aws_region
# }

# # Get current AWS account and region
# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}

# # ==============================================================================
# # Lex Bot with Versioning
# # ==============================================================================

# module "lex_bot" {
#   source = "../../modules/lexv2models"

#   bot_config_file = "${path.module}/bot_config.json"
#   environment     = var.environment

#   # Enable bot versioning for production deployments
#   create_bot_version      = var.create_bot_version
#   bot_version_description = var.bot_version_description

#   # Version all locales from DRAFT
#   bot_version_locale_specification = {
#     for locale in ["en_US", "en_GB"] :
#     locale => "DRAFT"
#   }

#   # Build bot and wait for completion
#   wait_for_build_completion = true
#   build_timeout_seconds     = 300

#   tags = {
#     Environment = var.environment
#     ManagedBy   = "Terraform"
#     Purpose     = "ProductionLexBot"
#     Example     = "lex-production-ready"
#   }
# }

# # ==============================================================================
# # Conversation Logs (CloudWatch + S3)
# # ==============================================================================

# module "conversation_logs" {
#   source = "../../modules/conversation-logs"

#   bot_id = module.lex_bot.bot_id

#   # Text logs to CloudWatch
#   enable_text_logs   = var.enable_text_logs
#   log_retention_days = var.log_retention_days

#   # Audio logs to S3 (optional)
#   enable_audio_logs = var.enable_audio_logs
#   s3_bucket_name    = var.enable_audio_logs ? "${var.environment}-lex-audio-logs-${data.aws_caller_identity.current.account_id}" : null
#   s3_lifecycle_days = var.audio_log_retention_days

#   # Encryption (optional)
#   kms_key_id = var.kms_key_id

#   tags = {
#     Environment = var.environment
#     ManagedBy   = "Terraform"
#     Purpose     = "ConversationLogs"
#   }

#   depends_on = [module.lex_bot]
# }

# # ==============================================================================
# # Lambda Fulfillment (Optional)
# # ==============================================================================

# module "lambda_fulfillment" {
#   count  = var.enable_lambda_fulfillment ? 1 : 0
#   source = "../../modules/lambda-fulfillment"

#   function_name = "${var.environment}-customer-service-bot"
#   handler       = "index.handler"
#   runtime       = "python3.11"
#   timeout       = 30
#   memory_size   = 512

#   source_dir = "${path.module}/lambda"

#   environment_variables = {
#     ENVIRONMENT = var.environment
#     LOG_LEVEL   = var.environment == "prod" ? "INFO" : "DEBUG"
#   }

#   # Production settings
#   enable_xray_tracing = var.environment == "prod"

#   # Dead letter queue for failed invocations
#   dead_letter_config = var.environment == "prod" ? {
#     target_arn = aws_sqs_queue.lambda_dlq[0].arn
#   } : null

#   tags = {
#     Environment = var.environment
#     ManagedBy   = "Terraform"
#   }
# }

# # Dead Letter Queue for Lambda (production only)
# resource "aws_sqs_queue" "lambda_dlq" {
#   count = var.enable_lambda_fulfillment && var.environment == "prod" ? 1 : 0

#   name                      = "${var.environment}-lex-lambda-dlq"
#   message_retention_seconds = 1209600 # 14 days

#   tags = {
#     Environment = var.environment
#     ManagedBy   = "Terraform"
#     Purpose     = "LambdaDLQ"
#   }
# }

# # Lambda permission for Lex
# resource "aws_lambda_permission" "lex_invoke" {
#   count = var.enable_lambda_fulfillment ? 1 : 0

#   statement_id  = "AllowLexInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = module.lambda_fulfillment[0].function_name
#   principal     = "lexv2.amazonaws.com"
#   source_arn    = "arn:aws:lex:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:bot-alias/${module.lex_bot.bot_id}/*"
# }

# # ==============================================================================
# # CloudWatch Logs for Lambda (Optional)
# # ==============================================================================
# module "lambda_logs" {
#   source   = "../../modules/cloudwatch-logs"
#   for_each = local.lambda_functions

#   name              = "/aws/lambda/${each.key}"
#   retention_in_days = var.log_retention_days
#   prevent_destroy   = var.environment == "prod"
#   kms_key_id        = var.kms_key_id

#   tags = {
#     Environment  = var.environment
#     LogType      = "LambdaFunction"
#     FunctionName = each.key
#     ManagedBy    = "Terraform"
#   }
# }
# # module "lambda_cloudwatch_logs" {
# #   count  = var.enable_lambda_fulfillment ? 1 : 0
# #   source = "../../modules/cloudwatch-logs"
# #   name              = "/aws/lex/${local.bot_config.name}"
# #   log_group_name    = "/aws/lambda/${module.lambda_fulfillment[0].function_name}"
# #   retention_in_days = var.lambda_log_retention_days

# #   tags = {
# #     Environment = var.environment
# #     ManagedBy   = "Terraform"
# #   }
# # }

# # # ==============================================================================
# # # Production-Ready Lex Bot Example
# # # ==============================================================================
# # # Demonstrates:
# # # - Bot versioning for deployments
# # # - Conversation logs (CloudWatch + S3)
# # # - Advanced slot validation
# # # - Lambda fulfillment integration
# # # ==============================================================================
# # # Get current AWS account and region

# # locals {
# #   bot_config = jsondecode(file("${path.module}/bot_config.json"))
# #   namespace  = "${var.environment}-insurance-bot"

# #   # Lambda configurations
# #   lambda_functions = {
# #     claims_handler = {
# #       namespace   = local.namespace
# #       description = "Handles insurance claim submissions"
# #       handler     = "index.handler"
# #       runtime     = "python3.11"
# #       timeout     = 30
# #       memory_size = 512
# #       s3_bucket   = var.lambda_s3_bucket
# #       s3_key      = "claims_handler.zip"

# #       environment_variables = {
# #         TABLE_NAME = "claims-table"
# #       }
# #     }
# #   }
# # }
# # data "aws_caller_identity" "current" {}
# # data "aws_region" "current" {}

# # # ==============================================================================
# # # Lex Bot with Versioning
# # # ==============================================================================

# # module "lex_bot" {
# #   source = "../../modules/lexv2models"

# #   bot_config          = local.bot_config
# #   lexv2_bot_role_name = "${var.environment}-${local.bot_config.name}-lex-role"

# #   # Enable bot versioning for production deployments
# #   create_bot_version      = var.create_bot_version
# #   bot_version_description = var.bot_version_description

# #   # Version all locales from DRAFT
# #   bot_version_locale_specification = {
# #     for locale in ["en_US", "en_GB"] :
# #     locale => "DRAFT"
# #   }

# #   # Build bot and wait for completion
# #   wait_for_build_completion = true
# #   build_timeout_seconds     = 300

# #   tags = {
# #     Environment = var.environment
# #     ManagedBy   = "Terraform"
# #     Purpose     = "ProductionLexBot"
# #     Example     = "lex-production-ready"
# #   }
# # }

# # # ==============================================================================
# # # Conversation Logs (CloudWatch + S3)
# # # ==============================================================================

# # module "conversation_logs" {
# #   source = "../../modules/conversation-logs"

# #   bot_id = module.lex_bot.bot_id

# #   # Text logs to CloudWatch
# #   enable_text_logs   = var.enable_text_logs
# #   log_retention_days = var.log_retention_days

# #   # Audio logs to S3 (optional)
# #   enable_audio_logs = var.enable_audio_logs
# #   s3_bucket_name    = var.enable_audio_logs ? "${var.environment}-lex-audio-logs-${data.aws_caller_identity.current.account_id}" : null
# #   s3_lifecycle_days = var.audio_log_retention_days

# #   # Encryption (optional)
# #   kms_key_id = var.kms_key_id

# #   tags = {
# #     Environment = var.environment
# #     ManagedBy   = "Terraform"
# #     Purpose     = "ConversationLogs"
# #   }

# #   depends_on = [module.lex_bot]
# # }

# # # ==============================================================================
# # # Lambda Fulfillment (Optional)
# # # ==============================================================================

# # module "lambda_fulfillment" {

# #   source = "../../modules/lambda-fulfillment"

# #   lambda_functions = local.lambda_functions

# #   # Enable Lex to invoke these functions
# #   enable_lex_invocation = true

# #   # X-Ray tracing (disabled by default to save costs)
# #   # Enable for production observability if needed
# #   enable_xray_tracing = var.enable_xray_tracing

# #   # Publish versions (required for Lex)
# #   publish_lambda_versions = true

# #   # Global environment variables
# #   global_environment_variables = {
# #     ENVIRONMENT = var.environment
# #     LOG_LEVEL   = "INFO"
# #   }

# #   tags = {
# #     Environment = var.environment
# #     Project     = "Insurance Bot"
# #     ManagedBy   = "Terraform"
# #   }
# # }

# # # Dead Letter Queue for Lambda (production only)
# # resource "aws_sqs_queue" "lambda_dlq" {
# #   count = var.enable_lambda_fulfillment && var.environment == "prod" ? 1 : 0

# #   name                      = "${var.environment}-lex-lambda-dlq"
# #   message_retention_seconds = 1209600 # 14 days

# #   tags = {
# #     Environment = var.environment
# #     ManagedBy   = "Terraform"
# #     Purpose     = "LambdaDLQ"
# #   }
# # }

# # # Lambda permission for Lex
# # # resource "aws_lambda_permission" "lex_invoke" {
# # #   count = var.enable_lambda_fulfillment ? 1 : 0

# # #   statement_id  = "AllowLexInvoke"
# # #   action        = "lambda:InvokeFunction"
# # #   function_name = module.lambda_fulfillment[0].function_name
# # #   principal     = "lexv2.amazonaws.com"
# # #   source_arn    = "arn:aws:lex:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:bot-alias/${module.lex_bot.bot_id}/*"
# # # }

# # # Lambda permission for Lex
# # resource "aws_lambda_permission" "lex_invoke" {
# #   count = var.enable_lambda_fulfillment && var.environment == "prod" ? 1 : 0

# #   statement_id  = "AllowLexInvoke"
# #   action        = "lambda:InvokeFunction"

# #   # FIX: reference the correct output (likely map-based)
# #   function_name = module.lambda_fulfillment[0].function_names["claims_handler"]

# #   principal  = "lexv2.amazonaws.com"
# #   source_arn = "arn:aws:lex:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:bot-alias/${module.lex_bot.bot_id}/*"
# # }

# # # ==============================================================================
# # # CloudWatch Logs for Lambda (Optional)
# # # ==============================================================================

# # module "lambda_cloudwatch_logs" {
# #   source = "../../modules/cloudwatch-logs"

# #   name              = "/aws/lex/${local.bot_config.name}"
# #   retention_in_days = var.log_retention_days
# #   prevent_destroy   = var.environment == "prod"
# #   kms_key_id        = var.kms_key_id

# #   tags = {
# #     Environment = var.environment
# #     LogType     = "LexConversations"
# #     ManagedBy   = "Terraform"
# #   }
# # }