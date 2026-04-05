# Lex Only Example

This example demonstrates creating a basic AWS Lex V2 bot **without versioning**. This is the simplest way to get started with the module.

## What This Example Shows

- Creating a Lex V2 bot with minimal configuration
- Defining a single locale (English US)
- Creating a simple greeting intent
- Working with the bot in DRAFT mode
- Bot development and testing workflow

## When to Use This Example

Use this example when you want to:
- Quickly prototype a bot
- Develop and test bot configurations
- Learn the basic module structure
- Work exclusively in DRAFT mode

For production deployments, see the [lex-with-versioning](../lex-with-versioning) example.

## What Gets Created

This example creates:
- ✅ AWS Lex V2 Bot (`GreetingBot`)
- ✅ IAM Role for the bot
- ✅ English (en_US) locale
- ✅ Greeting intent with sample utterances
- ✅ Voice settings (Joanna voice)

**Note**: No bot version is created. The bot remains in DRAFT mode.

## Architecture

```
┌─────────────────────────────────────┐
│   AWS Lex V2 Bot (DRAFT)           │
│                                     │
│   ┌─────────────────────────────┐  │
│   │  Locale: en_US              │  │
│   │                             │  │
│   │  ┌───────────────────────┐  │  │
│   │  │ Intent: Greeting      │  │  │
│   │  │                       │  │  │
│   │  │ • "Hello"            │  │  │
│   │  │ • "Hi"               │  │  │
│   │  │ • "Good morning"     │  │  │
│   │  └───────────────────────┘  │  │
│   └─────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **jq** command-line tool installed (for slot priorities)
4. **AWS CLI** configured with credentials

## Usage

### Step 1: Navigate to Example Directory

```bash
cd examples/lex-only
```

### Step 2: Initialize Terraform

```bash
terraform init
```

This downloads the required providers and initializes the working directory.

### Step 3: Review the Plan

```bash
terraform plan
```

Review what resources will be created.

### Step 4: Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### Step 5: Verify in AWS Console

1. Go to [Amazon Lex V2 Console](https://console.aws.amazon.com/lexv2/)
2. Find your bot: **GreetingBot**
3. You'll see:
   - Bot status: **Not Built**
   - Version: **DRAFT**
   - Locale: **en_US**

### Step 6: Build the Bot

The bot needs to be built before testing:

```bash
# Using AWS CLI
aws lexv2-models build-bot-locale \
  --bot-id $(terraform output -raw bot_id) \
  --bot-version DRAFT \
  --locale-id en_US \
  --region eu-west-1
```

Or build via the AWS Console:
1. Open the bot
2. Click **Build**
3. Wait for build to complete (~1-2 minutes)

### Step 7: Test the Bot

Test in the AWS Console:
1. Click **Test** button
2. Type: "Hello"
3. Bot responds: "Hello! Welcome. How can I assist you today?"

### Step 8: Make Changes (Development Workflow)

To modify the bot:

1. Edit `main.tf` (e.g., add new utterances)
2. Run `terraform apply`
3. Rebuild the bot in AWS Console
4. Test your changes

## Outputs

After applying, you'll see these outputs:

```
bot_id         = "ABCD1234XY"
bot_arn        = "arn:aws:lex:eu-west-1:123456789012:bot/ABCD1234XY"
bot_name       = "GreetingBot"
bot_role_arn   = "arn:aws:iam::123456789012:role/lex-greeting-bot-role"
```

## Development Workflow

When developing with this example:

```
1. Edit bot_config in main.tf
   ↓
2. terraform apply
   ↓
3. Build bot in AWS Console
   ↓
4. Test changes
   ↓
5. Repeat
```

## Configuration Highlights

### Bot Configuration

```hcl
bot_config = {
  name               = "GreetingBot"
  description        = "Simple greeting bot without versioning"
  idle_session_ttl   = 300
  
  data_privacy = {
    child_directed = false
  }
  
  # ... locales and intents ...
}
```

### Intent Configuration

```hcl
intents = {
  Greeting = {
    description = "Greet the user"
    
    sample_utterances = [
      { utterance = "Hello" },
      { utterance = "Hi" },
      { utterance = "Good morning" },
      { utterance = "Hey" }
    ]
    
    closing_prompt = {
      message    = "Hello! Welcome. How can I assist you today?"
      variations = []
    }
  }
}
```

## Customization

### Adding More Intents

```hcl
intents = {
  Greeting = { ... },
  
  # Add new intent
  Help = {
    description = "Provide help"
    sample_utterances = [
      { utterance = "Help" },
      { utterance = "I need help" }
    ]
    closing_prompt = {
      message    = "I can help you with greetings!"
      variations = []
    }
  }
}
```

### Adding Slots

```hcl
intents = {
  BookAppointment = {
    description = "Book an appointment"
    
    sample_utterances = [
      { utterance = "Book appointment for {Date}" }
    ]
    
    slots = {
      Date = {
        slot_type = "AMAZON.Date"
        required  = true
        prompt    = "What date would you like?"
      }
    }
  }
}
```

## Clean Up

To remove all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

**Note**: If you built the bot in AWS Console, Terraform will still be able to destroy it.

## Differences from Versioning Example

| Feature | lex-only | lex-with-versioning |
|---------|----------|---------------------|
| Bot Version | DRAFT only | DRAFT + Version 1 |
| Production Ready | ❌ No | ✅ Yes |
| Immutable Snapshot | ❌ No | ✅ Yes |
| Rollback Capability | ❌ No | ✅ Yes |
| Use Case | Development/Testing | Production Deployment |

## Next Steps

After mastering this example:

1. **Add complexity**: Add more intents, slots, and slot types
2. **Add Lambda**: Integrate Lambda functions for fulfillment
3. **Use versioning**: See [lex-with-versioning](../lex-with-versioning) example
4. **Production deployment**: Create immutable versions for production

## Troubleshooting

### Error: "jq: command not found"

Install jq:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### Error: "Bot locale not ready for build"

Wait a few seconds after `terraform apply` before building the bot.

### Bot doesn't respond

Ensure you:
1. Built the bot after applying Terraform
2. Test in the correct bot version (DRAFT)

## Additional Resources

- [Module Documentation](../../README.md)
- [AWS Lex V2 Documentation](https://docs.aws.amazon.com/lexv2/)
- [Terraform AWS Provider - Lex V2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lexv2models_bot)

## Cost

This example incurs minimal AWS costs:
- Lex V2 bot: Free tier includes 10,000 text requests/month
- IAM roles: Free
- CloudWatch Logs: Minimal (if enabled)

Estimated monthly cost (after free tier): ~$0.00 for testing
