# Terraform AWS Lex V2 Models Module

[![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-623CE4?logo=terraform)](https://registry.terraform.io/modules/infrakraft/lexv2models/aws/latest)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![TFLint](https://img.shields.io/badge/TFLint-Enabled-blue)](https://github.com/terraform-linters/tflint)
[![Validated](https://img.shields.io/badge/Schema-Validated-green)](schema/bot_config_schema.json)

A comprehensive Terraform module for creating and managing AWS Lex V2 bots with support for Lambda fulfillment, versioning, automatic building, conversation logs, and JSON schema validation.

## Features

- ✅ **JSON Schema Validation** - Validate bot configurations before deployment (v1.5.0)
- ✅ **Conversation Logs** - CloudWatch and S3 logging for monitoring (v1.5.0)
- ✅ **Slot Obfuscation** - PII protection with configurable obfuscation (v1.5.0)
- ✅ **Lambda Fulfillment** - Modular Lambda function creation (v1.4.0)
- ✅ **CloudWatch Logging** - Conversation monitoring and debugging (v1.3.0)
- ✅ **Automatic Bot Building** - Build bots automatically after deployment (v1.2.0)
- ✅ **Bot Versioning** - Create immutable snapshots for production (v1.1.0)
- ✅ **Multi-Locale Support** - Configure multiple languages and locales
- ✅ **IAM Role Management** - Automatic IAM role creation with proper permissions
- ✅ **TFLint Validated** - Code quality and best practices enforced

## Quick Start

```hcl
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.5.0"

  bot_config = {
    name               = "CustomerServiceBot"
    type               = "Bot"
    idle_session_ttl   = 300
    child_directed     = false
    
    locales = {
      en_US = {
        description          = "US English"
        confidence_threshold = 0.4
        
        voice_settings = {
          voice_id = "Joanna"
          engine   = "neural"
        }
        
        intents = {
          Greeting = {
            description = "Greet the user"
            sample_utterances = [
              "Hello",
              "Hi there",
              "Good morning"
            ]
            closing_prompt = {
              message = "Hello! How can I help you today?"
            }
          }
        }
      }
    }
  }
  
  lexv2_bot_role_name = "customer-service-bot-role"
}
```

## What's New in v1.5.0

### 🎯 JSON Schema Validation

Catch configuration errors **before** deployment with automated schema validation:

```bash
# Validate your bot configuration
./validate_schema.sh examples/my-bot/bot_config.json schema/bot_config_schema.json

# Run all validation checks
./terraform-preflight.sh
```

**Benefits:**
- ✅ Catch errors early in development
- ✅ Ensure AWS API compliance
- ✅ Prevent deployment failures
- ✅ Integrated into CI/CD pipelines

### 🔒 Slot Obfuscation for PII Protection

Protect sensitive data with built-in obfuscation:

```json
{
  "intents": {
    "AccountInquiry": {
      "slots": {
        "Email": {
          "slot_type": "AMAZON.EmailAddress",
          "obfuscation": "DefaultObfuscation"
        },
        "AccountNumber": {
          "slot_type": "AMAZON.Number",
          "obfuscation": "DefaultObfuscation"
        }
      }
    }
  }
}
```

**Compliance:**
- ✅ PCI DSS - Credit card data protection
- ✅ HIPAA - Health information privacy
- ✅ GDPR - Personal data protection
- ✅ SOC 2 - Information security

### 📊 Conversation Logs Module

Monitor and debug conversations with CloudWatch and S3:

```hcl
module "conversation_logs" {
  source  = "infrakraft/lexv2models/aws//modules/conversation-logs"
  version = "1.5.0"
  
  bot_id             = module.lex_bot.bot_id
  enable_text_logs   = true
  log_retention_days = 30
  enable_audio_logs  = false
  
  tags = {
    Environment = "production"
  }
}
```

## JSON Schema Validation (v1.5.0)

### Prerequisites

Install Python dependencies:

```bash
pip3 install jsonschema
```

### Validate Configuration

```bash
# Validate single file
python3 validate_schema.py examples/my-bot/bot_config.json schema/bot_config_schema.json

# Or use the wrapper script
./validate_schema.sh examples/my-bot/bot_config.json schema/bot_config_schema.json

# Validate all examples
./terraform-preflight.sh
```

### Schema Features

The schema validates:

- ✅ **Required fields** - name, type, idle_session_ttl, child_directed, locales
- ✅ **Field types** - string, number, boolean, object, array
- ✅ **Value ranges** - idle_session_ttl (60-86400), confidence_threshold (0.0-1.0)
- ✅ **Enum values** - voice engine (standard/neural), obfuscation (None/DefaultObfuscation)
- ✅ **Locale IDs** - en_US, en_GB, es_ES, fr_FR, de_DE, etc.
- ✅ **Intent structure** - sample_utterances, slots, confirmation prompts
- ✅ **Slot configuration** - slot_type, obfuscation, prompts, max_retries
- ✅ **Voice settings** - voice_id, engine
- ✅ **Slot types** - values, synonyms, value_selection_strategy

### CI/CD Integration

Schema validation is automatically run in GitHub Actions:

```yaml
# .github/workflows/validate.yml
jobs:
  schema-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: pip install jsonschema
      - run: python3 validate_schema.py bot_config.json schema/bot_config_schema.json
```

## Slot Obfuscation (v1.5.0)

### Configuration

Add `obfuscation` to sensitive slots in your `bot_config.json`:

```json
{
  "locales": {
    "en_US": {
      "intents": {
        "ProcessPayment": {
          "slots": {
            "CreditCardNumber": {
              "description": "Last 4 digits of credit card",
              "slot_type": "AMAZON.Number",
              "required": true,
              "prompt": "What are the last 4 digits of your card?",
              "obfuscation": "DefaultObfuscation"
            },
            "Email": {
              "description": "Customer email",
              "slot_type": "AMAZON.EmailAddress",
              "required": true,
              "prompt": "What is your email address?",
              "obfuscation": "DefaultObfuscation"
            },
            "OrderNumber": {
              "description": "Order number (not sensitive)",
              "slot_type": "AMAZON.AlphaNumeric",
              "required": true,
              "prompt": "What is your order number?",
              "obfuscation": "None"
            }
          }
        }
      }
    }
  }
}
```

### Obfuscation Options

| Value | Description | Use Cases |
|-------|-------------|-----------|
| `None` | No obfuscation (default) | Order numbers, public IDs, non-sensitive data |
| `DefaultObfuscation` | Mask in logs/history | Email, phone, SSN, account numbers, credit cards |

### What Gets Obfuscated?

When `DefaultObfuscation` is enabled:

- ✅ **CloudWatch Logs** - Value is masked
- ✅ **S3 Audio Logs** - Value is masked in metadata
- ✅ **Conversation History** - Value is masked
- ❌ **Lambda Event** - Value is **NOT** masked (Lambda receives actual value)

### Best Practices

**Always obfuscate:**
- Credit card numbers
- Social Security Numbers (SSN)
- Account numbers
- Passwords/PINs
- Email addresses (for privacy)
- Phone numbers (for privacy)
- Addresses (for privacy)

**Don't obfuscate:**
- Order numbers (needed for support)
- Public identifiers
- Non-sensitive selections (status, type, category)

## Conversation Logs (v1.5.0)

### CloudWatch Text Logs

```hcl
module "conversation_logs" {
  source  = "infrakraft/lexv2models/aws//modules/conversation-logs"
  version = "1.5.0"
  
  bot_id = module.lex_bot.bot_id
  
  # Text logs
  enable_text_logs   = true
  log_retention_days = 30  # 1-3653 days
  
  # Optional KMS encryption
  kms_key_id = aws_kms_key.logs.arn
  
  tags = {
    Environment = "production"
  }
}
```

### S3 Audio Logs

```hcl
module "conversation_logs" {
  source  = "infrakraft/lexv2models/aws//modules/conversation-logs"
  version = "1.5.0"
  
  bot_id = module.lex_bot.bot_id
  
  # Audio logs
  enable_audio_logs = true
  s3_bucket_name    = "my-lex-audio-logs"
  s3_lifecycle_days = 90  # Auto-delete after 90 days
  
  tags = {
    Environment = "production"
  }
}
```

### Manual Alias Configuration

⚠️ **Important:** Bot aliases are not yet supported by Terraform. Configure logging manually:

```bash
# Get bot ID and log group
BOT_ID=$(terraform output -raw bot_id)
LOG_GROUP=$(terraform output -raw cloudwatch_log_group)

# Create alias
aws lexv2-models create-bot-alias \
  --bot-id $BOT_ID \
  --bot-alias-name production \
  --bot-version 1

# Configure logging
aws lexv2-models update-bot-alias \
  --bot-id $BOT_ID \
  --bot-alias-id <ALIAS_ID> \
  --conversation-log-settings \
    textLogSettings=[{destination={cloudWatchLogs={cloudWatchLogGroupArn=<LOG_GROUP_ARN>,logPrefix=lex/}},enabled=true}]
```

## Lambda Fulfillment (v1.4.0)

Connect Lambda functions for business logic:

```hcl
module "lambda_fulfillment" {
  source  = "infrakraft/lexv2models/aws//modules/lambda-fulfillment"
  version = "1.5.0"
  
  lambda_functions = {
    order_handler = {
      namespace    = "my-bot"
      description  = "Handles order processing"
      handler      = "index.handler"
      runtime      = "python3.11"
      timeout      = 30
      memory_size  = 512
      s3_bucket    = "my-lambda-bucket"
      s3_key       = "order_handler.zip"
    }
  }
  
  enable_xray_tracing = false  # Save ~$5-10/month
}

module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.5.0"
  
  bot_config = {
    # ... configuration with fulfillment_lambda_name ...
  }
  
  lambda_arns = module.lambda_fulfillment.lambda_qualified_arns
}
```

## Bot Building (v1.2.0)

Automatically build bots after deployment:

```hcl
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.5.0"
  
  bot_config = { ... }
  
  # Enable automatic building
  auto_build_bot_locales    = true
  wait_for_build_completion = true
  build_timeout_seconds     = 300
}
```

## Bot Versioning (v1.1.0)

Create immutable snapshots for production:

```hcl
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.5.0"
  
  bot_config = { ... }
  
  # Enable versioning
  create_bot_version      = true
  bot_version_description = "v1.0 - Production release"
}
```

## Examples

Complete working examples:

- **[lex-production-ready](./examples/lex-production-ready)** - **⭐ Complete production setup** (v1.5.0)
  - JSON schema validation
  - Conversation logs (CloudWatch + S3)
  - Slot obfuscation for PII
  - Lambda fulfillment
  - Multi-locale (en_US, en_GB)
  - Bot versioning
  - Cost optimization

- **[lex-with-lambda-and-cloudwatch-logs](./examples/lex-with-lambda-and-cloudwatch-logs)** - Lambda + CloudWatch (v1.4.0)
- **[lex-with-lambda](./examples/lex-with-lambda)** - Basic Lambda integration (v1.4.0)
- **[lex-with-cloudwatch-logs](./examples/lex-with-cloudwatch-logs)** - CloudWatch logging (v1.3.0)
- **[lex-with-building](./examples/lex-with-building)** - Automatic building (v1.2.0)
- **[lex-with-versioning](./examples/lex-with-versioning)** - Bot versioning (v1.1.0)
- **[lex-only](./examples/lex-only)** - Basic bot (v1.0.0)

## Complete Production Example

Full-stack deployment with all v1.5.0 features:

```hcl
# ===========================================================================
# JSON Schema Validation (run before terraform apply)
# ===========================================================================
# ./validate_schema.sh bot_config.json schema/bot_config_schema.json

# ===========================================================================
# Conversation Logs
# ===========================================================================
module "conversation_logs" {
  source  = "infrakraft/lexv2models/aws//modules/conversation-logs"
  version = "1.5.0"
  
  bot_id = module.lex_bot.bot_id
  
  # CloudWatch text logs
  enable_text_logs   = true
  log_retention_days = 90
  
  # S3 audio logs
  enable_audio_logs = true
  s3_bucket_name    = "prod-lex-audio-logs"
  s3_lifecycle_days = 180
  
  # Encryption
  kms_key_id = aws_kms_key.logs.arn
  
  tags = {
    Environment = "production"
    Compliance  = "PII-Protected"
  }
}

# ===========================================================================
# Lambda Fulfillment
# ===========================================================================
module "lambda_fulfillment" {
  source  = "infrakraft/lexv2models/aws//modules/lambda-fulfillment"
  version = "1.5.0"
  
  lambda_functions = {
    order_handler = {
      namespace    = "production-bot"
      description  = "Handles order processing"
      handler      = "index.handler"
      runtime      = "python3.11"
      timeout      = 30
      memory_size  = 512
      s3_bucket    = aws_s3_bucket.lambda_artifacts.id
      s3_key       = "order_handler.zip"
      
      environment_variables = {
        TABLE_NAME = "orders"
      }
    }
  }
  
  # Production observability
  enable_xray_tracing = true
  
  # Dead Letter Queue
  dead_letter_config = {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
  
  # VPC for RDS access
  vpc_config = {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }
}

# ===========================================================================
# Lex Bot with All Features
# ===========================================================================
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.5.0"
  
  # Bot configuration (validated with schema)
  bot_config = jsondecode(file("${path.module}/bot_config.json"))
  
  lexv2_bot_role_name = "production-bot-role"
  
  # Lambda integration
  lambda_arns = module.lambda_fulfillment.lambda_qualified_arns
  
  # Bot building
  auto_build_bot_locales    = true
  wait_for_build_completion = true
  build_timeout_seconds     = 600
  
  # Bot versioning
  create_bot_version      = true
  bot_version_description = "v1.0 - Production release with PII protection"
  
  tags = {
    Environment = "production"
    Version     = "1.0"
    Compliance  = "PII-Protected"
  }
  
  depends_on = [
    module.lambda_fulfillment,
    module.conversation_logs
  ]
}
```

### bot_config.json with Obfuscation

```json
{
  "name": "production-bot",
  "type": "Bot",
  "idle_session_ttl": 900,
  "child_directed": false,
  "locales": {
    "en_US": {
      "description": "US English",
      "confidence_threshold": 0.6,
      "voice_settings": {
        "voice_id": "Joanna",
        "engine": "neural"
      },
      "intents": {
        "ProcessPayment": {
          "description": "Process customer payment",
          "sample_utterances": [
            "I want to make a payment",
            "Process payment"
          ],
          "slots": {
            "CreditCard": {
              "description": "Last 4 digits of card",
              "slot_type": "AMAZON.Number",
              "required": true,
              "prompt": "Last 4 digits of your card?",
              "obfuscation": "DefaultObfuscation"
            },
            "Email": {
              "description": "Customer email",
              "slot_type": "AMAZON.EmailAddress",
              "required": true,
              "prompt": "Your email address?",
              "obfuscation": "DefaultObfuscation"
            }
          }
        }
      }
    }
  }
}
```

## Cost Breakdown (Monthly)

### Development Environment
- Lex: $0 (free tier)
- Lambda: $0-1 (free tier)
- CloudWatch Logs: $0.50-1.00
- X-Ray: $0 (disabled)
- **Total: ~$0.50-2.00/month**

### Production Environment (Low Volume - 5K conversations/month)
- Lex: $2-5
- Lambda: $1-3
- CloudWatch Logs: $3-5
- S3 Audio Logs: $1-2
- X-Ray: $5-10 (if enabled)
- **Total: ~$12-25/month**

### Production Environment (Medium Volume - 50K conversations/month)
- Lex: $20-40
- Lambda: $10-20
- CloudWatch Logs: $15-25
- S3 Audio Logs: $5-10
- X-Ray: $10-20 (if enabled)
- **Total: ~$60-115/month**

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |
| null | >= 3.0 |

## Modules

| Name | Source | Version | Description |
|------|--------|---------|-------------|
| conversation-logs | ./modules/conversation-logs | - | CloudWatch & S3 logging (v1.5.0) |
| lambda-fulfillment | ./modules/lambda-fulfillment | - | Lambda function creation (v1.4.0) |
| cloudwatch-logs | ./modules/cloudwatch-logs | - | CloudWatch log groups (v1.3.0) |
| lexv2models | ./modules/lexv2models | - | Core Lex V2 resources |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bot_config | Complete bot configuration object | `any` | n/a | yes |
| lexv2_bot_role_name | IAM role name for Lex | `string` | n/a | yes |
| lambda_arns | Map of Lambda function ARNs | `map(string)` | `{}` | no |
| auto_build_bot_locales | Build bots automatically | `bool` | `true` | no |
| wait_for_build_completion | Wait for build | `bool` | `false` | no |
| create_bot_version | Create bot version | `bool` | `false` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bot_id | Bot unique identifier |
| bot_arn | Bot ARN |
| bot_name | Bot name |
| bot_version | Bot version number (if created) |
| bot_role_arn | IAM role ARN |

## Validation & Testing

### Local Validation

```bash
# Schema validation
./validate_schema.sh examples/my-bot/bot_config.json schema/bot_config_schema.json

# Terraform validation
terraform fmt -check -recursive
terraform validate

# TFLint
tflint --init
tflint --recursive

# Complete preflight checks
./terraform-preflight.sh
```

### CI/CD Validation

GitHub Actions automatically validates:
- ✅ JSON schema compliance
- ✅ Terraform formatting
- ✅ Terraform configuration
- ✅ TFLint rules
- ✅ Lambda code syntax

## Known Limitations

- **Bot Aliases** - Not yet supported by Terraform AWS provider
  - Workaround: Manual configuration via AWS CLI (documented)
- **Custom Vocabulary** - Deferred to future release
  - AWS API limitations and regional availability issues
- **AWS CLI Dependency** - Required for automatic building

## Roadmap

- [x] JSON schema validation (v1.5.0) ✅
- [x] Conversation logs module (v1.5.0) ✅
- [x] Slot obfuscation (v1.5.0) ✅
- [x] Lambda fulfillment (v1.4.0) ✅
- [x] CloudWatch logging (v1.3.0) ✅
- [x] Automatic building (v1.2.0) ✅
- [x] Bot versioning (v1.1.0) ✅
- [ ] Custom vocabulary (v1.6.0) - Pending AWS API improvements
- [ ] Bot aliases (v1.6.0) - Pending Terraform provider support

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Validate with `./terraform-preflight.sh`
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- 📖 [Documentation](https://registry.terraform.io/modules/infrakraft/lexv2models/aws/latest)
- 🐛 [Issue Tracker](https://github.com/infrakraft/terraform-aws-lexv2models/issues)
- 💬 [Discussions](https://github.com/infrakraft/terraform-aws-lexv2models/discussions)

## Author

Maintained by [Infrakraft](https://github.com/infrakraft)

---

**Latest Version:** 1.5.0 | **Released:** 2024-04-12