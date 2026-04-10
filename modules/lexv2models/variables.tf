# ==============================================================================
# Required
# ==============================================================================

variable "bot_config" {
  description = <<-EOT
    Decoded bot configuration object. Must conform to the Lex V2 bot JSON schema
    (see README). Provides all bot, locale, intent, and slot definitions.
  EOT
  type        = any

  validation {
    condition     = can(var.bot_config.name) && can(var.bot_config.locales)
    error_message = "bot_config must contain at least 'name' and 'locales' keys."
  }

  validation {
    condition     = can(tostring(var.bot_config.idle_session_ttl))
    error_message = "bot_config must contain 'idle_session_ttl' (integer, 60–86400)."
  }
}

variable "lexv2_bot_role_name" {
  description = "Name for the IAM role that Lex V2 will assume. Must be unique in your account."
  type        = string

  validation {
    condition     = length(var.lexv2_bot_role_name) >= 1 && length(var.lexv2_bot_role_name) <= 64
    error_message = "lexv2_bot_role_name must be between 1 and 64 characters."
  }
}

variable "lex_bot_alias_id" {
  description = <<-EOT
    Lex V2 bot alias ID used to scope aws_lambda_permission source_arn.
    Defaults to TSTALIASID (the built-in test alias every new bot receives).
    For production, pass the ID of your deployed alias.
  EOT
  type        = string
  default     = "TSTALIASID"
}

# ==============================================================================
# Optional — IAM permissions
# ==============================================================================

variable "polly_arn" {
  description = <<-EOT
    ARN of the Amazon Polly resource to grant speech synthesis permissions.
    Required only when the bot is configured with voice_settings.
    When null, no Polly IAM policy is created.
  EOT
  type        = string
  default     = null
}

variable "enable_cloudwatch_logging" {
  description = <<-EOT
    Whether to create IAM policies for CloudWatch logging.
    When true, cloudwatch_log_group_arn must be provided.
    
    This flag prevents count/computed value errors.
  EOT
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_arn" {
  description = <<-EOT
    ARN of the CloudWatch Log Group to grant Lex conversation logging permissions.
    When empty string, no CloudWatch IAM policy is created.
    
    Required when enable_cloudwatch_logging is true.
    
    Example: "arn:aws:logs:eu-west-1:123456789012:log-group:/aws/lex/my-bot"
  EOT
  type        = string
  default     = ""
}

# ==============================================================================
# Optional — misc
# ==============================================================================

variable "tags" {
  description = "Tags applied to all taggable resources created by this module."
  type        = map(string)
  default     = {}
}

variable "create_bot_version" {
  description = <<-EOT
    Whether to create a numbered bot version from the DRAFT.
    Set to true after testing your bot in DRAFT and you want to create
    an immutable production snapshot.
  EOT
  type        = bool
  default     = false
}

variable "bot_version_description" {
  description = <<-EOT
    Description for the bot version.
    Only used when create_bot_version is true.
    
    Example: "Production release v1.0 - Added booking and payment flows"
  EOT
  type        = string
  default     = ""
}

variable "bot_version_locale_specification" {
  description = <<-EOT
    Optional map of locale_id to source bot version for that locale.
    If not specified, all locales use DRAFT.
    
    Example:
    {
      "en_GB" = "1"
      "es_US" = "1"
    }
  EOT
  type        = map(string)
  default     = {}
}

# ==============================================================================
# Bot Building Configuration (v1.2.0)
# ==============================================================================

variable "auto_build_bot_locales" {
  description = <<-EOT
    Whether to automatically build bot locales after creation/update.
    
    When enabled:
    - Bot locales are built automatically via AWS CLI
    - No manual "Build" button clicking required in AWS Console
    - Bot is ready for testing immediately after deployment
    
    When disabled:
    - Bot remains in "Not Built" state
    - Manual build required in AWS Console
    - Useful for development/testing scenarios
    
    Note: Building can take 1-2 minutes per locale.
  EOT
  type        = bool
  default     = true
}

variable "wait_for_build_completion" {
  description = <<-EOT
    Whether to wait for bot locale build to complete before proceeding.
    
    When true:
    - Terraform waits until build completes (status: Built or ReadyExpressTesting)
    - Ensures bot is ready before moving to next resource
    - Safer for production deployments
    
    When false:
    - Terraform triggers build but doesn't wait
    - Faster deployment but bot may not be ready
    - Useful for large bots or development environments
    
    Only applies when auto_build_bot_locales = true.
  EOT
  type        = bool
  default     = false
}

variable "build_timeout_seconds" {
  description = <<-EOT
    Maximum time (in seconds) to wait for bot locale build to complete.
    Only used when wait_for_build_completion = true.
    
    Typical build times:
    - Simple bots: 30-60 seconds
    - Medium bots: 60-120 seconds
    - Complex bots: 120-300 seconds
    
    Default: 300 seconds (5 minutes)
  EOT
  type        = number
  default     = 300

  validation {
    condition     = var.build_timeout_seconds >= 30 && var.build_timeout_seconds <= 1800
    error_message = "Build timeout must be between 30 and 1800 seconds (30 minutes)."
  }
}

# ============================================================================
# Lambda Integration (v1.4.0)
# ============================================================================

variable "lambda_functions" {
  description = <<-EOT
    Map of Lambda functions available for Lex bot fulfillment.
    Typically comes from the lambda-fulfillment module output.
    
    Example:
    {
      "claims_handler" = {
        function_name = "claims_handler"
        arn           = "arn:aws:lambda:..."
        qualified_arn = "arn:aws:lambda:...:1"
      }
    }
  EOT
  type = map(object({
    function_name = string
    arn           = string
    qualified_arn = optional(string)
  }))
  default = {}
}

variable "lambda_arns" {
  description = <<-EOT
    DEPRECATED: Use lambda_functions instead.
    Map of Lambda function names to ARNs.
  EOT
  type        = map(string)
  default     = {}
}