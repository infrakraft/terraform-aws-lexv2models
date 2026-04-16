# data "aws_region" "current" {}
# data "aws_caller_identity" "current" {}

# ==============================================================================
# CloudWatch Log Group for Text Logs
# ==============================================================================

resource "aws_cloudwatch_log_group" "text_logs" {
  count = var.enable_text_logs ? 1 : 0

  name              = var.cloudwatch_log_group_name != null ? var.cloudwatch_log_group_name : "/aws/lex/${var.bot_id}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name = "${var.bot_id}-conversation-logs"
    }
  )
}

# ==============================================================================
# S3 Bucket for Audio Logs
# ==============================================================================

resource "aws_s3_bucket" "audio_logs" {
  count = var.enable_audio_logs ? 1 : 0

  bucket        = var.s3_bucket_name
  force_destroy = var.s3_force_destroy

  tags = merge(
    var.tags,
    {
      Name    = "${var.bot_id}-audio-logs"
      Purpose = "LexConversationAudioLogs"
    }
  )
}

resource "aws_s3_bucket_versioning" "audio_logs" {
  count = var.enable_audio_logs && var.s3_enable_versioning ? 1 : 0

  bucket = aws_s3_bucket.audio_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audio_logs" {
  count = var.enable_audio_logs ? 1 : 0

  bucket = aws_s3_bucket.audio_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "audio_logs" {
  count = var.enable_audio_logs && var.s3_lifecycle_days != null ? 1 : 0

  bucket = aws_s3_bucket.audio_logs[0].id

  rule {
    id     = "expire-old-audio-logs"
    status = "Enabled"

    expiration {
      days = var.s3_lifecycle_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}