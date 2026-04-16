# Conversation Logs Module

Enables conversation logging for AWS Lex V2 bots with CloudWatch (text) and S3 (audio) support.

## Features

- ✅ Text conversation logs to CloudWatch Logs
- ✅ Audio conversation logs to S3
- ✅ Configurable retention policies
- ✅ KMS encryption support
- ✅ IAM roles and permissions
- ✅ S3 lifecycle management

## Usage

```hcl
module "conversation_logs" {
  source = "../../modules/conversation-logs"
  
  bot_id = module.lex_bot.bot_id
  
  # Text logs to CloudWatch
  enable_text_logs   = true
  log_retention_days = 30
  
  # Audio logs to S3 (optional)
  enable_audio_logs = true
  s3_bucket_name    = "my-lex-audio-logs"
  s3_lifecycle_days = 90
  
  tags = {
    Environment = "production"
    Purpose     = "ConversationLogs"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| bot_id | Lex bot ID | string | - | yes |
| enable_text_logs | Enable CloudWatch text logs | bool | true | no |
| enable_audio_logs | Enable S3 audio logs | bool | false | no |
| log_retention_days | CloudWatch retention (days) | number | 30 | no |
| s3_bucket_name | S3 bucket for audio logs | string | null | if audio enabled |
| s3_lifecycle_days | Auto-expire audio after days | number | 90 | no |
| kms_key_id | KMS key for encryption | string | null | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudwatch_log_group_name | CloudWatch log group name |
| s3_bucket_name | S3 bucket for audio logs |
| iam_role_arn | IAM role ARN |

## Note on Bot Aliases

⚠️ **Logging configuration requires a bot alias**, which is not yet supported by Terraform AWS provider.

After running this module, you must:

1. Create a bot alias in AWS Console or via AWS CLI
2. Configure conversation logging for the alias
3. Reference the IAM role created by this module

### AWS CLI Example

```bash
# Create alias
aws lexv2-models create-bot-alias \
  --bot-id YOUR_BOT_ID \
  --bot-alias-name production \
  --bot-version 1

# Configure logging
aws lexv2-models update-bot-alias \
  --bot-id YOUR_BOT_ID \
  --bot-alias-id ALIAS_ID \
  --conversation-log-settings \
    textLogSettings=[{destination={cloudWatchLogs={cloudWatchLogGroupArn=LOG_GROUP_ARN,logPrefix=lex/}},enabled=true}] \
    audioLogSettings=[{destination={s3Bucket={s3BucketArn=BUCKET_ARN,logPrefix=lex-audio/}},enabled=true}]
```

## Cost Considerations

- **CloudWatch Logs**: ~$0.50/GB ingested + $0.03/GB/month storage
- **S3 Audio Logs**: ~$0.023/GB/month (Standard storage)
- **Typical costs**:
  - Low volume (1,000 conversations/month): ~$2-5/month
  - Medium volume (10,000 conversations/month): ~$10-25/month
  - High volume (100,000 conversations/month): ~$50-150/month