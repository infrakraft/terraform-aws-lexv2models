variable "aws_region" {
  description = "AWS region for deployment"
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

variable "wait_for_vocabulary" {
  description = "Wait for custom vocabulary to be ready before completing"
  type        = bool
  default     = true
}

variable "vocabulary_timeout" {
  description = "Maximum time to wait for vocabulary import (seconds)"
  type        = number
  default     = 300
  
  validation {
    condition     = var.vocabulary_timeout >= 30 && var.vocabulary_timeout <= 600
    error_message = "Timeout must be between 30 and 600 seconds."
  }
}