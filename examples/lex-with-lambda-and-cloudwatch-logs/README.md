# Lex Bot with Lambda Fulfillment and CloudWatch Logging

Complete production-ready example with Lambda fulfillment and comprehensive CloudWatch logging for both Lex conversations and Lambda executions.

## What This Example Shows

- ✅ Lambda functions for bot fulfillment
- ✅ CloudWatch Logs for Lex conversations
- ✅ CloudWatch Logs for Lambda functions
- ✅ Environment-based log retention
- ✅ Optional KMS encryption for logs
- ✅ Lifecycle protection for production
- ✅ Complete observability stack

## Architecture

┌──────────────────────────────────────┐
│   User Interaction                   │
└────────┬─────────────────────────────┘
│
↓
┌──────────────────────────────────────┐
│   AWS Lex V2 Bot                     │
│   • FileClaimIntent                  │
│   • CheckPolicyIntent                │
└────┬───────────────────────┬─────────┘
│                       │
│ Fulfillment           │ Conversation Logs
↓                       ↓
┌────────────────┐    ┌──────────────────────┐
│ Lambda         │    │ CloudWatch Logs      │
│ • claims       │───→│ /aws/lex/InsuranceBot│
│ • policy       │    └──────────────────────┘
└────┬───────────┘
│ Execution Logs
↓
┌──────────────────────────────────────┐
│ CloudWatch Logs                      │
│ • /aws/lambda/claims_handler         │
│ • /aws/lambda/policy_lookup          │
└──────────────────────────────────────┘

## What Gets Created

### Lambda Functions (2)
- `claims_handler` - Process insurance claims
- `policy_lookup` - Retrieve policy information

### CloudWatch Log Groups (3)
- `/aws/lex/InsuranceBot` - Conversation logs
- `/aws/lambda/claims_handler` - Lambda execution logs
- `/aws/lambda/policy_lookup` - Lambda execution logs

### IAM Resources
- Lambda execution roles
- Lex invoke permissions
- CloudWatch Logs permissions

### Lex Bot
- Insurance bot with 2 intents
- Lambda fulfillment integration
- Conversation logging enabled

## Prerequisites

1. **AWS Account** with required permissions
2. **Terraform** >= 1.0
3. **jq** installed
4. **AWS CLI** configured
5. **S3 bucket** for Lambda packages
6. **Lambda code** uploaded to S3

## Configuration Patterns

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
- Short retention (cost effective)
- No encryption
- Fast deployments
- No lifecycle protection
- **Cost: ~$1/month**

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
- Build validation
- Version snapshots
- **Cost: ~$3/month**

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
- KMS encryption
- **Lifecycle protection enabled**
- Build validation
- Version snapshots
- **Cost: ~$10-20/month**

## Quick Start

### Step 1: Prepare Lambda Packages

```bash
# Create and upload Lambda packages (see lex-with-lambda example)
cd lambda/claims_handler
zip claims_handler.zip index.py
aws s3 cp claims_handler.zip s3://YOUR-BUCKET/

cd ../policy_lookup
zip policy_lookup.zip index.py
aws s3 cp policy_lookup.zip s3://YOUR-BUCKET/
```

### Step 2: Configure

Create `terraform.tfvars`:

```hcl
aws_region         = "eu-west-1"
environment        = "dev"
lambda_s3_bucket   = "YOUR-BUCKET"
log_retention_days = 7
auto_build         = true
wait_for_build     = true
```

### Step 3: Deploy

```bash
terraform init
terraform plan
terraform apply
```

### Step 4: Test and Monitor

**Send test message:**

```bash
BOT_ID=$(terraform output -raw bot_id)

aws lexv2-runtime recognize-text \
  --bot-id "$BOT_ID" \
  --bot-alias-id TSTALIASID \
  --locale-id en_US \
  --session-id test-$(date +%s) \
  --text "I need to file a claim"
```

**View Lex conversation logs:**

```bash
LOG_GROUP=$(terraform output -raw lex_log_group_name)
aws logs tail "$LOG_GROUP" --follow
```

**View Lambda logs:**

```bash
# Claims handler
aws logs tail /aws/lambda/claims_handler --follow

# Policy lookup
aws logs tail /aws/lambda/policy_lookup --follow
```

## Monitoring with CloudWatch Insights

### Query: Successful Claims

```sql
fields @timestamp, inputTranscript, sessionId
| filter interpretations.0.intent.name = "FileClaimIntent"
| filter interpretations.0.intent.state = "Fulfilled"
| sort @timestamp desc
| limit 100
```

### Query: Failed Interactions

```sql
fields @timestamp, inputTranscript, interpretations.0.intent.state
| filter interpretations.0.intent.state = "Failed"
| sort @timestamp desc
```

### Query: Lambda Errors

```sql
fields @timestamp, @message
| filter @type = "ERROR"
| sort @timestamp desc
```

### Query: Lambda Duration

```sql
fields @duration
| stats avg(@duration) as avg_ms,
        max(@duration) as max_ms,
        min(@duration) as min_ms,
        count() as invocations
by bin(5m)
```

### Query: Conversation Volume by Hour

```sql
fields @timestamp
| stats count() as conversations by bin(@timestamp, 1h)
| sort @timestamp desc
```

## Cost Analysis

### CloudWatch Logs Pricing

| Component | Dev | Staging | Prod |
|-----------|-----|---------|------|
| Ingestion (100 convos/day) | $0.50 | $1.50 | $1.50 |
| Storage (7/30/365 days) | $0.03 | $0.12 | $1.50 |
| **Total Logs** | **$0.53** | **$1.62** | **$3.00** |

### Lambda Pricing

| Component | Dev | Staging | Prod |
|-----------|-----|---------|------|
| Requests | $0.00 | $0.00 | $0.60 |
| Duration | $0.00 | $0.40 | $4.00 |
| **Total Lambda** | **$0.00** | **$0.40** | **$4.60** |

### Lex Pricing

| Component | Cost |
|-----------|------|
| Text requests (10k free) | $0.00 |
| Beyond free tier | $0.75/1k |

### **Total Monthly Cost**

- **Development:** ~$0.53
- **Staging:** ~$2.02
- **Production:** ~$7.60-15

## KMS Encryption Setup

### Create KMS Key

```hcl
resource "aws_kms_key" "logs" {
  description             = "KMS key for log encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = {
    Name = "${var.environment}-logs-key"
  }
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.environment}-logs"
  target_key_id = aws_kms_key.logs.key_id
}
```

### Grant CloudWatch Permissions

```hcl
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_key_policy" "logs" {
  key_id = aws_kms_key.logs.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable CloudWatch Logs"
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
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/*"
          }
        }
      }
    ]
  })
}
```

### Use in Configuration

## X-Ray Tracing

### Cost Impact

AWS X-Ray adds approximately **$5-10/month** for production workloads:
- Trace storage: $5.00 per million traces
- Trace retrieval: $0.50 per million traces retrieved

### Configuration

**Disable X-Ray (Recommended for Development):**

```hcl
# terraform.tfvars
enable_xray_tracing = false
```

**Enable X-Ray (Optional for Production):**

```hcl
# terraform.tfvars
enable_xray_tracing = true
```

### When to Enable

✅ **Enable when:**
- Debugging distributed systems
- Need request flow visualization
- Production observability requirements
- Compliance mandates distributed tracing

❌ **Disable when:**
- Cost-sensitive applications
- Simple Lambda functions
- Development/testing (CloudWatch Logs sufficient)
- Low traffic applications

### Viewing X-Ray Traces

If enabled:

1. Go to AWS X-Ray Console
2. View Service Map
3. Analyze traces
4. Monitor performance

```hcl
kms_key_id = aws_kms_key.logs.arn
```

## Advanced Configuration

### X-Ray Tracing

Control AWS X-Ray tracing based on environment:

```hcl
# Development - X-Ray disabled (save costs)
environment         = "dev"
enable_xray_tracing = false

# Production - X-Ray enabled (observability)
environment         = "prod"
enable_xray_tracing = true
```

**Cost:** Adds ~$5-10/month for production workloads

### Ephemeral Storage

Increase Lambda /tmp storage for large file processing:

```hcl
# Default: 512 MB (included)
ephemeral_storage_size = null

# Increase to 2 GB for large files
ephemeral_storage_size = 2048
```

**Cost:** $0.0000000309 per GB-second above 512 MB

### Environment-Specific Configuration

```hcl
# Development
environment            = "dev"
log_retention_days     = 7
enable_xray_tracing    = false
ephemeral_storage_size = null
kms_key_id             = null

# Staging
environment            = "staging"
log_retention_days     = 30
enable_xray_tracing    = true
ephemeral_storage_size = null
kms_key_id             = aws_kms_key.staging.arn

# Production
environment            = "prod"
log_retention_days     = 365
enable_xray_tracing    = true
ephemeral_storage_size = 2048  # If needed
kms_key_id             = aws_kms_key.prod.arn
```

## Troubleshooting

### No Logs Appearing

**Check IAM permissions:**

```bash
# Verify Lex has CloudWatch permissions
BOT_ROLE=$(terraform output -raw bot_role_arn | cut -d'/' -f2)
aws iam list-attached-role-policies --role-name "$BOT_ROLE"
```

**Verify log groups exist:**

```bash
aws logs describe-log-groups --log-group-name-prefix "/aws/lex/"
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/"
```

### Lambda Not Logging

Ensure Lambda execution role has `AWSLambdaBasicExecutionRole` attached.

### Cannot Delete Log Groups (Production)

Expected when `prevent_destroy = true`. To delete:

1. Change environment to `dev` (disables protection)
2. Apply changes
3. Then destroy

## Outputs

After deployment:

```bash
terraform output
```

Example:

bot_id               = "ABC123XYZ"
bot_name             = "InsuranceBot"
lex_log_group_name   = "/aws/lex/InsuranceBot"
lambda_function_names = {
claims_handler = "claims_handler"
policy_lookup  = "policy_lookup"
}
lambda_log_groups = {
claims_handler = "/aws/lambda/claims_handler"
policy_lookup  = "/aws/lambda/policy_lookup"
}
deployment_info = {
bot_id             = "ABC123XYZ"
environment        = "dev"
lambda_functions   = ["claims_handler", "policy_lookup"]
log_retention_days = 7
logs_encrypted     = false
logs_protected     = false
}

## Clean Up

```bash
terraform destroy
```

**Note:** If environment is "prod", change to "dev" first to remove lifecycle protection.

## Next Steps

1. **Add dashboards** - Create CloudWatch dashboards
2. **Set up alarms** - Alert on errors and latency
3. **Add metrics** - Custom application metrics
4. **Production hardening** - DR, backup, monitoring
5. **Scale testing** - Load test Lambda and Lex

## Additional Resources

- [Basic Lambda Example](../lex-with-lambda)
- [Lambda Fulfillment Module](../../modules/lambda-fulfillment/README.md)
- [CloudWatch Logs Module](../../modules/cloudwatch-logs/README.md)
- [Main Documentation](../../README.md)