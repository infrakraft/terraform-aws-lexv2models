# ============================================================================
# Lambda Function
# ============================================================================

resource "aws_lambda_function" "this" {
  for_each = var.lambda_functions

  function_name                  = each.key
  description                    = each.value.description
  role                           = aws_iam_role.lambda_role[each.key].arn
  handler                        = each.value.handler
  runtime                        = each.value.runtime
  timeout                        = each.value.timeout
  memory_size                    = each.value.memory_size
  reserved_concurrent_executions = lookup(each.value, "reserved_concurrent_executions", -1)

  # S3 deployment
  s3_bucket        = each.value.s3_bucket
  s3_key           = each.value.s3_key
  source_code_hash = lookup(each.value, "source_code_hash", null)

  # KMS encryption (optional)
  kms_key_arn = lookup(each.value, "kms_key_arn", null)

  # Publishing (required for Lex, but configurable)
  publish = var.publish_lambda_versions

  # Environment variables
  dynamic "environment" {
    for_each = (
      length(var.global_environment_variables) > 0 ||
      length(lookup(each.value, "environment_variables", {})) > 0
    ) ? [1] : []

    content {
      variables = merge(
        var.global_environment_variables,
        lookup(each.value, "environment_variables", {})
      )
    }
  }

  # VPC configuration
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []

    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # X-Ray tracing (configurable - can be expensive)
  tracing_config {
    mode = var.enable_xray_tracing ? "Active" : "PassThrough"
  }

  # Dead Letter Queue (optional)
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config != null ? [var.dead_letter_config] : []

    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  # File system config (optional - for EFS)
  dynamic "file_system_config" {
    for_each = var.file_system_config != null ? [var.file_system_config] : []

    content {
      arn              = file_system_config.value.arn
      local_mount_path = file_system_config.value.local_mount_path
    }
  }

  # Image config (for container images)
  dynamic "image_config" {
    for_each = var.image_config != null ? [var.image_config] : []

    content {
      command           = lookup(image_config.value, "command", null)
      entry_point       = lookup(image_config.value, "entry_point", null)
      working_directory = lookup(image_config.value, "working_directory", null)
    }
  }

  # Ephemeral storage (configurable - default 512 MB)
  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_size != null ? [var.ephemeral_storage_size] : []

    content {
      size = ephemeral_storage.value
    }
  }

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      Name      = each.key
      ManagedBy = "Terraform"
      Module    = "lambda-fulfillment"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# Lex Invoke Permissions
# ============================================================================
# Grants Lex V2 permission to invoke Lambda functions
# This is CRITICAL for Lex integration to work
# ============================================================================

resource "aws_lambda_permission" "allow_lex" {
  for_each = var.enable_lex_invocation ? var.lambda_functions : {}

  statement_id  = "AllowLexInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[each.key].function_name
  principal     = "lexv2.amazonaws.com"

  # Allow any Lex bot in this account to invoke
  # More restrictive: specify source_arn for specific bot
  source_account = data.aws_caller_identity.current.account_id

  # Use qualified ARN (includes version) for Lex
  qualifier = var.publish_lambda_versions ? aws_lambda_function.this[each.key].version : null
}

# ============================================================================
# Lambda Aliases (Optional)
# ============================================================================
# Create aliases for different environments (dev, staging, prod)
# ============================================================================

resource "aws_lambda_alias" "this" {
  for_each = var.create_aliases ? var.lambda_functions : {}

  name             = var.alias_name
  description      = "Alias for ${var.alias_name} environment"
  function_name    = aws_lambda_function.this[each.key].function_name
  function_version = aws_lambda_function.this[each.key].version

  lifecycle {
    ignore_changes = [function_version]
  }
}