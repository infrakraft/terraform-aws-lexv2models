variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# ==============================================================================
# Bot Versioning
# ==============================================================================

variable "create_bot_version" {
  description = "Create a numbered bot version for deployment"
  type        = bool
  default     = false
}

variable "bot_version_description" {
  description = "Description for the bot version"
  type        = string
  default     = "Version created by Terraform"
}

# ==============================================================================
# Conversation Logs
# ==============================================================================

variable "enable_text_logs" {
  description = "Enable text conversation logs to CloudWatch"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "enable_audio_logs" {
  description = "Enable audio conversation logs to S3"
  type        = bool
  default     = false
}

variable "audio_log_retention_days" {
  description = "Days to retain audio logs in S3"
  type        = number
  default     = 90
}

variable "kms_key_id" {
  description = "KMS key ID for log encryption (optional)"
  type        = string
  default     = null
}

# ==============================================================================
# Lambda Fulfillment
# ==============================================================================

variable "enable_lambda_fulfillment" {
  description = "Enable Lambda fulfillment function"
  type        = bool
  default     = false
}

variable "lambda_log_retention_days" {
  description = "Lambda CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "lambda_s3_bucket" {
  description = "S3 bucket containing Lambda deployment packages"
  type        = string
}

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray tracing for Lambda functions (adds cost ~$5-10/month)"
  type        = bool
  default     = false
}

variable "auto_build" {
  description = "Automatically build bot after deployment"
  type        = bool
  default     = true
}

variable "wait_for_build" {
  description = "Wait for bot build to complete"
  type        = bool
  default     = true
}

variable "create_version" {
  description = "Create a bot version"
  type        = bool
  default     = false
}

variable "ephemeral_storage_size" {
  description = "Lambda /tmp storage size in MB (512-10240). Default 512 MB is free."
  type        = number
  default     = null

  validation {
    condition = (
      var.ephemeral_storage_size == null ||
      can(var.ephemeral_storage_size >= 512 && var.ephemeral_storage_size <= 10240)
    )
    error_message = "Ephemeral storage must be between 512 and 10240 MB."
  }
}