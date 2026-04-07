# AWS Lex V2 Terraform Module

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS%20Provider-%3E%3D4.0-FF9900?logo=amazon-aws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/infrakraft/terraform-aws-lexv2models)](https://github.com/infrakraft/terraform-aws-lexv2models/releases)

Terraform module for creating and managing AWS Lex V2 bots with advanced features including slot priorities, bot versioning, multi-locale support, Lambda integration, and conversation logging.

## Features

## Features

- ✅ **Full Lex V2 Bot Management** - Create and configure bots with JSON-based configuration
- ✅ **Automatic Bot Building** - Build bots automatically after deployment (v1.2.0)
- ✅ **Bot Versioning** - Create immutable snapshots for production deployments (v1.1.0)
- ✅ **Slot Priority Configuration** - Set elicitation order for intent slots
- ✅ **Multi-Locale Support** - Configure multiple languages and locales
- ✅ **Lambda Integration** - Connect fulfillment and validation code hooks
- ✅ **IAM Role Management** - Automatic IAM role creation with proper permissions
- ✅ **Polly Integration** - Voice settings with Amazon Polly
- ✅ **CloudWatch Logging Support** - Ready for conversation logging (requires setup)

## Prerequisites

⚠️ **Important**: This module uses a `local-exec` provisioner that requires `jq` to be installed on the machine running Terraform.

**Install jq:**

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# RHEL/CentOS
sudo yum install jq

# Windows (Chocolatey)
choco install jq
```

## Quick Start

```hcl
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.1.0"

  # IAM Role name (must be unique in your AWS account)
  lexv2_bot_role_name = "my-lex-bot-role"

  # Bot configuration
  bot_config = {
    name               = "CustomerServiceBot"
    description        = "Customer service chatbot"
    idle_session_ttl   = 300
    
    data_privacy = {
      child_directed = false
    }

    locales = {
      en_US = {
        locale_id                = "en_US"
        description              = "English (US)"
        nlu_confidence_threshold = 0.4
        
        voice_settings = {
          voice_id = "Joanna"
        }

        intents = {
          Greeting = {
            description = "Greet the user"
            
            sample_utterances = [
              { utterance = "Hello" },
              { utterance = "Hi there" }
            ]
            
            closing_prompt = {
              message    = "Hello! How can I help you today?"
              variations = []
            }
          }
        }
      }
    }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

## Bot Versioning (v1.1.0)

Bot versions create **immutable snapshots** of your bot configuration, essential for:
- **Production deployments** - Deploy stable versions to production
- **Rollback capabilities** - Revert to previous versions if needed
- **Change tracking** - Document what changed in each version
- **Bot aliases** - Versions are required for creating aliases (coming in v1.2.0)

### Creating a Bot Version

```hcl
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.1.0"

  lexv2_bot_role_name = "my-lex-bot-role"
  
  bot_config = {
    name               = "ProductionBot"
    idle_session_ttl   = 300
    data_privacy       = { child_directed = false }
    
    locales = {
      en_US = {
        locale_id                = "en_US"
        nlu_confidence_threshold = 0.4
        # ... intents and slots ...
      }
    }
  }

  # Enable bot versioning
  create_bot_version      = true
  bot_version_description = "v1.0 - Initial production release with booking flow"
}
```

### Version Workflow

1. **Develop** - Make changes in DRAFT version
2. **Test** - Thoroughly test in DRAFT
3. **Version** - Create numbered version (1, 2, 3, etc.)
4. **Deploy** - Use version in production via aliases

### Accessing Version Information

```hcl
output "version_info" {
  value = {
    version_number = module.lex_bot.bot_version      # "1"
    version_arn    = module.lex_bot.bot_version_arn  # Full ARN
  }
}
```

### Advanced: Locale-Specific Versions

Use different source versions for different locales:

```hcl
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.1.0"
  
  # ... bot_config ...
  
  create_bot_version = true
  bot_version_locale_specification = {
    "en_US" = "1"  # Use version 1 for English
    "es_ES" = "2"  # Use version 2 for Spanish
  }
}
```

See the [versioning example](./examples/lex-with-versioning) for a complete working example.

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
  version = "1.2.0"

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

## Usage Examples

### Basic Bot with Lambda Fulfillment

```hcl
# Lambda function for fulfillment
resource "aws_lambda_function" "bot_fulfillment" {
  filename      = "fulfillment.zip"
  function_name = "lex-bot-fulfillment"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.11"
}

module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.1.0"

  lexv2_bot_role_name = "my-lex-bot-role"

  # Lambda integration
  lambda_functions = {
    "BookingFulfillment" = {
      function_name = aws_lambda_function.bot_fulfillment.function_name
      arn           = aws_lambda_function.bot_fulfillment.arn
    }
  }

  bot_config = {
    name             = "BookingBot"
    idle_session_ttl = 300
    data_privacy     = { child_directed = false }

    locales = {
      en_US = {
        locale_id                = "en_US"
        nlu_confidence_threshold = 0.4
        
        intents = {
          BookRoom = {
            description = "Book a room"
            
            # Reference the Lambda function by logical name
            fulfillment_lambda_name = "BookingFulfillment"
            
            sample_utterances = [
              { utterance = "I want to book a room" }
            ]
            
            slots = {
              RoomType = {
                slot_type = "RoomType"
                required  = true
                prompt    = "What type of room would you like?"
              }
            }
          }
        }
      }
    }
  }
}
```

### Bot with CloudWatch Logging

```hcl
resource "aws_cloudwatch_log_group" "lex_logs" {
  name              = "/aws/lex/my-bot"
  retention_in_days = 7
}

module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.1.0"

  lexv2_bot_role_name = "my-lex-bot-role"

  # Enable CloudWatch logging
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.lex_logs.arn

  bot_config = {
    # ... bot configuration ...
  }
}
```

## Examples

Complete working examples are available in the [examples](./examples) directory:

- **[lex-only](./examples/lex-only)** - Basic bot without versioning or auto-building
- **[lex-with-versioning](./examples/lex-with-versioning)** - Bot with version snapshots (v1.1.0)
- **[lex-with-building](./examples/lex-with-building)** - Bot with automatic building (v1.2.0)

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0 |

## Providers

No direct providers used (all resources are in the submodule).

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lexv2models"></a> [lexv2models](#module\_lexv2models) | ./modules/lexv2models | n/a |

## Resources

No direct resources (all resources are in the submodule).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bot_config"></a> [bot\_config](#input\_bot\_config) | Decoded bot configuration object (see examples) | `any` | n/a | yes |
| <a name="input_lexv2_bot_role_name"></a> [lexv2\_bot\_role\_name](#input\_lexv2\_bot\_role\_name) | IAM role name for the Lex bot | `string` | n/a | yes |
| <a name="input_create_bot_version"></a> [create\_bot\_version](#input\_create\_bot\_version) | Whether to create a bot version | `bool` | `false` | no |
| <a name="input_bot_version_description"></a> [bot\_version\_description](#input\_bot\_version\_description) | Description for the bot version | `string` | `""` | no |
| <a name="input_bot_version_locale_specification"></a> [bot\_version\_locale\_specification](#input\_bot\_version\_locale\_specification) | Map of locale-specific source versions | `map(string)` | `{}` | no |
| <a name="input_lambda_functions"></a> [lambda\_functions](#input\_lambda\_functions) | Map of Lambda functions for fulfillment | `map(object)` | `{}` | no |
| <a name="input_lambda_arns"></a> [lambda\_arns](#input\_lambda\_arns) | Map of logical name to Lambda ARN | `map(string)` | `{}` | no |
| <a name="input_lex_bot_alias_id"></a> [lex\_bot\_alias\_id](#input\_lex\_bot\_alias\_id) | Bot alias ID for Lambda permissions | `string` | `"TSTALIASID"` | no |
| <a name="input_polly_arn"></a> [polly\_arn](#input\_polly\_arn) | ARN for Amazon Polly permissions | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#input\_cloudwatch\_log\_group\_arn) | CloudWatch Log Group ARN for logging | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bot_id"></a> [bot\_id](#output\_bot\_id) | The unique identifier of the bot |
| <a name="output_bot_arn"></a> [bot\_arn](#output\_bot\_arn) | The ARN of the bot |
| <a name="output_bot_name"></a> [bot\_name](#output\_bot\_name) | The name of the bot |
| <a name="output_lex_bot_role_arn"></a> [lex\_bot\_role\_arn](#output\_lex\_bot\_role\_arn) | ARN of the IAM role for the bot |
| <a name="output_bot_version"></a> [bot\_version](#output\_bot\_version) | The version number (if created) |
| <a name="output_bot_version_arn"></a> [bot\_version\_arn](#output\_bot\_version\_arn) | The ARN of the bot version (if created) |
| <a name="output_intent_ids"></a> [intent\_ids](#output\_intent\_ids) | Map of intent names to their IDs |
| <a name="output_slot_ids"></a> [slot\_ids](#output\_slot\_ids) | Map of slot names to their IDs |

## Bot Configuration Schema

The `bot_config` variable expects a structured object. See the [examples](./examples) for complete configurations.

### Minimal Configuration

```hcl
bot_config = {
  name               = "MyBot"
  idle_session_ttl   = 300
  data_privacy       = { child_directed = false }
  
  locales = {
    en_US = {
      locale_id                = "en_US"
      nlu_confidence_threshold = 0.4
      
      intents = {
        MyIntent = {
          description = "My intent"
          sample_utterances = [
            { utterance = "Hello" }
          ]
          closing_prompt = {
            message = "Response message"
            variations = []
          }
        }
      }
    }
  }
}
```

## Known Limitations

- **jq Dependency**: The module requires `jq` to be installed for slot priority management
- **AWS CLI Dependency**: Automatic building requires AWS CLI for build triggering
- **CI/CD Compatibility**: Local-exec provisioners may not work in containerized CI/CD environments without additional setup
- **Bot Alias**: Native Terraform resource not yet available (tracked in [GitHub Issue #35780](https://github.com/hashicorp/terraform-provider-aws/issues/35780))

## Roadmap

- [x] Bot versioning support (v1.1.0) ✅
- [x] Automatic bot building (v1.2.0) ✅
- [ ] Bot alias support (v1.3.0) - Pending Terraform provider support
- [ ] Code hooks and Lambda integration enhancements (v1.4.0)
- [ ] Custom vocabulary support (v1.5.0)
- [ ] Conversation logging enhancements (v1.6.0)
- [ ] Replace jq dependency with native Terraform (v2.0.0)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


## Upcoming Features

The following features are planned for future releases but require additional AWS provider support or implementation:

### Planned (Terraform Provider Support Needed)
- **Bot Aliases** - Waiting for `aws_lexv2models_bot_alias` resource
- **Conversation Logging** - Partial support ready, needs testing infrastructure

### Planned (Implementation Ready)
- **Code Hooks** - Enhanced Lambda integration
- **Custom Vocabulary** - Custom word pronunciations
- **Slot Value Elicitation** - Advanced prompting strategies
- **Session Attributes** - Pass context between turns

**Want to contribute?** Check our [Contributing Guidelines](CONTRIBUTING.md) or open an issue to discuss features!

## Support

- **Issues**: [GitHub Issues](https://github.com/infrakraft/terraform-aws-lexv2models/issues)
- **Discussions**: [GitHub Discussions](https://github.com/infrakraft/terraform-aws-lexv2models/discussions)

## License

This module is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Authors

Created and maintained by [Infrakraft](https://github.com/infrakraft).

## Acknowledgments

- AWS Lex V2 Documentation
- Terraform AWS Provider Documentation
- HashiCorp Terraform Best Practices
