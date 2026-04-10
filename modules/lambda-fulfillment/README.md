# Lambda Fulfillment Module

Terraform module for creating AWS Lambda functions optimized for Amazon Lex V2 bot fulfillment.

## Features

- ✅ **Lex Integration** - Automatic permissions for Lex to invoke Lambda
- ✅ **Versioning** - Published versions for stable deployments
- ✅ **CloudWatch Logs** - Automatic log group permissions
- ✅ **VPC Support** - Optional VPC configuration for private resources
- ✅ **X-Ray Tracing** - Built-in distributed tracing
- ✅ **Environment Variables** - Global and per-function configuration
- ✅ **IAM Roles** - Automatic role creation with least privilege
- ✅ **Lambda Aliases** - Optional alias creation for environments

## Usage

### Basic Example

```hcl
module "lambda_fulfillment" {
  source = "infrakraft/lexv2models/aws//modules/lambda-fulfillment"
  version = "1.4.0"
  
  lambda_functions = {
    claims_handler = {
      namespace    = "insurance-bot"
      description  = "Handles insurance claim submissions"
      handler      = "index.handler"
      runtime      = "python3.11"
      timeout      = 30
      memory_size  = 512
      s3_bucket    = "my-lambda-artifacts"
      s3_key       = "claims_handler.zip"
    }
  }
  
  enable_lex_invocation = true
  
  tags = {
    Environment = "production"
  }
}
```

### With Environment Variables

```hcl
module "lambda_fulfillment" {
  source = "infrakraft/lexv2models/aws//modules/lambda-fulfillment"
  version = "1.4.0"
  
  lambda_functions = {
    claims_handler = {
      namespace    = "insurance-bot"
      description  = "Claims processing"
      handler      = "index.handler"
      runtime      = "python3.11"
      timeout      = 30
      memory_size  = 512
      s3_bucket    = "my-lambda-artifacts"
      s3_key       = "claims_handler.zip"
      
      # Function-specific variables
      environment_variables = {
        TABLE_NAME = "claims-table"
        API_ENDPOINT = "https://api.example.com"
      }
    }
  }
  
  # Global variables (applied to all functions)
  global_environment_variables = {
    ENVIRONMENT = "production"
    LOG_LEVEL   = "INFO"
  }
}
```

### With VPC Configuration

```hcl
module "lambda_fulfillment" {
  source = "infrakraft/lexv2models/aws//modules/lambda-fulfillment"
  version = "1.4.0"
  
  lambda_functions = { ... }
  
  # VPC configuration for accessing RDS, ElastiCache, etc.
  vpc_config = {
    subnet_ids         = ["subnet-abc123", "subnet-def456"]
    security_group_ids = ["sg-xyz789"]
  }
}
```

### Multiple Functions

```hcl
module "lambda_fulfillment" {
  source = "infrakraft/lexv2models/aws//modules/lambda-fulfillment"
  version = "1.4.0"
  
  lambda_functions = {
    claims_handler = {
      namespace    = "insurance-bot"
      description  = "Process insurance claims"
      handler      = "claims.handler"
      runtime      = "python3.11"
      timeout      = 30
      memory_size  = 512
      s3_bucket    = "lambda-artifacts"
      s3_key       = "claims_handler.zip"
    }
    
    policy_lookup = {
      namespace    = "insurance-bot"
      description  = "Look up policy details"
      handler      = "policy.handler"
      runtime      = "python3.11"
      timeout      = 10
      memory_size  = 256
      s3_bucket    = "lambda-artifacts"
      s3_key       = "policy_lookup.zip"
    }
    
    quote_calculator = {
      namespace    = "insurance-bot"
      description  = "Calculate insurance quotes"
      handler      = "quote.handler"
      runtime      = "nodejs18.x"
      timeout      = 15
      memory_size  = 512
      s3_bucket    = "lambda-artifacts"
      s3_key       = "quote_calculator.zip"
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| lambda_functions | Map of Lambda function configurations | `map(object)` | n/a | yes |
| enable_lex_invocation | Grant Lex permission to invoke functions | `bool` | `true` | no |
| global_environment_variables | Environment variables for all functions | `map(string)` | `{}` | no |
| vpc_config | VPC configuration (subnet_ids, security_group_ids) | `object` | `null` | no |
| create_aliases | Create Lambda aliases | `bool` | `false` | no |
| alias_name | Name of the alias (if create_aliases is true) | `string` | `"live"` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

### lambda_functions Object Structure

```hcl
{
  function_name = {
    namespace                      = string           # Required: Naming prefix
    description                    = string           # Required: Function description
    handler                        = string           # Required: Entry point (e.g., "index.handler")
    runtime                        = string           # Required: Runtime (e.g., "python3.11")
    timeout                        = number           # Required: Timeout in seconds (1-900)
    memory_size                    = number           # Required: Memory in MB (128-10240)
    s3_bucket                      = string           # Required: S3 bucket for code
    s3_key                         = string           # Required: S3 key for code
    kms_key_arn                    = optional(string) # Optional: KMS encryption key
    reserved_concurrent_executions = optional(number) # Optional: Reserved concurrency (-1 = unlimited)
    source_code_hash               = optional(string) # Optional: Code hash for updates
    environment_variables          = optional(map)    # Optional: Function-specific env vars
    tags                           = optional(map)    # Optional: Additional tags
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| lambda_function_arns | ARNs of all Lambda functions |
| lambda_function_names | Names of all Lambda functions |
| lambda_qualified_arns | Qualified ARNs (with version) - **Use this for Lex** |
| lambda_versions | Latest published versions |
| lambda_role_arns | IAM role ARNs |
| functions | Complete function details (name, ARN, qualified ARN, version) |

## Lex Integration

### Connecting Lambda to Lex

```hcl
# 1. Create Lambda functions
module "lambda_fulfillment" {
  source = "infrakraft/lexv2models/aws//modules/lambda-fulfillment"
  version = "1.4.0"
  
  lambda_functions = {
    claims_handler = { ... }
  }
}

# 2. Pass to Lex module
module "lex_bot" {
  source = "infrakraft/lexv2models/aws"
  version = "1.4.0"
  
  bot_config = {
    # ... bot configuration
    locales = {
      en_US = {
        intents = {
          FileClaimIntent = {
            # Reference Lambda by name
            fulfillment_lambda_name = "claims_handler"
            fulfillment_code_hook = { enabled = true }
          }
        }
      }
    }
  }
  
  # Provide Lambda ARNs
  lambda_arns = module.lambda_fulfillment.lambda_qualified_arns
}
```

**Important:** Always use `qualified_arn` (includes version) for Lex integration, not the base ARN.

## Lambda Function Code Structure

### Python Example

```python
# index.py
import json

def handler(event, context):
    """
    Lex V2 fulfillment handler
    
    Event structure:
    {
      "sessionId": "...",
      "inputTranscript": "...",
      "interpretations": [...],
      "sessionState": {
        "intent": {
          "name": "FileClaimIntent",
          "slots": {
            "PolicyNumber": { "value": { "interpretedValue": "ABC123" } },
            "ClaimType": { "value": { "interpretedValue": "Accident" } }
          }
        }
      }
    }
    """
    
    # Extract intent and slots
    intent = event['sessionState']['intent']
    slots = intent['slots']
    
    # Business logic
    policy_number = slots['PolicyNumber']['value']['interpretedValue']
    claim_type = slots['ClaimType']['value']['interpretedValue']
    
    # Process claim
    claim_id = process_claim(policy_number, claim_type)
    
    # Return Lex response
    return {
        "sessionState": {
            "dialogAction": {
                "type": "Close"
            },
            "intent": {
                "name": intent['name'],
                "state": "Fulfilled"
            }
        },
        "messages": [
            {
                "contentType": "PlainText",
                "content": f"Your claim {claim_id} has been submitted successfully."
            }
        ]
    }

def process_claim(policy_number, claim_type):
    # Your business logic here
    import uuid
    return str(uuid.uuid4())[:8]
```

### Node.js Example

```javascript
// index.js
exports.handler = async (event) => {
    // Extract intent and slots
    const intent = event.sessionState.intent;
    const slots = intent.slots;
    
    const policyNumber = slots.PolicyNumber.value.interpretedValue;
    const claimType = slots.ClaimType.value.interpretedValue;
    
    // Process claim
    const claimId = await processClaim(policyNumber, claimType);
    
    // Return Lex response
    return {
        sessionState: {
            dialogAction: {
                type: 'Close'
            },
            intent: {
                name: intent.name,
                state: 'Fulfilled'
            }
        },
        messages: [
            {
                contentType: 'PlainText',
                content: `Your claim ${claimId} has been submitted successfully.`
            }
        ]
    };
};

async function processClaim(policyNumber, claimType) {
    // Your business logic
    return Math.random().toString(36).substring(7);
}
```

## Deployment Package

### Creating the ZIP File

**Python:**
```bash
# Install dependencies
pip install -r requirements.txt -t ./package

# Create deployment package
cd package
zip -r ../claims_handler.zip .
cd ..
zip -g claims_handler.zip index.py

# Upload to S3
aws s3 cp claims_handler.zip s3://my-lambda-artifacts/
```

**Node.js:**
```bash
# Install dependencies
npm install

# Create deployment package
zip -r claims_handler.zip index.js node_modules/

# Upload to S3
aws s3 cp claims_handler.zip s3://my-lambda-artifacts/
```

### Using Terraform to Upload

```hcl
# Generate hash of source code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/claims_handler"
  output_path = "${path.module}/lambda/claims_handler.zip"
}

# Upload to S3
resource "aws_s3_object" "lambda_package" {
  bucket = "my-lambda-artifacts"
  key    = "claims_handler.zip"
  source = data.archive_file.lambda_zip.output_path
  etag   = filemd5(data.archive_file.lambda_zip.output_path)
}

# Use in Lambda module
module "lambda_fulfillment" {
  source = "infrakraft/lexv2models/aws//modules/lambda-fulfillment"
  version = "1.4.0"
  
  lambda_functions = {
    claims_handler = {
      # ... other config
      s3_bucket        = aws_s3_object.lambda_package.bucket
      s3_key           = aws_s3_object.lambda_package.key
      source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    }
  }
}
```

## IAM Permissions

### Default Permissions

The module automatically creates:
- ✅ `AWSLambdaBasicExecutionRole` - CloudWatch Logs
- ✅ `AWSLambdaVPCAccessExecutionRole` - VPC access (if VPC configured)
- ✅ Lambda invoke permission for Lex V2

### Adding Custom Permissions

```hcl
module "lambda_fulfillment" {
  source = "infrakraft/lexv2models/aws//modules/lambda-fulfillment"
  version = "1.4.0"
  
  lambda_functions = { ... }
}

# Add DynamoDB access
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
          "dynamodb:Query"
        ]
        Resource = aws_dynamodb_table.claims.arn
      }
    ]
  })
}
```

## Monitoring

### CloudWatch Logs

Logs are automatically sent to: `/aws/lambda/{function_name}`

View logs:
```bash
aws logs tail /aws/lambda/claims_handler --follow
```

### X-Ray Tracing

X-Ray is enabled by default. View traces in AWS Console:
1. Go to AWS X-Ray
2. View service map
3. Analyze traces

### Metrics

Available CloudWatch metrics:
- `Invocations` - Number of invocations
- `Duration` - Execution time
- `Errors` - Error count
- `Throttles` - Throttled invocations
- `ConcurrentExecutions` - Concurrent executions

## Best Practices

### 1. Use Environment Variables

```hcl
global_environment_variables = {
  ENVIRONMENT = "production"
  LOG_LEVEL   = "INFO"
}
```

### 2. Set Appropriate Timeouts

- Simple lookups: 3-10 seconds
- API calls: 10-30 seconds
- Database operations: 15-30 seconds
- Maximum: 900 seconds (15 minutes)

### 3. Optimize Memory

Start with 512 MB and adjust based on:
- CloudWatch Logs memory usage
- Duration vs memory cost tradeoff
- Use AWS Lambda Power Tuning

### 4. Use Reserved Concurrency

For critical functions:
```hcl
reserved_concurrent_executions = 10
```

### 5. Version Your Code

Always use `source_code_hash` for automatic updates:
```hcl
source_code_hash = filebase64sha256("lambda.zip")
```

## Troubleshooting

### Lambda Not Invoked by Lex

**Check permissions:**
```bash
aws lambda get-policy --function-name claims_handler
```

Should show `lexv2.amazonaws.com` as principal.

**Verify ARN in Lex:**
- Use `qualified_arn` (includes version)
- Not the base ARN

### Timeout Errors

Increase timeout:
```hcl
timeout = 60  # seconds
```

Or optimize code.

### Memory Errors

Increase memory:
```hcl
memory_size = 1024  # MB
```

### VPC Issues

If Lambda can't connect to internet:
- Ensure NAT Gateway in VPC
- Check security group rules
- Verify subnet routing

## Cost Optimization

### Pricing Factors

- Requests: $0.20 per 1M requests
- Duration: $0.0000166667 per GB-second
- Free tier: 1M requests + 400,000 GB-seconds/month

### Example Costs

**Small bot (1,000 invocations/month):**
- Memory: 512 MB
- Duration: 100ms average
- Cost: **~$0.00** (free tier)

**Medium bot (100,000 invocations/month):**
- Memory: 512 MB
- Duration: 200ms average
- Cost: **~$2.08/month**

**Large bot (1M invocations/month):**
- Memory: 512 MB
- Duration: 300ms average
- Cost: **~$25/month**

### Optimization Tips

1. **Reduce cold starts** - Keep functions warm with scheduled invocations
2. **Right-size memory** - Use Lambda Power Tuning
3. **Minimize dependencies** - Smaller packages = faster cold starts
4. **Use connection pooling** - Reuse database connections
5. **Enable provisioned concurrency** - For latency-sensitive applications (additional cost)

## Examples

- [Basic Lambda Fulfillment](../../examples/lex-with-lambda)
- [Lambda with CloudWatch Logs](../../examples/lex-with-lambda-and-cloudwatch-logs)

## Additional Resources

- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/)
- [Lex V2 Lambda Integration](https://docs.aws.amazon.com/lexv2/latest/dg/lambda.html)
- [Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)