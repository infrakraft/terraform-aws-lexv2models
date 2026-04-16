output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for text logs"
  value       = var.enable_text_logs ? aws_cloudwatch_log_group.text_logs[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = var.enable_text_logs ? aws_cloudwatch_log_group.text_logs[0].arn : null
}

output "s3_bucket_name" {
  description = "S3 bucket name for audio logs"
  value       = var.enable_audio_logs ? aws_s3_bucket.audio_logs[0].id : null
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN for audio logs"
  value       = var.enable_audio_logs ? aws_s3_bucket.audio_logs[0].arn : null
}

output "iam_role_arn" {
  description = "IAM role ARN for Lex logging"
  value       = aws_iam_role.lex_logs.arn
}

output "iam_role_name" {
  description = "IAM role name for Lex logging"
  value       = aws_iam_role.lex_logs.name
}