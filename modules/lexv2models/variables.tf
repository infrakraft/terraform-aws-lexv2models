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

# ==============================================================================
# Optional — Lambda integration
# ==============================================================================

variable "lambda_functions" {
  description = <<-EOT
    Map of deployed Lambda functions keyed by the logical name used as
    fulfillment_lambda_name in bot_config. Each entry provides the function_name
    and ARN needed to wire fulfillment hooks and grant invoke permissions.

    Example:
      lambda_functions = {
        "MyFulfillmentFn" = {
          function_name = "my-fulfilment-fn"
          arn           = "arn:aws:lambda:eu-west-1:123456789012:function:my-fulfilment-fn"
        }
      }
  EOT
  type = map(object({
    function_name = string
    arn           = string
  }))
  default = {}
}

variable "lambda_arns" {
  description = <<-EOT
    Alternative to lambda_functions: a simple map of logical name → ARN.
    Merged with lambda_functions (this map wins on key overlap). Useful when
    you only have ARNs and not the full function object.
  EOT
  type        = map(string)
  default     = {}
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

variable "cloudwatch_log_group_arn" {
  description = <<-EOT
    ARN of the CloudWatch Log Group to grant Lex conversation logging permissions.
    When null, no CloudWatch IAM policy is created.
    Pair with the cloudwatch-log-group module from this ecosystem.
  EOT
  type        = string
  default     = null
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