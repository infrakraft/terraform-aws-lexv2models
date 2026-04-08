# ==============================================================================
# Required
# ==============================================================================

variable "name" {
  description = <<-EOT
    Name of the CloudWatch Log Group.

    This must be unique within the AWS account and region.
    Common convention is to prefix with the service name.

    Example:
      "/aws/lex/my-bot"
  EOT
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 512
    error_message = "Log group name must be between 1 and 512 characters."
  }
}

# ==============================================================================
# Optional — Log retention & encryption
# ==============================================================================

variable "retention_in_days" {
  description = <<-EOT
    Number of days to retain log events in the CloudWatch Log Group.

    After the retention period expires, logs are automatically deleted.

    Common values:
      - 7    → Short-lived environments (dev/test)
      - 30   → Standard retention
      - 90   → Extended debugging
      - 365  → Production/audit use cases

    Set to 0 to keep logs indefinitely (not recommended for cost control).
  EOT
  type        = number
  default     = 365

  validation {
    condition     = var.retention_in_days >= 0
    error_message = "retention_in_days must be 0 or greater."
  }
}

variable "kms_key_id" {
  description = <<-EOT
    ARN of the KMS key used to encrypt log data at rest.

    When provided:
    - CloudWatch Logs will use this key for encryption
    - Ensures compliance with security requirements

    When null:
    - Default CloudWatch Logs encryption is used

    Example:
      "arn:aws:kms:eu-west-1:123456789012:key/abcd-1234..."
  EOT
  type        = string
  default     = null
}

# ==============================================================================
# Optional — Resource behavior
# ==============================================================================

variable "prevent_destroy" {
  description = <<-EOT
    Whether to enable Terraform's prevent_destroy lifecycle rule.

    When true:
    - Prevents accidental deletion of the log group
    - Terraform will fail if a destroy is attempted

    Recommended:
    - true  → Production environments
    - false → Development and ephemeral environments
  EOT
  type        = bool
  default     = false
}

# ==============================================================================
# Optional — Tags
# ==============================================================================

variable "tags" {
  description = <<-EOT
    Map of tags to apply to the CloudWatch Log Group.

    Tags help with:
    - Cost allocation
    - Resource organization
    - Access control (IAM conditions)

    Example:
      {
        Environment = "prod"
        Service     = "lex-bot"
      }
  EOT
  type        = map(string)
  default     = {}
}