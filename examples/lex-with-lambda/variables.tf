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