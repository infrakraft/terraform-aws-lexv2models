# Terraform AWS Lex V2 Models Module

[![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-623CE4?logo=terraform)](https://registry.terraform.io/modules/infrakraft/lexv2models/aws/latest)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![TFLint](https://img.shields.io/badge/TFLint-Enabled-blue)](https://github.com/terraform-linters/tflint)

A comprehensive Terraform module for creating and managing AWS Lex V2 bots with support for Lambda fulfillment, versioning, automatic building, and CloudWatch logging.

## Features

- ✅ **Full Lex V2 Bot Management** - Create and configure bots with JSON-based configuration
- ✅ **Lambda Fulfillment** - Modular Lambda function creation for bot fulfillment (v1.4.0)
- ✅ **CloudWatch Logging** - Modular log group creation for conversation monitoring (v1.3.0)
- ✅ **Automatic Bot Building** - Build bots automatically after deployment (v1.2.0)
- ✅ **Bot Versioning** - Create immutable snapshots for production deployments (v1.1.0)
- ✅ **Slot Priority Configuration** - Set elicitation order for intent slots
- ✅ **Multi-Locale Support** - Configure multiple languages and locales
- ✅ **IAM Role Management** - Automatic IAM role creation with proper permissions
- ✅ **Polly Integration** - Voice settings with Amazon Polly
- ✅ **TFLint Validated** - Code quality and best practices enforced

## Quick Start

```hcl
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.4.0"

  lexv2_bot_role_name = "my-bot-role"
  
  bot_config = {
    name               = "MyBot"
    idle_session_ttl   = 300
    
    data_privacy = {
      child_directed = false
    }

    locales = {
      en_US = {
        locale_id                = "en_US"
        nlu_confidence_threshold = 0.4
        
        intents = {
          Greeting = {
            description = "Greet the user"
            sample_utterances = [
              { utterance = "Hello" },
              { utterance = "Hi" }
            ]
          }
        }
      }
    }
  }
}
```

## Lambda Fulfillment (v1.4.0)

Connect Lambda functions to your Lex bot for business logic, validation, and fulfillment.

### Modular Approach

```hcl
# Create Lambda functions
module "lambda_fulfillment" {
  source = "infrakraft/lexv2models/aws//modules/lambda-fulfillment"
  version = "1.4.0"
  
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
      
      environment_variables = {
        TABLE_NAME = "orders"
      }
    }
  }
  
  enable_lex_invocation = true
}

# Connect to Lex bot
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.4.0"
  
  bot_config = {
    # ... configuration
    locales = {
      en_US = {
        intents = {
          PlaceOrder = {
            fulfillment_lambda_name = "order_handler"
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

### Features

- **Automatic Lex permissions** - Lambda invoke permissions created automatically
- **Versioning** - Published versions for stable deployments
- **CloudWatch integration** - Automatic logging setup
- **VPC support** - Optional VPC configuration
- **X-Ray tracing** - Built-in distributed tracing
- **Environment variables** - Global and per-function configuration

See the [Lambda fulfillment example](./examples/lex-with-lambda) for complete implementation.

## CloudWatch Logging (v1.3.0)

Monitor and debug your bot conversations with integrated CloudWatch Logs.

### Modular Approach

```hcl
# Create CloudWatch log group
module "cloudwatch_logs" {
  source = "infrakraft/lexv2models/aws//modules/cloudwatch-logs"
  version = "1.4.0"
  
  name              = "/aws/lex/MyBot"
  retention_in_days = 7                    # Dev: 7, Prod: 365
  prevent_destroy   = true                 # Protect production logs
  kms_key_id        = aws_kms_key.logs.arn # Optional encryption
  
  tags = {
    Environment = "production"
  }
}

# Create bot with logging enabled
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.4.0"
  
  bot_config = { ... }
  
  # Enable CloudWatch logging
  enable_cloudwatch_logging = true
  cloudwatch_log_group_arn  = module.cloudwatch_logs.cloudwatch_log_group_arn
}
```

### Features

- **Modular design** - Separate CloudWatch module for flexibility
- **Environment protection** - Prevent accidental deletion in production
- **KMS encryption** - Encrypt logs at rest
- **Configurable retention** - 1 day to 10 years
- **IAM automation** - Automatic permissions configuration

See the [CloudWatch logging example](./examples/lex-with-cloudwatch-logs) for complete implementation.

## Bot Building (v1.2.0)

Automatically build bot locales after deployment, making your bot ready for testing immediately without manual intervention.

### Why Automatic Building?

Without automatic building:
1. Deploy bot with Terraform
2. Go to AWS Console
3. Click "Build" for each locale
4. Wait 1-2 minutes
5. Finally test

With automatic building:
1. Deploy bot with Terraform
2. Bot is ready! ✅

### Enabling Automatic Building

```hcl
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.4.0"

  lexv2_bot_role_name = "my-lex-bot-role"
  
  bot_config = {
    # ... your bot configuration ...
  }

  # Enable automatic building
  auto_build_bot_locales    = true   # Default: true
  wait_for_build_completion = true   # Wait for build to finish
  build_timeout_seconds     = 300    # 5 minutes timeout
}
```

### Configuration Options

**Fast Mode (Development):**
```hcl
auto_build_bot_locales    = true
wait_for_build_completion = false  # Don't wait, faster iterations
```

**Production Mode:**
```hcl
auto_build_bot_locales    = true
wait_for_build_completion = true   # Ensure bot is ready
build_timeout_seconds     = 600    # 10 minutes for complex bots
```

**Manual Building:**
```hcl
auto_build_bot_locales = false  # Build manually in console
```

See the [automatic building example](./examples/lex-with-building) for a complete working example.

## Bot Versioning (v1.1.0)

Create immutable snapshots of your bot configuration for production deployments and rollback capabilities.

```hcl
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.4.0"

  bot_config = { ... }
  
  # Enable versioning
  create_bot_version      = true
  bot_version_description = "v1.0 - Production release"
  
  # Optional: Specify version per locale
  bot_version_locale_specification = {
    en_US = "DRAFT"
    es_ES = "DRAFT"
  }
}
```

See the [versioning example](./examples/lex-with-versioning) for complete implementation.

## Examples

Complete working examples are available in the [examples](./examples) directory:

- **[lex-only](./examples/lex-only)** - Basic bot without versioning or auto-building
- **[lex-with-versioning](./examples/lex-with-versioning)** - Bot with version snapshots (v1.1.0)
- **[lex-with-building](./examples/lex-with-building)** - Bot with automatic building (v1.2.0)
- **[lex-with-cloudwatch-logs](./examples/lex-with-cloudwatch-logs)** - Bot with conversation logging (v1.3.0)
- **[lex-with-lambda](./examples/lex-with-lambda)** - Bot with Lambda fulfillment (v1.4.0)
- **[lex-with-lambda-and-cloudwatch-logs](./examples/lex-with-lambda-and-cloudwatch-logs)** - Complete production setup (v1.4.0)

## Complete Production Example

```hcl
# CloudWatch logs for Lex conversations
module "lex_logs" {
  source = "infrakraft/lexv2models/aws//modules/cloudwatch-logs"
  version = "1.4.0"
  
  name              = "/aws/lex/ProductionBot"
  retention_in_days = 365
  prevent_destroy   = true
  kms_key_id        = aws_kms_key.logs.arn
}

# CloudWatch logs for Lambda functions
module "lambda_logs" {
  source   = "infrakraft/lexv2models/aws//modules/cloudwatch-logs"
  version  = "1.4.0"
  for_each = { order_handler = true, inventory_check = true }
  
  name              = "/aws/lambda/${each.key}"
  retention_in_days = 365
  prevent_destroy   = true
}

# Lambda functions for fulfillment
module "lambda_fulfillment" {
  source = "infrakraft/lexv2models/aws//modules/lambda-fulfillment"
  version = "1.4.0"
  
  lambda_functions = {
    order_handler = {
      namespace    = "production-bot"
      description  = "Handles order processing"
      handler      = "index.handler"
      runtime      = "python3.11"
      timeout      = 30
      memory_size  = 512
      s3_bucket    = "lambda-artifacts"
      s3_key       = "order_handler.zip"
    }
    inventory_check = {
      namespace    = "production-bot"
      description  = "Checks inventory availability"
      handler      = "index.handler"
      runtime      = "python3.11"
      timeout      = 10
      memory_size  = 256
      s3_bucket    = "lambda-artifacts"
      s3_key       = "inventory_check.zip"
    }
  }
  
  enable_lex_invocation = true
  
  global_environment_variables = {
    ENVIRONMENT = "production"
    LOG_LEVEL   = "INFO"
  }
}

# Lex bot with all features
module "lex_bot" {
  source = "infrakraft/lexv2models/aws"
  version = "1.4.0"
  
  bot_config          = local.bot_config
  lexv2_bot_role_name = "production-bot-role"
  
  # Lambda integration
  lambda_arns = module.lambda_fulfillment.lambda_qualified_arns
  
  # CloudWatch logging
  enable_cloudwatch_logging = true
  cloudwatch_log_group_arn  = module.lex_logs.cloudwatch_log_group_arn
  
  # Bot building
  auto_build_bot_locales    = true
  wait_for_build_completion = true
  build_timeout_seconds     = 600
  
  # Bot versioning
  create_bot_version      = true
  bot_version_description = "v1.0 - Production release"
  
  tags = {
    Environment = "production"
  }
  
  depends_on = [
    module.lambda_fulfillment,
    module.lex_logs
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |
| null | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0 |
| null | >= 3.0 |

## Modules

| Name | Source | Description |
|------|--------|-------------|
| cloudwatch-logs | ./modules/cloudwatch-logs | CloudWatch log group creation (optional) |
| lambda-fulfillment | ./modules/lambda-fulfillment | Lambda function creation for Lex (optional) |
| lexv2models | ./modules/lexv2models | Core Lex V2 bot resources |

## Resources

Core resources created by this module:
- `aws_lexv2models_bot`
- `aws_lexv2models_bot_locale`
- `aws_lexv2models_intent`
- `aws_lexv2models_slot`
- `aws_lexv2models_slot_type`
- `aws_lexv2models_bot_version` (optional, v1.1.0)
- `aws_cloudwatch_log_group` (optional, v1.3.0)
- `aws_lambda_function` (optional, v1.4.0)
- `aws_lambda_permission` (optional, v1.4.0)
- `aws_iam_role`
- `aws_iam_policy`
- `null_resource` (for slot priorities and bot building)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bot_config | Complete bot configuration object | `any` | n/a | yes |
| lexv2_bot_role_name | Name for the IAM role used by Lex | `string` | n/a | yes |
| lambda_arns | Map of Lambda function names to qualified ARNs | `map(string)` | `{}` | no |
| auto_build_bot_locales | Automatically build bot locales after deployment | `bool` | `true` | no |
| wait_for_build_completion | Wait for bot build to complete | `bool` | `false` | no |
| build_timeout_seconds | Maximum time to wait for build completion | `number` | `300` | no |
| create_bot_version | Create a bot version | `bool` | `false` | no |
| bot_version_description | Description for the bot version | `string` | `""` | no |
| enable_cloudwatch_logging | Enable CloudWatch logging IAM permissions | `bool` | `false` | no |
| cloudwatch_log_group_arn | ARN of CloudWatch log group for conversation logs | `string` | `""` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bot_id | The unique identifier of the bot |
| bot_arn | The ARN of the bot |
| bot_name | The name of the bot |
| bot_role_arn | The ARN of the IAM role used by the bot |
| bot_version | The bot version number (if created) |
| bot_build_triggered | Whether bot build was triggered |
| intent_ids | Map of intent names to their IDs |
| slot_ids | Map of slot names to their IDs |

## Code Quality

This module is validated with:
- ✅ **terraform fmt** - Code formatting
- ✅ **terraform validate** - Configuration validation
- ✅ **TFLint** - Best practices and AWS-specific rules
- ✅ **Automated testing** - GitHub Actions CI/CD

Run locally:
```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Run TFLint
tflint --init
tflint
```

## Known Limitations

- **jq Dependency**: The module requires `jq` to be installed for slot priority management
- **AWS CLI Dependency**: Automatic building requires AWS CLI for build triggering
- **CI/CD Compatibility**: Local-exec provisioners may not work in containerized CI/CD environments without additional setup
- **Bot Alias**: Native Terraform resource not yet available (tracked in [GitHub Issue #35780](https://github.com/hashicorp/terraform-provider-aws/issues/35780))

## Roadmap

- [x] Bot versioning support (v1.1.0) ✅
- [x] Automatic bot building (v1.2.0) ✅
- [x] CloudWatch logging module (v1.3.0) ✅
- [x] Lambda fulfillment module (v1.4.0) ✅
- [ ] Custom vocabulary support (v1.5.0)
- [ ] Bot alias support (v1.6.0) - Pending Terraform provider
- [ ] Replace jq dependency with native Terraform (v2.0.0)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This module is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Maintained by [Infrakraft](https://github.com/infrakraft)

## Support

- 📖 [Documentation](https://registry.terraform.io/modules/infrakraft/lexv2models/aws/latest)
- 🐛 [Issue Tracker](https://github.com/infrakraft/terraform-aws-lexv2models/issues)
- 💬 [Discussions](https://github.com/infrakraft/terraform-aws-lexv2models/discussions)