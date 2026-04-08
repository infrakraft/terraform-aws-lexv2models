variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain conversation logs"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Retention days must be a valid CloudWatch Logs retention period."
  }
}

variable "kms_key_id" {
  description = "Optional KMS key ID/ARN for encrypting logs"
  type        = string
  default     = null
}

variable "auto_build" {
  description = "Whether to automatically build the bot"
  type        = bool
  default     = true
}

variable "wait_for_build" {
  description = "Whether to wait for bot build completion"
  type        = bool
  default     = false
}

variable "create_version" {
  description = "Whether to create a bot version"
  type        = bool
  default     = false
}