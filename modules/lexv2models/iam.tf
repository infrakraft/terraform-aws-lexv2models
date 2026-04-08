# ==============================================================================
# Trust relationship — allows Lex V2 to assume the bot role
# ==============================================================================

data "aws_iam_policy_document" "lex_trust_relationship" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lexv2.amazonaws.com"]
    }
  }
}

# ==============================================================================
# Core IAM role
# ==============================================================================

resource "aws_iam_role" "lex_role" {
  name                 = var.lexv2_bot_role_name
  assume_role_policy   = data.aws_iam_policy_document.lex_trust_relationship.json
  max_session_duration = 43200
  tags                 = var.tags
}

# ==============================================================================
# Polly — text-to-speech (created only when polly_arn is provided)
# ==============================================================================

data "aws_iam_policy_document" "allow_synthesize_speech" {
  count = var.polly_arn != null ? 1 : 0

  statement {
    sid       = "AllowPollyTTS"
    effect    = "Allow"
    actions   = ["polly:SynthesizeSpeech"]
    resources = [var.polly_arn]
  }
}

resource "aws_iam_policy" "allow_synthesize_speech" {
  count  = var.polly_arn != null ? 1 : 0
  name   = "${local.bot_name}-polly-tts-policy"
  policy = data.aws_iam_policy_document.allow_synthesize_speech[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "allow_synthesize_speech" {
  count      = var.polly_arn != null ? 1 : 0
  role       = aws_iam_role.lex_role.name
  policy_arn = aws_iam_policy.allow_synthesize_speech[0].arn
}

# ==============================================================================
# CloudWatch — conversation logging (created only when log group ARN is provided)
# ==============================================================================

data "aws_iam_policy_document" "allow_cloudwatch_logging" {
  count = var.enable_cloudwatch_logging ? 1 : 0
  statement {
    sid    = "AllowLexCloudWatchLogging"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      var.cloudwatch_log_group_arn,
      "${var.cloudwatch_log_group_arn}:*" # Allow actions on log streams
    ]
  }
}

resource "aws_iam_policy" "allow_cloudwatch_logging" {
  count  = var.enable_cloudwatch_logging ? 1 : 0
  name   = "${local.bot_name}-cloudwatch-logging-policy"
  policy = data.aws_iam_policy_document.allow_cloudwatch_logging[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "allow_cloudwatch_logging" {
  count      = var.enable_cloudwatch_logging ? 1 : 0
  role       = aws_iam_role.lex_role.name
  policy_arn = aws_iam_policy.allow_cloudwatch_logging[0].arn
}

# data "aws_iam_policy_document" "allow_cloudwatch_logging" {
#   count = var.cloudwatch_log_group_arn != null ? 1 : 0

#   statement {
#     sid    = "AllowLexCloudWatchLogging"
#     effect = "Allow"
#     actions = [
#       "logs:CreateLogStream",
#       "logs:PutLogEvents",
#       "logs:CreateLogGroup",
#     ]
#     resources = [var.cloudwatch_log_group_arn]
#   }
# }

# resource "aws_iam_policy" "allow_cloudwatch_logging" {
#   count  = var.cloudwatch_log_group_arn != null ? 1 : 0
#   name   = "${local.bot_name}-cloudwatch-logging-policy"
#   policy = data.aws_iam_policy_document.allow_cloudwatch_logging[0].json
#   tags   = var.tags
# }

# resource "aws_iam_role_policy_attachment" "allow_cloudwatch_logging" {
#   count      = var.cloudwatch_log_group_arn != null ? 1 : 0
#   role       = aws_iam_role.lex_role.name
#   policy_arn = aws_iam_policy.allow_cloudwatch_logging[0].arn
# }

# ==============================================================================
# Lambda invocation — created only when Lambda ARNs are provided
# ==============================================================================

data "aws_iam_policy_document" "allow_invoke_lambdas" {
  count = length(local.lambda_arns_effective) > 0 ? 1 : 0

  statement {
    sid    = "AllowInvokeLambdas"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "lambda:InvokeAsync",
    ]
    resources = values(local.lambda_arns_effective)
  }
}

resource "aws_iam_policy" "allow_invoke_lambdas" {
  count  = length(local.lambda_arns_effective) > 0 ? 1 : 0
  name   = "${local.bot_name}-lambda-invoke-policy"
  policy = data.aws_iam_policy_document.allow_invoke_lambdas[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "allow_invoke_lambdas" {
  count      = length(local.lambda_arns_effective) > 0 ? 1 : 0
  role       = aws_iam_role.lex_role.name
  policy_arn = aws_iam_policy.allow_invoke_lambdas[0].arn
}
