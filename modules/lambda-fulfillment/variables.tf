# ============================================================================
# Lambda Functions Configuration
# ============================================================================

variable "lambda_functions" {
  description = <<-EOT
    Map of Lambda function configurations for Lex bot fulfillment.
    
    Each Lambda must include:
    - namespace: Resource naming prefix
    - description: Function description
    - handler: Entry point (e.g., "index.handler")
    - runtime: Runtime environment (e.g., "python3.11", "nodejs18.x")
    - timeout: Execution timeout in seconds (max: 900)
    - memory_size: Memory allocation in MB (128-10240)
    - s3_bucket: S3 bucket containing deployment package
    - s3_key: S3 object key for deployment package
    
    Optional:
    - environment_variables: Function-specific env vars
    - kms_key_arn: KMS key for encryption
    - reserved_concurrent_executions: Reserved concurrency (-1 = unlimited)
    - source_code_hash: Base64 hash of deployment package
    - tags: Additional tags
  EOT

  type = map(object({
    namespace                      = string
    description                    = string
    handler                        = string
    runtime                        = string
    timeout                        = number
    memory_size                    = number
    s3_bucket                      = string
    s3_key                         = string
    kms_key_arn                    = optional(string)
    reserved_concurrent_executions = optional(number, -1)
    source_code_hash               = optional(string)
    environment_variables          = optional(map(string), {})
    tags                           = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for k, v in var.lambda_functions :
      v.timeout >= 1 && v.timeout <= 900
    ])
    error_message = "Lambda timeout must be between 1 and 900 seconds."
  }

  validation {
    condition = alltrue([
      for k, v in var.lambda_functions :
      v.memory_size >= 128 && v.memory_size <= 10240
    ])
    error_message = "Lambda memory_size must be between 128 and 10240 MB."
  }
}

# ============================================================================
# Environment Variables
# ============================================================================

variable "global_environment_variables" {
  description = "Global environment variables applied to all Lambda functions"
  type        = map(string)
  default     = {}
}

# ============================================================================
# VPC Configuration
# ============================================================================

variable "vpc_config" {
  description = <<-EOT
    Optional VPC configuration for Lambda functions.
    Required for accessing VPC resources (RDS, ElastiCache, etc.)
    
    Example:
    {
      subnet_ids         = ["subnet-abc123", "subnet-def456"]
      security_group_ids = ["sg-xyz789"]
    }
  EOT

  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })

  default = null
}

# ============================================================================
# Lex Integration
# ============================================================================

variable "enable_lex_invocation" {
  description = <<-EOT
    Whether to grant Lex permission to invoke Lambda functions.
    Set to true when using these Lambdas for Lex bot fulfillment.
    
    This creates aws_lambda_permission resources allowing lexv2.amazonaws.com
    to invoke the functions.
  EOT
  type        = bool
  default     = true
}

# ============================================================================
# Lambda Aliases
# ============================================================================

variable "create_aliases" {
  description = "Whether to create Lambda aliases (e.g., dev, staging, prod)"
  type        = bool
  default     = false
}

variable "alias_name" {
  description = "Name of the Lambda alias (only used if create_aliases is true)"
  type        = string
  default     = "live"
}

# ============================================================================
# Tags
# ============================================================================

variable "tags" {
  description = "Tags to apply to all Lambda resources"
  type        = map(string)
  default     = {}
}