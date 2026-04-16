variable "bot_id" {
  description = "The ID of the Lex bot"
  type        = string
}

variable "enable_text_logs" {
  description = "Enable text conversation logs to CloudWatch"
  type        = bool
  default     = true
}

variable "enable_audio_logs" {
  description = "Enable audio conversation logs to S3"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch log group name (default: /aws/lex/{bot_id})"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Must be a valid CloudWatch retention period."
  }
}

variable "s3_bucket_name" {
  description = "S3 bucket name for audio logs (required if enable_audio_logs = true)"
  type        = string
  default     = null
}

variable "s3_force_destroy" {
  description = "Allow Terraform to destroy S3 bucket even if not empty"
  type        = bool
  default     = false
}

variable "s3_enable_versioning" {
  description = "Enable S3 bucket versioning for audio logs"
  type        = bool
  default     = true
}

variable "s3_lifecycle_days" {
  description = "Days after which to expire audio logs (null = never expire)"
  type        = number
  default     = 90
}

variable "kms_key_id" {
  description = "KMS key ID/ARN for encrypting logs (null = use AWS managed keys)"
  type        = string
  default     = null
}

variable "iam_role_name" {
  description = "IAM role name for Lex logging (default: {bot_id}-logs-role)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}