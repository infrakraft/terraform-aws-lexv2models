resource "aws_cloudwatch_log_group" "protected" {
  count             = var.prevent_destroy ? 1 : 0
  name              = var.name
  retention_in_days = var.retention_in_days != null ? var.retention_in_days : 365
  kms_key_id        = var.kms_key_id != null ? var.kms_key_id : null
  tags              = var.tags
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "unprotected" {
  count             = var.prevent_destroy ? 0 : 1
  name              = var.name
  retention_in_days = var.retention_in_days != null ? var.retention_in_days : 365
  kms_key_id        = var.kms_key_id != null ? var.kms_key_id : null
  tags              = var.tags
}