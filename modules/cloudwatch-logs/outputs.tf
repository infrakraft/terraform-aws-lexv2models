output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Log Group"
  value       = var.prevent_destroy ? aws_cloudwatch_log_group.protected[0].name : aws_cloudwatch_log_group.unprotected[0].name
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group"
  value       = var.prevent_destroy ? aws_cloudwatch_log_group.protected[0].arn : aws_cloudwatch_log_group.unprotected[0].arn
}