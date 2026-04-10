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
# X-Ray Tracing (NEW - Configurable)
# ============================================================================

variable "enable_xray_tracing" {
  description = <<-EOT
    Enable AWS X-Ray tracing for Lambda functions.
    
    When enabled:
    - Provides distributed tracing across services
    - Helps debug performance issues
    - Visualize request flows
    - **Cost:** ~$5 per million traces + $0.50 per million traces retrieved
    
    When disabled:
    - Lower cost
    - Less observability
    - Use CloudWatch Logs only
    
    Recommendation:
    - Development: false (save cost)
    - Staging: true (testing)
    - Production: true (observability) or false (cost-sensitive)
  EOT
  type        = bool
  default     = false

  # Changed from true to false to save costs by default
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

# ============================================================================
# Lambda Publishing (NEW - Configurable)
# ============================================================================

variable "publish_lambda_versions" {
  description = <<-EOT
    Whether to publish Lambda function versions.
    
    **Required for Lex integration** - Lex needs versioned (qualified) ARNs.
    
    When true:
    - Creates numbered versions ($LATEST, 1, 2, 3...)
    - Enables aliases
    - Required for Lex bot integration
    
    When false:
    - Only $LATEST version exists
    - Cannot use with Lex (Lex requires qualified ARNs)
    - Slightly faster deployments
    
    **Must be true** if using with Lex bots.
  EOT
  type        = bool
  default     = true
}

# ============================================================================
# Dead Letter Queue (NEW - Optional)
# ============================================================================

variable "dead_letter_config" {
  description = <<-EOT
    Dead Letter Queue configuration for failed Lambda invocations.
    
    Example:
    {
      target_arn = aws_sqs_queue.dlq.arn
    }
  EOT

  type = object({
    target_arn = string
  })

  default = null
}

# ============================================================================
# Ephemeral Storage (NEW - Optional)
# ============================================================================

variable "ephemeral_storage_size" {
  description = <<-EOT
    Size of Lambda's /tmp directory in MB.
    
    Default: 512 MB (included in pricing)
    Maximum: 10240 MB (10 GB)
    
    Additional cost: $0.0000000309 per GB-second above 512 MB
    
    Use when:
    - Processing large files
    - Need temporary storage
    - Extracting archives
  EOT

  type    = number
  default = null

  validation {
    condition     = var.ephemeral_storage_size == null || (var.ephemeral_storage_size >= 512 && var.ephemeral_storage_size <= 10240)
    error_message = "Ephemeral storage must be between 512 and 10240 MB."
  }
}

# ============================================================================
# File System Config (NEW - Optional EFS)
# ============================================================================

variable "file_system_config" {
  description = <<-EOT
    EFS file system configuration for Lambda.
    
    Example:
    {
      arn              = aws_efs_access_point.lambda.arn
      local_mount_path = "/mnt/efs"
    }
    
    Requires:
    - VPC configuration
    - EFS file system in same VPC
  EOT

  type = object({
    arn              = string
    local_mount_path = string
  })

  default = null
}

# ============================================================================
# Image Config (NEW - Optional for Container Images)
# ============================================================================

variable "image_config" {
  description = <<-EOT
    Configuration for Lambda functions using container images.
    
    Example:
    {
      command           = ["/app/handler"]
      entry_point       = ["/usr/bin/python"]
      working_directory = "/app"
    }
  EOT

  type = object({
    command           = optional(list(string))
    entry_point       = optional(list(string))
    working_directory = optional(string)
  })

  default = null
}
