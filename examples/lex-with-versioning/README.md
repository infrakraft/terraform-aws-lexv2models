# Lex Bot with Versioning Example

This example demonstrates creating an AWS Lex V2 bot **with versioning enabled**. This is the recommended approach for production deployments.

## What This Example Shows

- Creating a Lex V2 bot with version snapshots
- Enabling bot versioning with `create_bot_version = true`
- Adding descriptive version messages
- Accessing version information via outputs
- Production deployment workflow

## What is Bot Versioning?

Bot versions are **immutable snapshots** of your bot configuration. They enable:

- **Production deployments** - Deploy stable versions to production
- **Rollback capability** - Revert to previous versions if issues arise  
- **Change tracking** - Document what changed in each version
- **Alias support** - Versions are required for creating bot aliases (coming in v1.2.0)

## When to Use This Example

Use this example when you want to:
- Deploy bots to production
- Create stable, immutable configurations
- Enable version rollback capabilities
- Prepare for bot aliases
- Follow production best practices

For development/testing, see the [lex-only](../lex-only) example.

## What Gets Created

This example creates:
- ✅ AWS Lex V2 Bot (`VersionedGreetingBot`)
- ✅ IAM Role for the bot
- ✅ English (en_US) locale
- ✅ Greeting intent with sample utterances
- ✅ Voice settings (Joanna voice)
- ✅ **Bot Version 1** (immutable snapshot)

## Architecture

```
┌─────────────────────────────────────────┐
│   AWS Lex V2 Bot                       │
│                                         │
│   ┌─────────────────────────────────┐  │
│   │  DRAFT (editable)               │  │
│   │  • Active development           │  │
│   └─────────────────────────────────┘  │
│                ↓                        │
│   ┌─────────────────────────────────┐  │
│   │  Version 1 (immutable)          │  │
│   │  • Production snapshot          │  │
│   │  • Cannot be modified           │  │
│   │  • Ready for aliases            │  │
│   └─────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **jq** command-line tool installed (for slot priorities)
4. **AWS CLI** configured with credentials

## Usage

### Step 1: Navigate to Example Directory

```bash
cd examples/lex-with-versioning
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Review the Plan

```bash
terraform plan
```

You'll see resources for:
- Bot creation
- Locale creation
- Intent creation
- **Bot version creation** ← New in v1.1.0

### Step 4: Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted.

**Note**: Creating a bot version takes slightly longer than DRAFT-only creation (~30-60 seconds extra).

### Step 5: Review Outputs

After apply completes, you'll see:

```
Outputs:

bot_id = "HM2ONOKTBX"
bot_name = "VersionedGreetingBot"
bot_role_arn = "arn:aws:iam::123456789012:role/versioned-greeting-bot-role"

# Version information
bot_version = "1"
bot_version_arn = "arn:aws:lex:eu-west-1:123456789012:bot/HM2ONOKTBX:1"
bot_version_id = "HM2ONOKTBX,1"
```

### Step 6: Verify in AWS Console

1. Go to [Amazon Lex V2 Console](https://console.aws.amazon.com/lexv2/)
2. Find your bot: **VersionedGreetingBot**
3. You'll see:
   - **DRAFT** version (editable)
   - **Version 1** (immutable, ready for production)

### Step 7: Build and Test

Build the DRAFT version:

```bash
aws lexv2-models build-bot-locale \
  --bot-id $(terraform output -raw bot_id) \
  --bot-version DRAFT \
  --locale-id en_US \
  --region eu-west-1
```

Test in AWS Console:
1. Select **Version 1** in the dropdown
2. Click **Test**
3. Type: "Hello"
4. Bot responds: "Hello! How can I help you today?"

## Version Workflow

### How Versioning Works

```
┌────────────┐
│   DRAFT    │  ← Make changes here
│ (editable) │
└─────┬──────┘
      │
      │ terraform apply with create_bot_version = true
      │
      ▼
┌────────────┐
│ Version 1  │  ← Immutable snapshot
│ (locked)   │
└────────────┘
```

### Creating Subsequent Versions

To create version 2:

1. Modify your `bot_config` in `main.tf`:
   ```hcl
   intents = {
     Greeting = { ... },
     
     # Add new intent
     Help = {
       description = "Provide help"
       # ...
     }
   }
   ```

2. Update version description:
   ```hcl
   bot_version_description = "v1.1.0 - Added help intent"
   ```

3. Apply:
   ```bash
   terraform apply
   ```

4. A new **Version 2** is created!

### Version Management

```bash
# View all versions
aws lexv2-models list-bot-versions \
  --bot-id $(terraform output -raw bot_id) \
  --region eu-west-1

# Describe specific version
aws lexv2-models describe-bot-version \
  --bot-id $(terraform output -raw bot_id) \
  --bot-version 1 \
  --region eu-west-1
```

## Configuration Highlights

### Enabling Versioning

The key difference from `lex-only` example:

```hcl
module "lex_bot" {
  source = "../.."

  lexv2_bot_role_name = "versioned-greeting-bot-role"
  bot_config = { ... }

  # Enable versioning
  create_bot_version      = true
  bot_version_description = "v1.0.0 - Initial release with greeting intent"

  tags = {
    Environment = "production"  # ← Production-ready
    Version     = "1.0.0"
  }
}
```

### Version Outputs

```hcl
output "bot_version" {
  description = "The version number (e.g., '1', '2')"
  value       = module.lex_bot.bot_version
}

output "bot_version_arn" {
  description = "Full ARN for the version"
  value       = module.lex_bot.bot_version_arn
}
```

## Advanced Usage

### Locale-Specific Versions

Create versions from different sources per locale:

```hcl
module "lex_bot" {
  source = "../.."

  lexv2_bot_role_name = "multi-locale-bot-role"
  
  bot_config = {
    locales = {
      en_US = { ... }
      es_ES = { ... }
    }
  }

  create_bot_version = true
  
  # Use different versions for different locales
  bot_version_locale_specification = {
    "en_US" = "1"      # English uses version 1
    "es_ES" = "DRAFT"  # Spanish uses current DRAFT
  }
}
```

### Conditional Versioning

Only create versions in production:

```hcl
variable "environment" {
  type = string
}

module "lex_bot" {
  source = "../.."

  # ... configuration ...

  # Only version in production
  create_bot_version = var.environment == "production"
  bot_version_description = var.environment == "production" ? "Production release" : ""
}
```

## Production Deployment Pattern

Recommended workflow for production:

```hcl
# main.tf
module "dev_bot" {
  source = "infrakraft/lexv2models/aws"
  version = "1.1.0"

  lexv2_bot_role_name = "dev-bot-role"
  bot_config = local.bot_config
  
  # No versioning in dev
  create_bot_version = false
  
  tags = { Environment = "dev" }
}

module "prod_bot" {
  source = "infrakraft/lexv2models/aws"
  version = "1.1.0"

  lexv2_bot_role_name = "prod-bot-role"
  bot_config = local.bot_config
  
  # Enable versioning in prod
  create_bot_version      = true
  bot_version_description = "Production release ${var.release_version}"
  
  tags = { Environment = "prod" }
}
```

## Comparison with lex-only Example

| Feature | lex-only | lex-with-versioning |
|---------|----------|---------------------|
| Bot Version Created | ❌ No | ✅ Yes |
| Immutable Snapshot | ❌ No | ✅ Yes |
| Production Ready | ❌ No | ✅ Yes |
| Rollback Capability | ❌ No | ✅ Yes |
| Change Tracking | ❌ No | ✅ Yes |
| Alias Support | ❌ No | ✅ Yes (future) |
| Use Case | Development | Production |

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

**Note**: Bot versions are automatically deleted when the bot is destroyed.

## Best Practices

### ✅ DO:
- Create versions for production releases
- Document changes in version descriptions
- Use semantic versioning in descriptions (v1.0.0, v1.1.0)
- Test thoroughly in DRAFT before versioning
- Tag resources with version information

### ❌ DON'T:
- Create versions for every small change (use DRAFT for iteration)
- Delete versions that might be in use
- Expect to modify versions (they're immutable)
- Skip version descriptions (always document changes)

## Troubleshooting

### Error: "Version already exists"

**Cause**: Trying to create a version that already exists.

**Solution**: Versions are created incrementally (1, 2, 3...). Terraform manages this automatically. If you see this error, the version may have been created outside Terraform.

### Error: "Cannot delete bot - versions exist"

**Cause**: Bot has numbered versions.

**Solution**: `terraform destroy` handles this automatically by deleting versions first, then the bot.

### Version not showing in console

**Cause**: Console cache or API delay.

**Solution**: Refresh the console or wait 1-2 minutes.

## Version Information

To get version details:

```bash
# List all versions
aws lexv2-models list-bot-versions \
  --bot-id $(terraform output -raw bot_id) \
  --region eu-west-1 \
  --query 'botVersionSummaries[*].[botVersion,creationDateTime,description]' \
  --output table

# Get specific version ARN
terraform output -raw bot_version_arn
```

## Next Steps

After mastering this example:

1. **Create multiple versions**: Modify bot, update description, apply
2. **Add bot aliases**: Coming in v1.2.0
3. **Implement CI/CD**: Automate version creation in deployment pipelines
4. **Monitor versions**: Track which versions are deployed where

## Additional Resources

- [Module Documentation](../../README.md)
- [AWS Lex V2 Versioning Guide](https://docs.aws.amazon.com/lexv2/latest/dg/versioning-aliases.html)
- [Terraform AWS Provider - Bot Version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lexv2models_bot_version)
- [Bot Alias Support (v1.2.0)](../../README.md#roadmap) - Coming soon!

## Cost

This example incurs minimal additional cost compared to `lex-only`:
- Bot versions: Free (same as DRAFT)
- Lex V2 requests: Free tier includes 10,000 text requests/month
- IAM roles: Free

Estimated monthly cost (after free tier): ~$0.00 for testing

## Support

Having issues? Check:
- [GitHub Issues](https://github.com/infrakraft/terraform-aws-lexv2models/issues)
- [Module README](../../README.md)
- [AWS Lex V2 Documentation](https://docs.aws.amazon.com/lexv2/)
