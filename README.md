# AWS Lex V2 Terraform Module

Terraform module for creating and managing AWS Lex V2 bots with advanced features including slot priorities, multi-locale support, Lambda integration, and conversation logging.

## Features

- ✅ **Full Lex V2 Bot Management** - Create and configure bots with JSON-based configuration
- ✅ **Slot Priority Configuration** - Set elicitation order for intent slots
- ✅ **Multi-Locale Support** - Configure multiple languages and locales
- ✅ **Lambda Integration** - Connect fulfillment and validation code hooks
- ✅ **IAM Role Management** - Automatic IAM role creation with proper permissions
- ✅ **Polly Integration** - Voice settings with Amazon Polly
- ✅ **CloudWatch Logging** - Conversation logging to CloudWatch

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
```

## Usage

### Basic Example
```hcl
module "lex_bot" {
  source = "your-org/lexv2models/aws"
  version = "1.0.0"

  # IAM Role name (must be unique in your AWS account)
  lexv2_bot_role_name = "my-lex-bot-role"

  # Bot configuration object
  bot_config = {
    name               = "CustomerServiceBot"
    description        = "Bot for customer service"
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

        slot_types = {
          RoomType = {
            description = "Types of rooms"
            slot_type_values = [
              { sample_value = { value = "deluxe" } },
              { sample_value = { value = "standard" } },
              { sample_value = { value = "suite" } }
            ]
          }
        }

        intents = {
          BookRoom = {
            description = "Book a hotel room"
            
            sample_utterances = [
              { utterance = "I want to book a room" },
              { utterance = "Book a {RoomType} room" }
            ]
            
            slots = [
              {
                slot_name    = "RoomType"
                slot_type_id = "RoomType"
                value_elicitation_setting = {
                  slot_constraint = "Required"
                  prompt_specification = {
                    message_groups = [{
                      message = {
                        plain_text_message = { 
                          value = "What type of room would you like?" 
                        }
                      }
                    }]
                    max_retries = 2
                  }
                }
              },
              {
                slot_name    = "CheckInDate"
                slot_type_id = "AMAZON.Date"
                value_elicitation_setting = {
                  slot_constraint = "Required"
                  prompt_specification = {
                    message_groups = [{
                      message = {
                        plain_text_message = { 
                          value = "What is your check-in date?" 
                        }
                      }
                    }]
                    max_retries = 2
                  }
                }
              }
            ]

            # Define slot elicitation order
            slot_priorities = [
              { slot_name = "RoomType", priority = 1 },
              { slot_name = "CheckInDate", priority = 2 }
            ]
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

### Example with Lambda Fulfillment
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
  source = "your-org/lexv2models/aws"
  version = "1.0.0"

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
            
            # ... slots configuration ...
          }
        }
      }
    }
  }
}
```

### Example with CloudWatch Logging
```hcl
resource "aws_cloudwatch_log_group" "lex_logs" {
  name              = "/aws/lex/my-bot"
  retention_in_days = 7
}

module "lex_bot" {
  source = "your-org/lexv2models/aws"
  version = "1.0.0"

  lexv2_bot_role_name = "my-lex-bot-role"

  # Enable CloudWatch logging
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.lex_logs.arn

  bot_config = {
    # ... bot configuration ...
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bot_config | Decoded bot configuration object (see examples) | `any` | n/a | yes |
| lexv2_bot_role_name | IAM role name for the Lex bot | `string` | n/a | yes |
| lambda_functions | Map of Lambda functions for fulfillment | `map(object)` | `{}` | no |
| lambda_arns | Map of logical name to Lambda ARN | `map(string)` | `{}` | no |
| lex_bot_alias_id | Bot alias ID for Lambda permissions | `string` | `"TSTALIASID"` | no |
| polly_arn | ARN for Amazon Polly permissions | `string` | `null` | no |
| cloudwatch_log_group_arn | CloudWatch Log Group ARN for logging | `string` | `null` | no |
| tags | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bot_id | The unique identifier of the bot |
| bot_arn | The ARN of the bot |
| bot_name | The name of the bot |
| lex_bot_role_arn | ARN of the IAM role for the bot |
| intent_ids | Map of intent names to their IDs |
| slot_ids | Map of slot names to their IDs |

## Bot Configuration Schema

The `bot_config` variable expects a structured object with the following schema:
```hcl
{
  name               = string          # Required: Bot name
  description        = string          # Optional: Bot description
  idle_session_ttl   = number          # Required: 60-86400 seconds
  data_privacy       = {               # Required
    child_directed = bool
  }
  bot_type           = string          # Optional: "Bot" or "BotNetwork"
  
  locales = {                          # Required: At least one locale
    locale_key = {
      locale_id                = string  # e.g., "en_US", "es_ES"
      description              = string
      nlu_confidence_threshold = number  # 0.0-1.0
      
      voice_settings = {                 # Optional
        voice_id = string
      }
      
      slot_types = {                     # Optional
        SlotTypeName = {
          description      = string
          slot_type_values = list(object({
            sample_value = { value = string }
          }))
        }
      }
      
      intents = {                        # Required: At least one intent
        IntentName = {
          description             = string
          fulfillment_lambda_name = string  # Optional: from lambda_functions
          
          sample_utterances = list(object({
            utterance = string
          }))
          
          slots = list(object({
            slot_name    = string
            slot_type_id = string
            value_elicitation_setting = object({...})
          }))
          
          slot_priorities = list(object({  # Optional
            slot_name = string
            priority  = number
          }))
        }
      }
    }
  }
}
```

## License

MIT Licensed. See [LICENSE](LICENSE) for details.