variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-1"
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

variable "lambda_s3_bucket" {
  description = "S3 bucket containing Lambda deployment packages"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch"
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