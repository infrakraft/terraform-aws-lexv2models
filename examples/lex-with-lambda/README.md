# Lex Bot with Lambda Fulfillment Example

This example demonstrates integrating **AWS Lambda functions** with a Lex bot for business logic fulfillment and validation.

## What This Example Shows

- ✅ Lambda functions for Lex bot fulfillment
- ✅ Multiple Lambda handlers (claims, policy lookup)
- ✅ Automatic Lex invoke permissions
- ✅ Lambda versioning for stable deployments
- ✅ Environment-specific configurations
- ✅ Bot building with Lambda integration
- ✅ Complete insurance bot with real fulfillment

## Architecture

┌─────────────────────────────────┐
│   User Interaction              │
└────────┬────────────────────────┘
│
↓
┌─────────────────────────────────┐
│   AWS Lex V2 Bot               │
│                                 │
│   Intents:                      │
│   • FileClaimIntent             │
│   • CheckPolicyIntent           │
└────────┬────────────────────────┘
│
│ Fulfillment Requests
↓
┌─────────────────────────────────┐
│   Lambda Functions              │
│                                 │
│   • claims_handler              │
│     - Process claims            │
│     - Generate claim ID         │
│                                 │
│   • policy_lookup               │
│     - Retrieve policy details   │
│     - Validate policy           │
└─────────────────────────────────┘

## What Gets Created

1. **Lambda Functions** - Two fulfillment functions
   - `claims_handler` - Processes insurance claims
   - `policy_lookup` - Looks up policy information

2. **IAM Roles** - Automatic role creation
   - Lambda execution roles
   - CloudWatch Logs permissions
   - Lex invoke permissions

3. **Lex Bot** - Insurance bot with Lambda integration
   - FileClaimIntent → claims_handler
   - CheckPolicyIntent → policy_lookup

## Prerequisites

1. **AWS Account** with permissions for:
   - Lambda
   - Lex V2
   - IAM
   - S3
2. **Terraform** >= 1.0
3. **jq** installed
4. **AWS CLI** configured
5. **S3 bucket** for Lambda deployment packages
6. **Lambda code packages** uploaded to S3

## Quick Start

### Step 1: Prepare Lambda Deployment Packages

**Create claims_handler package:**

```bash
cd lambda/claims_handler

# Create deployment package
zip claims_handler.zip index.py

# Upload to S3
aws s3 cp claims_handler.zip s3://YOUR-BUCKET-NAME/
```

**Create policy_lookup package:**

```bash
cd ../policy_lookup

# Create deployment package
zip policy_lookup.zip index.py

# Upload to S3
aws s3 cp policy_lookup.zip s3://YOUR-BUCKET-NAME/
```

### Step 2: Configure Variables

Create `terraform.tfvars`:

```hcl
aws_region       = "eu-west-1"
environment      = "dev"
lambda_s3_bucket = "YOUR-BUCKET-NAME"  # Replace with your bucket
auto_build       = true
wait_for_build   = true
create_version   = false
```

### Step 3: Deploy

```bash
# Initialize
terraform init

# Review plan
terraform plan

# Deploy
terraform apply
```

### Step 4: Test the Bot

**Get bot ID:**

```bash
BOT_ID=$(terraform output -raw bot_id)
```

**Test FileClaimIntent:**

```bash
aws lexv2-runtime recognize-text \
  --bot-id "$BOT_ID" \
  --bot-alias-id TSTALIASID \
  --locale-id en_US \
  --session-id test-session-$(date +%s) \
  --text "I need to file a claim"
```

**Follow the conversation:**

```bash
# Bot: What is your policy number?
aws lexv2-runtime recognize-text \
  --bot-id "$BOT_ID" \
  --bot-alias-id TSTALIASID \
  --locale-id en_US \
  --session-id test-session-123 \
  --text "POL123456"

# Bot: What type of claim would you like to file?
aws lexv2-runtime recognize-text \
  --bot-id "$BOT_ID" \
  --bot-alias-id TSTALIASID \
  --locale-id en_US \
  --session-id test-session-123 \
  --text "Accident"

# Bot: When did the incident occur?
aws lexv2-runtime recognize-text \
  --bot-id "$BOT_ID" \
  --bot-alias-id TSTALIASID \
  --locale-id en_US \
  --session-id test-session-123 \
  --text "yesterday"

# Bot: Your Accident claim has been submitted successfully. Claim ID: CLM-XXXXXXXX
```

**Test CheckPolicyIntent:**

```bash
aws lexv2-runtime recognize-text \
  --bot-id "$BOT_ID" \
  --bot-alias-id TSTALIASID \
  --locale-id en_US \
  --session-id test-session-$(date +%s) \
  --text "Check my policy POL123456"
```

### Step 5: View Lambda Logs

```bash
# Claims handler logs
aws logs tail /aws/lambda/claims_handler --follow

# Policy lookup logs
aws logs tail /aws/lambda/policy_lookup --follow
```

## Lambda Function Details

### claims_handler

**Purpose:** Process insurance claim submissions

**Inputs (slots):**
- `PolicyNumber` - Insurance policy number
- `ClaimType` - Type of claim (Accident, Theft, etc.)
- `IncidentDate` - Date of incident

**Output:**
- Claim ID (e.g., CLM-A1B2C3D4)
- Confirmation message

**Configuration:**
- Runtime: Python 3.11
- Timeout: 30 seconds
- Memory: 512 MB

### policy_lookup

**Purpose:** Look up policy details

**Inputs (slots):**
- `PolicyNumber` - Insurance policy number

**Output:**
- Policy type
- Coverage amount
- Premium

**Configuration:**
- Runtime: Python 3.11
- Timeout: 10 seconds
- Memory: 256 MB

## Customizing Lambda Functions

### Adding Environment Variables

```hcl
# In locals
lambda_functions = {
  claims_handler = {
    # ... other config
    
    environment_variables = {
      TABLE_NAME    = "claims-${var.environment}"
      API_ENDPOINT  = "https://api.example.com"
      TIMEOUT_MS    = "5000"
    }
  }
}
```

### Adding Database Access

```hcl
# Add IAM policy for DynamoDB
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "lambda-dynamodb-access"
  role = module.lambda_fulfillment.lambda_role_arns["claims_handler"]
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.claims.arn
      }
    ]
  })
}
```

### Using with VPC

```hcl
# In lambda_fulfillment module
module "lambda_fulfillment" {
  source = "../../modules/lambda-fulfillment"
  
  lambda_functions = local.lambda_functions
  
  # Add VPC configuration
  vpc_config = {
    subnet_ids         = ["subnet-abc123", "subnet-def456"]
    security_group_ids = ["sg-xyz789"]
  }
}
```

## Testing Lambda Locally

### Python Local Test

```bash
cd lambda/claims_handler

# Run local test
python3 index.py
```

Expected output:
```json
{
  "sessionState": {
    "dialogAction": {
      "type": "Close"
    },
    "intent": {
      "name": "FileClaimIntent",
      "state": "Fulfilled"
    }
  },
  "messages": [
    {
      "contentType": "PlainText",
      "content": "Your Accident claim has been submitted successfully..."
    }
  ]
}
```

### Invoke Lambda Directly

```bash
# Create test event
cat > test-event.json << 'EOF'
{
  "sessionState": {
    "intent": {
      "name": "FileClaimIntent",
      "slots": {
        "PolicyNumber": {
          "value": {
            "interpretedValue": "POL123456"
          }
        },
        "ClaimType": {
          "value": {
            "interpretedValue": "Accident"
          }
        },
        "IncidentDate": {
          "value": {
            "interpretedValue": "2025-04-01"
          }
        }
      }
    }
  }
}
EOF

# Invoke Lambda
aws lambda invoke \
  --function-name claims_handler \
  --payload file://test-event.json \
  response.json

# View response
cat response.json | jq .
```

## Monitoring

### CloudWatch Metrics

Available metrics:
- `Invocations` - Number of Lambda invocations
- `Duration` - Execution time
- `Errors` - Error count
- `Throttles` - Throttled requests

### CloudWatch Insights Queries

**Find all claims processed:**

```sql
fields @timestamp, @message
| filter @message like /Processing claim/
| sort @timestamp desc
| limit 100
```

**Calculate average processing time:**

```sql
fields @duration
| stats avg(@duration) as avg_duration, 
        max(@duration) as max_duration,
        min(@duration) as min_duration
```

**Find errors:**

```sql
fields @timestamp, @message
| filter @type = "ERROR"
| sort @timestamp desc
```

## Deployment Patterns

### Development

```hcl
environment      = "dev"
auto_build       = true
wait_for_build   = false  # Faster iterations
create_version   = false
```

### Staging

```hcl
environment      = "staging"
auto_build       = true
wait_for_build   = true
create_version   = true
```

### Production

```hcl
environment      = "prod"
auto_build       = true
wait_for_build   = true
create_version   = true

# Use aliases
create_aliases   = true
alias_name       = "prod"
```

## Troubleshooting

### Lambda Not Invoked

**Check permissions:**

```bash
aws lambda get-policy --function-name claims_handler
```

Should show `lexv2.amazonaws.com` principal.

**Verify ARN in bot:**

```bash
# Check what ARN Lex is using
aws lexv2-models describe-intent \
  --bot-id "$BOT_ID" \
  --bot-version DRAFT \
  --locale-id en_US \
  --intent-id <INTENT_ID>
```

### Lambda Errors

**View logs:**

```bash
aws logs tail /aws/lambda/claims_handler --since 10m
```

**Check for common issues:**
- Missing environment variables
- Timeout (increase timeout)
- Memory errors (increase memory)
- IAM permission errors

### Bot Not Building

Check slot priorities and building status in CloudWatch Logs.

## Cost Estimate

### Lambda Costs

**Development (100 invocations/day):**
- Requests: ~3,000/month = $0.00 (free tier)
- Duration: ~$0.00 (free tier)
- **Total: $0.00/month**

**Production (1,000 invocations/day):**
- Requests: ~30,000/month = $0.00 (free tier)
- Duration: ~$0.83/month
- **Total: ~$0.83/month**

### Lex Costs

- Text requests: $0.75 per 1,000 requests
- Voice requests: $4.00 per 1,000 requests
- Free tier: 10,000 text requests/month

**Total estimated cost: $0-5/month** for development/testing

## Next Steps

1. **Add CloudWatch Logs** - See [lex-with-lambda-and-cloudwatch-logs](../lex-with-lambda-and-cloudwatch-logs)
2. **Add database** - DynamoDB or RDS for persistence
3. **Add API integration** - Connect to backend services
4. **Add error handling** - Implement retry logic
5. **Add validation** - Validate slots before fulfillment
6. **Production hardening** - Add monitoring, alerting, disaster recovery

## Additional Resources

- [Main Module Documentation](../../README.md)
- [Lambda Fulfillment Module](../../modules/lambda-fulfillment/README.md)
- [AWS Lambda for Lex](https://docs.aws.amazon.com/lexv2/latest/dg/lambda.html)
- [Lex V2 Response Format](https://docs.aws.amazon.com/lexv2/latest/dg/lambda-response-format.html)