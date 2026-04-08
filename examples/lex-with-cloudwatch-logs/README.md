# Lex Bot with CloudWatch Logging Example

This example demonstrates integrating **CloudWatch Logs** with your Lex bot for conversation logging, monitoring, and debugging.

## What This Example Shows

- ✅ Modular CloudWatch log group creation
- ✅ Automatic IAM permissions for logging
- ✅ Environment-specific log retention (dev vs prod)
- ✅ Optional KMS encryption for logs
- ✅ Lifecycle protection for production logs
- ✅ Bot building with logging enabled
- ✅ Complete observability setup

## Architecture

┌─────────────────────────────────┐
│   User Interaction              │
└────────┬────────────────────────┘
│
↓
┌─────────────────────────────────┐
│   AWS Lex V2 Bot               │
│                                 │
│   • Processes conversations     │
│   • Fulfills intents           │
│   • Generates responses         │
└────────┬────────────────────────┘
│
│ Conversation Events
↓
┌─────────────────────────────────┐
│   CloudWatch Logs               │
│                                 │
│   Log Group:                    │
│   /aws/lex/{BotName}           │
│                                 │
│   Features:                     │
│   • Retention: 7-365 days      │
│   • KMS encryption (optional)   │
│   • Lifecycle protection        │
│   • Log Insights queries        │
└─────────────────────────────────┘

## What Gets Created

This example deploys:

1. **CloudWatch Log Group** - `/aws/lex/{BotName}`
   - Configurable retention (7-3653 days)
   - Optional KMS encryption
   - Environment-based lifecycle protection

2. **Lex Bot** - With conversation logging enabled
   - Automatically built and ready for testing
   - IAM permissions for CloudWatch Logs
   - Multi-locale support

3. **IAM Permissions** - Automatic policy creation
   - `logs:CreateLogStream`
   - `logs:PutLogEvents`

## Prerequisites

1. **AWS Account** with permissions for:
   - Lex V2
   - CloudWatch Logs
   - IAM
2. **Terraform** >= 1.0
3. **jq** installed (for slot priorities)
4. **AWS CLI** configured and installed
5. **Bot configuration file** - `bot_config.json`

## Quick Start

### Step 1: Create Bot Configuration

Create `bot_config.json`:

```json
{
  "name": "CustomerServiceBot",
  "description": "Bot with CloudWatch logging enabled",
  "idle_session_ttl": 300,
  "data_privacy": {
    "child_directed": false
  },
  "locales": {
    "en_US": {
      "locale_id": "en_US",
      "description": "English US",
      "nlu_confidence_threshold": 0.4,
      "voice_settings": {
        "voice_id": "Joanna"
      },
      "intents": {
        "Greeting": {
          "description": "Greet the user",
          "sample_utterances": [
            { "utterance": "Hello" },
            { "utterance": "Hi there" },
            { "utterance": "Good morning" }
          ],
          "closing_prompt": {
            "message": "Hello! How can I help you today?",
            "variations": []
          }
        },
        "GetHelp": {
          "description": "User needs help",
          "sample_utterances": [
            { "utterance": "I need help" },
            { "utterance": "Can you help me" },
            { "utterance": "Help" }
          ],
          "closing_prompt": {
            "message": "I'm here to help! What do you need assistance with?",
            "variations": []
          }
        }
      }
    }
  }
}
```

### Step 2: Configure Variables (Optional)

Create `terraform.tfvars`:

```hcl
aws_region         = "eu-west-1"
environment        = "dev"
log_retention_days = 7
auto_build         = true
wait_for_build     = true
create_version     = false
```

### Step 3: Initialize and Deploy

```bash
cd examples/lex-with-cloudwatch-logs

# Initialize
terraform init

# Review plan
terraform plan

# Deploy
terraform apply
```

### Step 4: Test Conversation Logging

**Send a test message:**

```bash
# Get bot ID
BOT_ID=$(terraform output -raw bot_id)

# Send test conversation
aws lexv2-runtime recognize-text \
  --bot-id "$BOT_ID" \
  --bot-alias-id TSTALIASID \
  --locale-id en_US \
  --session-id test-session-$(date +%s) \
  --text "Hello"
```

**View logs:**

```bash
# Get log group name
LOG_GROUP=$(terraform output -raw log_group_name)

# View recent logs
aws logs tail "$LOG_GROUP" --follow

# Or describe log streams
aws logs describe-log-streams \
  --log-group-name "$LOG_GROUP" \
  --order-by LastEventTime \
  --descending \
  --max-items 5
```

**View in AWS Console:**
1. Go to [CloudWatch Console](https://console.aws.amazon.com/cloudwatch/)
2. Navigate to **Log groups**
3. Find `/aws/lex/CustomerServiceBot`
4. Click on latest log stream

## Configuration Options

### Development Environment

```hcl
environment        = "dev"
log_retention_days = 7        # 1 week
kms_key_id         = null     # No encryption
auto_build         = true
wait_for_build     = false    # Faster iterations
create_version     = false
```

**Characteristics:**
- Short retention (lower cost)
- No encryption
- Fast deployments
- No lifecycle protection
- **Cost: ~$0.50/month** (100 conversations/day)

### Staging Environment

```hcl
environment        = "staging"
log_retention_days = 30       # 1 month
kms_key_id         = aws_kms_key.staging.arn
auto_build         = true
wait_for_build     = true
create_version     = true
```

**Characteristics:**
- Medium retention
- Encrypted logs
- Ensures bot is ready
- Version snapshots
- **Cost: ~$2/month** (500 conversations/day)

### Production Environment

```hcl
environment        = "prod"
log_retention_days = 365      # 1 year
kms_key_id         = aws_kms_key.prod.arn
auto_build         = true
wait_for_build     = true
create_version     = true
```

**Characteristics:**
- Long retention (compliance)
- KMS encryption required
- **Lifecycle protection enabled** (prevent deletion)
- Version snapshots
- Build verification
- **Cost: ~$10-50/month** (1000-10000 conversations/day)

## Understanding Log Retention

### Valid Retention Periods (days)

| Category | Retention Periods |
|----------|------------------|
| **Short-term** | 1, 3, 5, 7, 14 |
| **Medium-term** | 30, 60, 90, 120, 150, 180 |
| **Long-term** | 365, 400, 545, 731 (2 years) |
| **Compliance** | 1827 (5 years), 3653 (10 years) |

### Retention Best Practices

| Environment | Recommended | Rationale |
|-------------|------------|-----------|
| Development | 7 days | Quick debugging, minimal cost |
| Testing/QA | 14-30 days | Test cycle duration |
| Staging | 30-60 days | Pre-production validation |
| Production | 365 days | Compliance, audit trails |
| Regulated | 1827-3653 days | Legal/regulatory requirements |

## KMS Encryption Setup

### Why Encrypt Logs?

- ✅ Compliance requirements (HIPAA, PCI-DSS, GDPR)
- ✅ Protect sensitive conversation data
- ✅ Meet organizational security standards
- ✅ Audit trail for key usage

### Step 1: Create KMS Key

```hcl
resource "aws_kms_key" "lex_logs" {
  description             = "KMS key for Lex conversation logs encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "lex-logs-encryption-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "lex_logs" {
  name          = "alias/lex-${var.environment}-logs"
  target_key_id = aws_kms_key.lex_logs.key_id
}
```

### Step 2: Grant CloudWatch Permissions

```hcl
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_key_policy" "lex_logs" {
  key_id = aws_kms_key.lex_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Enable CloudWatch Logs Encryption"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lex/*"
          }
        }
      }
    ]
  })
}
```

### Step 3: Use in Module

```hcl
module "cloudwatch_logs" {
  source = "../../modules/cloudwatch-logs"
  
  name       = "/aws/lex/MyBot"
  kms_key_id = aws_kms_key.lex_logs.arn  # Enable encryption
  
  # ... other config
}
```

## Analyzing Logs with CloudWatch Insights

### Query: Find Failed Intents

```sql
fields @timestamp, inputTranscript, sessionId, interpretations.0.intent.state
| filter interpretations.0.intent.state = "Failed"
| sort @timestamp desc
| limit 50
```

### Query: Low Confidence Interactions

```sql
fields @timestamp, inputTranscript, interpretations.0.nluConfidence
| filter interpretations.0.nluConfidence < 0.7
| sort interpretations.0.nluConfidence asc
| limit 100
```

### Query: Popular Intents

```sql
stats count() as conversationCount by interpretations.0.intent.name
| sort conversationCount desc
```

### Query: Conversation Volume by Hour

```sql
fields @timestamp
| stats count() as conversations by bin(@timestamp, 1h)
| sort @timestamp desc
```

### Query: Session Duration Analysis

```sql
fields @timestamp, sessionId
| stats earliest(@timestamp) as sessionStart, latest(@timestamp) as sessionEnd by sessionId
| fields sessionId, (sessionEnd - sessionStart) / 60000 as durationMinutes
| sort durationMinutes desc
```

## Log Entry Structure

Example log entry:

```json
{
  "@timestamp": "2025-04-10T14:23:45.123Z",
  "requestId": "abc-123-def-456",
  "sessionId": "test-session-1712758425",
  "botId": "ABCDEFGHIJ",
  "botAliasId": "TSTALIASID",
  "localeId": "en_US",
  "inputTranscript": "Hello",
  "inputMode": "Text",
  "interpretations": [
    {
      "intent": {
        "name": "Greeting",
        "state": "ReadyForFulfillment",
        "slots": {}
      },
      "nluConfidence": 0.98
    }
  ],
  "sessionState": {
    "sessionAttributes": {},
    "dialogAction": {
      "type": "Close"
    },
    "intent": {
      "name": "Greeting",
      "state": "Fulfilled"
    }
  },
  "messages": [
    {
      "contentType": "PlainText",
      "content": "Hello! How can I help you today?"
    }
  ]
}
```

## Cost Analysis

### CloudWatch Logs Pricing (US East - Ohio)

| Component | Price | Notes |
|-----------|-------|-------|
| Data Ingestion | $0.50 per GB | One-time per GB ingested |
| Data Storage | $0.03 per GB/month | Based on retention period |
| CloudWatch Insights | $0.005 per GB scanned | Query costs |

### Example Monthly Costs

**Small Bot (100 conversations/day):**
- Log volume: ~1 GB/month
- Ingestion: $0.50
- Storage (7 days): $0.03
- **Total: ~$0.53/month**

**Medium Bot (1,000 conversations/day):**
- Log volume: ~10 GB/month
- Ingestion: $5.00
- Storage (30 days): $0.30
- **Total: ~$5.30/month**

**Large Bot (10,000 conversations/day):**
- Log volume: ~100 GB/month
- Ingestion: $50.00
- Storage (365 days): $3.00
- Insights queries: ~$2.00
- **Total: ~$55/month**

### Cost Optimization Tips

1. **Adjust retention based on needs**
```hcl
   log_retention_days = 7  # vs 365 saves storage cost
```

2. **Use metric filters instead of storing all logs**
```hcl
   resource "aws_cloudwatch_log_metric_filter" "failed_intents" {
     name           = "FailedIntents"
     log_group_name = module.cloudwatch_logs.cloudwatch_log_group_name
     pattern        = "[..., intent_state = Failed]"
     
     metric_transformation {
       name      = "FailedIntentCount"
       namespace = "LexBot"
       value     = "1"
     }
   }
```

3. **Archive old logs to S3**
   - Export logs older than 30 days to S3
   - Use S3 Glacier for long-term archival
   - Much cheaper: $0.004 per GB/month (Glacier)

4. **Filter unnecessary log events**
   - Configure subscription filters
   - Only log important events

## Monitoring and Alerting

### Create Alarms for Key Metrics

```hcl
resource "aws_cloudwatch_metric_alarm" "high_failure_rate" {
  alarm_name          = "lex-high-failure-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FailedIntentCount"
  namespace           = "LexBot"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when failed intents exceed threshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

### CloudWatch Dashboard

```hcl
resource "aws_cloudwatch_dashboard" "lex_bot" {
  dashboard_name = "LexBot-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lex", "MissedUtterance", { stat = "Sum" }],
            [".", "RuntimeRequestCount", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Bot Activity"
        }
      }
    ]
  })
}
```

## Troubleshooting

### No Logs Appearing

**1. Check IAM permissions:**

```bash
BOT_ROLE=$(terraform output -raw bot_role_arn | cut -d'/' -f2)

aws iam list-attached-role-policies --role-name "$BOT_ROLE"
```

Should show `cloudwatch-logging-policy`.

**2. Verify log group exists:**

```bash
aws logs describe-log-groups --log-group-name-prefix "/aws/lex/"
```

**3. Test bot interaction:**

Ensure you're actually sending messages to the bot.

### Permission Denied Errors

Check that the IAM policy includes:
- `logs:CreateLogStream`
- `logs:PutLogEvents`

Verify with:
```bash
aws iam get-policy-version \
  --policy-arn $(terraform output -raw bot_role_arn)/cloudwatch-logging-policy \
  --version-id v1
```

### Logs Not Encrypted (when KMS specified)

**Verify KMS key policy:**

```bash
aws kms get-key-policy \
  --key-id <your-key-id> \
  --policy-name default
```

Ensure CloudWatch Logs service has permissions.

### Cannot Delete Log Group (Production)

This is **expected behavior** when `prevent_destroy = true`.

**To delete:**
1. Update configuration:
```hcl
   environment = "dev"  # Changes prevent_destroy to false
```
2. Apply: `terraform apply`
3. Destroy: `terraform destroy`

Or manually delete in AWS Console first.

## Outputs

After successful deployment:

```bash
terraform output
```

Example output:

bot_id              = "ABCDEFGHIJ"
bot_name            = "CustomerServiceBot"
bot_arn             = "arn:aws:lex:eu-west-1:123456789012:bot/ABCDEFGHIJ"
log_group_name      = "/aws/lex/CustomerServiceBot"
log_group_arn       = "arn:aws:logs:eu-west-1:123456789012:log-group:/aws/lex/CustomerServiceBot"
environment         = "dev"
log_retention_days  = 7
logs_protected      = false
deployment_info = {
auto_build_enabled  = true
bot_id              = "ABCDEFGHIJ"
bot_name            = "CustomerServiceBot"
environment         = "dev"
log_group_name      = "/aws/lex/CustomerServiceBot"
log_retention_days  = 7
logs_encrypted      = false
logs_protected      = false
version_created     = false
}

## Clean Up

```bash
terraform destroy
```

**Note:** If `environment = "prod"`, you'll get an error due to `prevent_destroy`. See troubleshooting section above.

## Combining Features

This example can be combined with other features:

### With Bot Versioning

```hcl
create_version      = true
bot_version_description = "v1.0.0 - Production release with logging"
```

### With All Features

```hcl
# CloudWatch logging
enable_cloudwatch_logging = true
cloudwatch_log_group_arn  = module.cloudwatch_logs.cloudwatch_log_group_arn

# Bot building
auto_build_bot_locales    = true
wait_for_build_completion = true

# Bot versioning
create_bot_version        = true
bot_version_description   = "v1.0.0 - Full production deployment"
```

## Next Steps

1. **Set up alerts** - CloudWatch alarms for failures
2. **Create dashboards** - Visualize bot performance
3. **Add Lambda fulfillment** - Connect business logic
4. **Implement CI/CD** - Automate deployments
5. **Scale to production** - Add more locales, intents

## Additional Resources

- [Main Module Documentation](../../README.md)
- [AWS Lex Logging Documentation](https://docs.aws.amazon.com/lexv2/latest/dg/monitoring-cloudwatch.html)
- [CloudWatch Logs Pricing](https://aws.amazon.com/cloudwatch/pricing/)
- [CloudWatch Insights Query Syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)
- [KMS Encryption for Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html)