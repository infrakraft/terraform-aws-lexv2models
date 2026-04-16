# ==============================================================================
# IAM Role for Lex to Write Logs
# ==============================================================================

data "aws_iam_policy_document" "lex_logs_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lexv2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lex_logs" {
  name               = var.iam_role_name != null ? var.iam_role_name : "${var.bot_id}-logs-role"
  assume_role_policy = data.aws_iam_policy_document.lex_logs_trust.json

  tags = var.tags
}

# CloudWatch Logs permissions
data "aws_iam_policy_document" "cloudwatch_logs" {
  count = var.enable_text_logs ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.text_logs[0].arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "cloudwatch_logs" {
  count = var.enable_text_logs ? 1 : 0

  name   = "cloudwatch-logs"
  role   = aws_iam_role.lex_logs.id
  policy = data.aws_iam_policy_document.cloudwatch_logs[0].json
}

# S3 permissions for audio logs
data "aws_iam_policy_document" "s3_audio_logs" {
  count = var.enable_audio_logs ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]

    resources = [
      "${aws_s3_bucket.audio_logs[0].arn}/*"
    ]
  }

  # KMS permissions if encryption is enabled
  dynamic "statement" {
    for_each = var.kms_key_id != null ? [1] : []

    content {
      effect = "Allow"

      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]

      resources = [var.kms_key_id]
    }
  }
}

resource "aws_iam_role_policy" "s3_audio_logs" {
  count = var.enable_audio_logs ? 1 : 0

  name   = "s3-audio-logs"
  role   = aws_iam_role.lex_logs.id
  policy = data.aws_iam_policy_document.s3_audio_logs[0].json
}