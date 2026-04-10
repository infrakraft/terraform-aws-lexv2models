# ============================================================================
# Lambda Function Outputs
# ============================================================================

output "lambda_function_arns" {
  description = "ARNs of all Lambda functions"
  value       = { for k, v in aws_lambda_function.this : k => v.arn }
}

output "lambda_function_names" {
  description = "Names of all Lambda functions"
  value       = { for k, v in aws_lambda_function.this : k => v.function_name }
}

output "lambda_qualified_arns" {
  description = "Qualified ARNs (with version) for all Lambda functions - USE THIS for Lex integration"
  value       = { for k, v in aws_lambda_function.this : k => v.qualified_arn }
}

output "lambda_versions" {
  description = "Latest published versions of all Lambda functions"
  value       = { for k, v in aws_lambda_function.this : k => v.version }
}

output "lambda_role_arns" {
  description = "IAM role ARNs for all Lambda functions"
  value       = { for k, v in aws_iam_role.lambda_role : k => v.arn }
}

output "lambda_alias_arns" {
  description = "ARNs of Lambda aliases (if created)"
  value       = var.create_aliases ? { for k, v in aws_lambda_alias.this : k => v.arn } : {}
}

# ============================================================================
# Convenience Output for Lex Integration
# ============================================================================

output "functions" {
  description = "Map of Lambda functions with key details for Lex integration"
  value = {
    for k, v in aws_lambda_function.this : k => {
      function_name = v.function_name
      arn           = v.arn
      qualified_arn = v.qualified_arn
      version       = v.version
    }
  }
}