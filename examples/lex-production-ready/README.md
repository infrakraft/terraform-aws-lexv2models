# Production-Ready Lex Bot Example

Complete production deployment showcasing all v1.5.0 features:
- ✅ JSON schema validation
- ✅ Conversation logs (CloudWatch + S3)
- ✅ Slot obfuscation for PII protection
- ✅ Lambda fulfillment with DLQ
- ✅ Multi-locale support (en_US, en_GB)
- ✅ Bot versioning
- ✅ Automatic building
- ✅ Cost optimization

## Architecture

┌─────────────┐
│    User     │
└──────┬──────┘
│
▼
┌──────────────────┐
│   Lex Bot V2     │
│  (Multi-locale)  │◄── JSON Schema Validated
│   + Versioning   │
└────┬─────────┬───┘
│         │
│         └────────────┐
▼                      ▼
┌─────────────┐      ┌──────────────┐
│ CloudWatch  │      │   Lambda     │
│   Logs      │      │ Fulfillment  │
│ (Text)      │      │   + DLQ      │
└─────────────┘      └──────────────┘
│
▼
┌─────────────┐
│ S3 Bucket   │
│ (Audio)     │
└─────────────┘

## Features Demonstrated

### 1. JSON Schema Validation
- Pre-deployment validation
- CI/CD integration
- Error prevention

### 2. Slot Obfuscation
- PII protection in logs
- Compliance-ready (PCI DSS, HIPAA, GDPR)
- Email, SSN, and account number masking

### 3. Conversation Logs
- CloudWatch text logs (90-day retention)
- S3 audio logs (180-day retention)
- KMS encryption (optional)

### 4. Lambda Fulfillment
- Order processing handler
- Dead Letter Queue
- X-Ray tracing (optional)
- VPC support

### 5. Multi-Locale Support
- US English (en_US)
- British English (en_GB)
- Locale-specific intents and slots

### 6. Production Settings
- Bot versioning enabled
- Automatic building enabled
- Environment-specific configuration

## Quick Start

### Prerequisites

```bash
# Install Python dependencies for schema validation
pip3 install jsonschema

# Verify AWS CLI
aws --version

# Verify Terraform
terraform --version
```

### 1. Validate Configuration

```bash
# Validate bot_config.json against schema
cd examples/lex-production-ready

python3 ../../validate_schema.py \
  bot_config.json \
  ../../schema/bot_config_schema.json
```

### 2. Review Configuration

```bash
# Review terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

### 3. Deploy

```bash
# Initialize
terraform init

# Validate
terraform validate

# Plan
terraform plan

# Apply
terraform apply
```

### 4. Configure Conversation Logging (Manual Step)

⚠️ **Important:** Bot aliases not yet supported by Terraform.

```bash
# Get outputs
BOT_ID=$(terraform output -raw bot_id)
LOG_GROUP=$(terraform output -raw cloudwatch_log_group)
AUDIO_BUCKET=$(terraform output -raw audio_logs_bucket)
ROLE_ARN=$(terraform output -raw logging_iam_role_arn)

# Create alias
aws lexv2-models create-bot-alias \
  --bot-id $BOT_ID \
  --bot-alias-name production \
  --bot-version 1 \
  --region us-east-1

# Get alias ID from output
ALIAS_ID="<your-alias-id>"

# Configure logging
aws lexv2-models update-bot-alias \
  --bot-id $BOT_ID \
  --bot-alias-id $ALIAS_ID \
  --region us-east-1 \
  --conversation-log-settings \
    "textLogSettings=[{destination={cloudWatchLogs={cloudWatchLogGroupArn=arn:aws:logs:us-east-1:ACCOUNT:log-group:$LOG_GROUP,logPrefix=lex/}},enabled=true}],audioLogSettings=[{destination={s3Bucket={s3BucketArn=arn:aws:s3:::$AUDIO_BUCKET,logPrefix=lex-audio/}},enabled=true}]"
```

## Configuration Options

### Environment-Specific Settings

#### Development

```hcl
# terraform.tfvars
environment               = "dev"
create_bot_version        = false
enable_text_logs          = true
log_retention_days        = 7
enable_audio_logs         = false
enable_lambda_fulfillment = true
enable_xray_tracing       = false
```

**Cost:** ~$1-3/month

#### Staging

```hcl
# terraform.tfvars
environment               = "staging"
create_bot_version        = true
enable_text_logs          = true
log_retention_days        = 30
enable_audio_logs         = true
audio_log_retention_days  = 30
enable_lambda_fulfillment = true
enable_xray_tracing       = false
```

**Cost:** ~$5-15/month

#### Production

```hcl
# terraform.tfvars
environment               = "prod"
create_bot_version        = true
enable_text_logs          = true
log_retention_days        = 90
enable_audio_logs         = true
audio_log_retention_days  = 180
enable_lambda_fulfillment = true
enable_xray_tracing       = true  # Enable for observability
kms_key_id                = "arn:aws:kms:..."
```

**Cost:** ~$25-75/month (depends on volume)

## Bot Configuration

### Intents

#### 1. CheckOrderIntent
Checks order status with email verification.

**Slots:**
- `OrderNumber` - Customer order number (not obfuscated)
- `Email` - Customer email (**obfuscated** for PII protection)

**Sample Utterances:**
- "Check my order"
- "Where is my order {OrderNumber}"
- "Track my package"

#### 2. AccountInquiryIntent
Account-related inquiries with PII protection.

**Slots:**
- `AccountType` - Personal or Business (not obfuscated)
- `AccountNumber` - Account number (**obfuscated**)
- `SSN` - Last 4 digits of SSN (**obfuscated**)

**Sample Utterances:**
- "I have a question about my account"
- "Account help"
- "Billing inquiry"

#### 3. PaymentIntent
Process payments with full PII protection.

**Slots:**
- `PaymentAmount` - Payment amount (not obfuscated)
- `CreditCardNumber` - Last 4 digits (**obfuscated**)

**Sample Utterances:**
- "I want to make a payment"
- "Pay my bill"
- "Process payment"

### Slot Obfuscation Strategy

| Slot | Type | Obfuscation | Reason |
|------|------|-------------|--------|
| OrderNumber | AlphaNumeric | None | Public identifier, needed for support |
| Email | EmailAddress | DefaultObfuscation | PII - privacy protection |
| AccountNumber | Number | DefaultObfuscation | PII - security requirement |
| SSN | Number | DefaultObfuscation | PII - compliance requirement (HIPAA) |
| CreditCardNumber | Number | DefaultObfuscation | PCI DSS compliance |
| PaymentAmount | Number | None | Not sensitive |
| AccountType | Custom | None | Public information |

## Lambda Functions

### Deployment

Lambda functions are included in the `lambda/` directory:

lambda/
└── index.py          # Main handler

**Packaging:**

```bash
# Create deployment package
cd lambda
zip -r ../lambda.zip .
cd ..

# Upload to S3 (if using S3 deployment)
aws s3 cp lambda.zip s3://my-lambda-bucket/
```

### Handler Code

The Lambda handler (`lambda/index.py`) includes:
- Order status checking
- Account inquiry handling
- Payment processing
- Mock database lookups
- Lex V2 response formatting

### Testing Lambda Locally

```bash
cd lambda

# Test order check
python3 << EOF
import index
event = {
    "sessionState": {
        "intent": {
            "name": "CheckOrderIntent",
            "slots": {
                "OrderNumber": {
                    "value": {"interpretedValue": "ABC123"}
                }
            }
        }
    }
}
print(index.lambda_handler(event, None))
EOF
```

## Testing the Bot

### Test Order Check Intent

```bash
BOT_ID=$(terraform output -raw bot_id)
ALIAS_ID="<your-alias-id>"

aws lexv2-runtime recognize-text \
  --bot-id $BOT_ID \
  --bot-alias-id $ALIAS_ID \
  --locale-id en_US \
  --session-id test-session-1 \
  --text "Check my order ABC123"
```

### Test Account Inquiry Intent

```bash
aws lexv2-runtime recognize-text \
  --bot-id $BOT_ID \
  --bot-alias-id $ALIAS_ID \
  --locale-id en_US \
  --session-id test-session-2 \
  --text "I have a question about my personal account"
```

### Test Multi-Locale (British English)

```bash
aws lexv2-runtime recognize-text \
  --bot-id $BOT_ID \
  --bot-alias-id $ALIAS_ID \
  --locale-id en_GB \
  --session-id test-session-3 \
  --text "Track my parcel"
```

## Monitoring

### View Conversation Logs

```bash
LOG_GROUP=$(terraform output -raw cloudwatch_log_group)

# Tail logs
aws logs tail $LOG_GROUP --follow

# Search logs
aws logs filter-log-events \
  --log-group-name $LOG_GROUP \
  --filter-pattern "CheckOrderIntent"
```

### View Audio Logs

```bash
BUCKET=$(terraform output -raw audio_logs_bucket)

# List audio files
aws s3 ls s3://$BUCKET/lex-audio/ --recursive

# Download audio file
aws s3 cp s3://$BUCKET/lex-audio/conversation-123.wav ./
```

### Lambda Metrics

```bash
FUNCTION_NAME=$(terraform output -raw lambda_function_name)

# View invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=$FUNCTION_NAME \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum

# View errors
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=$FUNCTION_NAME \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

### CloudWatch Insights Queries

```sql
-- Find all conversations with obfuscated data
fields @timestamp, @message
| filter @message like /DefaultObfuscation/
| sort @timestamp desc
| limit 100

-- Count conversations by intent
fields @timestamp, intentName
| stats count() by intentName

-- Find failed fulfillment
fields @timestamp, @message
| filter dialogAction.type = "Failed"
| sort @timestamp desc
```

## Cost Estimate

### Development (1,000 conversations/month)
- Lex: $0 (free tier)
- Lambda: $0 (free tier)
- CloudWatch Logs: $0.50
- S3 Audio: $0 (disabled)
- **Total: ~$0.50-1.00/month**

### Staging (10,000 conversations/month)
- Lex: $4-8
- Lambda: $0.50-1.00
- CloudWatch Logs: $2-3
- S3 Audio: $0.50-1.00
- **Total: ~$7-13/month**

### Production (50,000 conversations/month)
- Lex: $20-40
- Lambda: $3-6
- CloudWatch Logs: $10-15
- S3 Audio: $2-5
- X-Ray: $10-15 (if enabled)
- **Total: ~$45-81/month**

### Production (100,000 conversations/month)
- Lex: $40-80
- Lambda: $6-12
- CloudWatch Logs: $20-30
- S3 Audio: $5-10
- X-Ray: $15-25 (if enabled)
- **Total: ~$86-157/month**

## Troubleshooting

### Bot Not Responding

1. **Check bot version:**
```bash
   terraform output bot_version
```

2. **Verify alias configuration:**
```bash
   aws lexv2-models describe-bot-alias \
     --bot-id $BOT_ID \
     --bot-alias-id $ALIAS_ID
```

3. **Check Lambda permissions:**
```bash
   aws lambda get-policy \
     --function-name $FUNCTION_NAME
```

### Logs Not Appearing

1. **Verify alias has logging enabled:**
```bash
   aws lexv2-models describe-bot-alias \
     --bot-id $BOT_ID \
     --bot-alias-id $ALIAS_ID \
     --query 'conversationLogSettings'
```

2. **Check IAM role permissions:**
```bash
   aws iam get-role-policy \
     --role-name $(terraform output -raw logging_iam_role_name) \
     --policy-name cloudwatch-logs
```

3. **Verify log group exists:**
```bash
   aws logs describe-log-groups \
     --log-group-name-prefix /aws/lex/
```

### Lambda Errors

1. **Check Lambda logs:**
```bash
   aws logs tail /aws/lambda/$FUNCTION_NAME --follow
```

2. **Check Dead Letter Queue:**
```bash
   aws sqs receive-message \
     --queue-url $(terraform output -raw dlq_url) \
     --max-number-of-messages 10
```

3. **Test Lambda directly:**
```bash
   aws lambda invoke \
     --function-name $FUNCTION_NAME \
     --payload file://test-event.json \
     response.json
```

### Schema Validation Errors

```bash
# Run validation with detailed output
python3 ../../validate_schema.py \
  bot_config.json \
  ../../schema/bot_config_schema.json
```

Common errors:
- Missing required fields
- Invalid locale IDs
- Invalid obfuscation values
- Invalid slot types

## Cleanup

```bash
# Destroy all resources
terraform destroy

# Confirm deletion
yes

# Verify cleanup
aws lexv2-models list-bots
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `prod-customer-service`)].FunctionName'
```

## Security Best Practices

### 1. KMS Encryption
- ✅ Encrypt CloudWatch Logs
- ✅ Encrypt S3 audio logs
- ✅ Use customer-managed keys

### 2. IAM Permissions
- ✅ Least privilege principle
- ✅ Separate roles for Lex, Lambda, and logging
- ✅ No wildcard permissions

### 3. Data Protection
- ✅ Obfuscate all PII in logs
- ✅ Set appropriate retention periods
- ✅ Enable S3 versioning

### 4. Network Security
- ✅ Deploy Lambda in VPC (for RDS access)
- ✅ Use security groups
- ✅ Enable VPC flow logs

### 5. Monitoring
- ✅ CloudWatch alarms for errors
- ✅ Dead Letter Queue monitoring
- ✅ Regular log reviews

## Compliance Checklist

- [x] **PCI DSS** - Credit card data obfuscated
- [x] **HIPAA** - SSN and health data obfuscated
- [x] **GDPR** - Personal data obfuscated, retention policies set
- [x] **SOC 2** - Encryption at rest and in transit
- [x] **CCPA** - Consumer data protection

## Next Steps

1. **Enable X-Ray** - For production observability
2. **Set up Alarms** - CloudWatch alarms for errors
3. **Configure Backup** - S3 bucket replication
4. **Add More Locales** - Expand to es_ES, fr_FR, etc.
5. **Implement A/B Testing** - Multiple bot versions

## Support

For issues or questions:
- 📖 [Main Documentation](../../README.md)
- 🐛 [Issue Tracker](https://github.com/infrakraft/terraform-aws-lexv2models/issues)
- 💬 [Discussions](https://github.com/infrakraft/terraform-aws-lexv2models/discussions)