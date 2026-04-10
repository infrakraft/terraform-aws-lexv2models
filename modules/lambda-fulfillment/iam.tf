# ============================================================================
# Lambda Fulfillment Functions for Lex Bots
# ============================================================================
# Creates Lambda functions optimized for Lex bot fulfillment with:
# - Automatic Lex invoke permissions
# - CloudWatch Logs integration
# - VPC support (optional)
# - Environment variables
# - Versioning and aliases
# ============================================================================

# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}

# ============================================================================
# IAM Assume Role Policy
# ============================================================================

data "aws_iam_policy_document" "lambda_assume_role" {
  for_each = var.lambda_functions

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# ============================================================================
# IAM Role for Lambda Functions
# ============================================================================

resource "aws_iam_role" "lambda_role" {
  for_each = var.lambda_functions

  name               = "${each.value.namespace}-${each.key}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role[each.key].json

  tags = merge(
    var.tags,
    {
      Name      = "${each.value.namespace}-${each.key}-lambda-role"
      ManagedBy = "Terraform"
      Module    = "lambda-fulfillment"
    }
  )
}

# ============================================================================
# CloudWatch Logs Policy
# ============================================================================

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  for_each = var.lambda_functions

  role       = aws_iam_role.lambda_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ============================================================================
# VPC Access Policy (if VPC is configured)
# ============================================================================

resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  for_each = var.vpc_config != null ? var.lambda_functions : {}

  role       = aws_iam_role.lambda_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}