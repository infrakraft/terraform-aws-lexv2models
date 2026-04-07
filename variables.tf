# ==============================================================================
# Required Variables
# ==============================================================================

variable "bot_config" {
  description = <<-EOT
    Decoded bot configuration object. Must conform to the Lex V2 bot JSON schema.
    
    Required fields:
    - name: Bot name
    - locales: Map of locale configurations
    - idle_session_ttl: Session timeout (60-86400 seconds)
    - data_privacy: Object with child_directed boolean
    
    Optional fields:
    - description: Bot description
    - bot_type: "Bot" or "BotNetwork"
    - test_bot_alias_tags: Tags for test alias
    
    Example:
    {
      name               = "MyBot"
      description        = "Customer service bot"
      idle_session_ttl   = 300
      data_privacy       = { child_directed = false }
      locales = {
        en_US = {
          locale_id                = "en_US"
          description              = "English US"
          nlu_confidence_threshold = 0.4
          voice_settings = {
            voice_id = "Joanna"
          }
          intents = {
            BookRoom = {
              description = "Book a room"
              sample_utterances = [
                { utterance = "I want to book a room" }
              ]
              slots = [...]
              slot_priorities = [...]
            }
          }
          slot_types = {...}
        }
      }
    }
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
# Optional Variables - Lambda Integration
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
    
    Example:
      lambda_arns = {
        "MyFulfillmentFn" = "arn:aws:lambda:eu-west-1:123456789012:function:my-fn"
      }
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
# Optional Variables - IAM Permissions
# ==============================================================================

variable "polly_arn" {
  description = <<-EOT
    ARN of the Amazon Polly resource to grant speech synthesis permissions.
    Required only when the bot is configured with voice_settings.
    When null, no Polly IAM policy is created.
    
    Example: "arn:aws:polly:eu-west-1:123456789012:lexicon/my-lexicon"
  EOT
  type        = string
  default     = null
}

variable "cloudwatch_log_group_arn" {
  description = <<-EOT
    ARN of the CloudWatch Log Group to grant Lex conversation logging permissions.
    When null, no CloudWatch IAM policy is created.
    
    Example: "arn:aws:logs:eu-west-1:123456789012:log-group:/aws/lex/my-bot"
  EOT
  type        = string
  default     = null
}

# ==============================================================================
# Optional Variables - Tagging
# ==============================================================================

variable "tags" {
  description = "Tags applied to all taggable resources created by this module."
  type        = map(string)
  default     = {}
}

# ==============================================================================
# Bot Version Configuration (v1.1.0)
# ==============================================================================

variable "create_bot_version" {
  description = <<-EOT
    Whether to create a versioned snapshot of the bot.
    Set to true when you want to create a stable, immutable version for production.
    Once created, versions cannot be modified - only new versions can be created.
  EOT
  type        = bool
  default     = false
}

variable "bot_version_description" {
  description = <<-EOT
    Description for the bot version.
    Useful for documenting what changed in this version.
    Only used when create_bot_version is true.
    
    Example: "Production release v1.0 - Added checkout flow and payment processing"
  EOT
  type        = string
  default     = ""
}

variable "bot_version_locale_specification" {
  description = <<-EOT
    Map of locale-specific source bot versions.
    If not specified, uses the DRAFT version for all locales.
    
    Example:
    {
      "en_US" = "1"
      "es_ES" = "2"
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
    
    When enabled, bot is ready for testing immediately without manual builds.
    When disabled, manual build required in AWS Console.
    
    Default: true (recommended for most use cases)
  EOT
  type        = bool
  default     = true
}

variable "wait_for_build_completion" {
  description = <<-EOT
    Whether to wait for bot locale build to complete before proceeding.
    
    Recommended settings:
    - Production: true (ensures bot is ready)
    - Development: false (faster iterations)
    
    Default: false (faster deployments)
  EOT
  type        = bool
  default     = false
}

variable "build_timeout_seconds" {
  description = <<-EOT
    Maximum time to wait for bot locale build to complete.
    Only used when wait_for_build_completion = true.
    
    Default: 300 seconds (5 minutes)
  EOT
  type        = number
  default     = 300
}