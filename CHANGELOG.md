# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Custom vocabulary support (deferred due to AWS API limitations)
- Bot alias support (pending Terraform AWS provider)

---

## [1.5.0] - 2024-04-16

### Added

#### JSON Schema Validation
- **NEW**: JSON schema validation for `bot_config.json` files
- Schema file: `schema/bot_config_schema.json` - Complete validation rules
- Validation script: `validate_schema.sh` - Shell-based JSON schema validator using `jq`
- Validation tool: Uses `ajv-cli` (Node.js) or Python `jsonschema` for validation
- CI/CD integration: Schema validation integrated into `terraform-preflight.sh`
- GitHub Actions: Automated schema validation on every PR and push
- **Developer Experience**: Catch configuration errors before deployment
- **Production Safety**: Ensure bot configurations meet AWS API requirements
- **Documentation**: Complete schema reference and validation guide
- **Multi-tool Support**: Works with ajv-cli (Node.js), jsonschema (Python), or jq fallback

#### Conversation Logs Module
- **NEW MODULE**: `modules/conversation-logs` for CloudWatch and S3 conversation logging
- CloudWatch Logs integration for text conversation logs
  - Configurable retention periods (1-3653 days)
  - Optional KMS encryption
  - Auto-configured IAM roles and permissions
- S3 integration for audio conversation logs
  - Server-side encryption (AES256 or KMS)
  - Optional versioning
  - Lifecycle policies for automatic expiration
  - Auto-configured IAM roles and permissions
- Comprehensive logging IAM role with least-privilege permissions
- Support for custom log group names and S3 bucket names
- Detailed cost estimation and best practices documentation

#### Enhanced Slot Validation
- **ENHANCED**: Slot obfuscation support for PII protection
  - `DefaultObfuscation` - Masks sensitive data in logs and conversation history
  - `None` - No obfuscation for non-sensitive data
- Obfuscation configuration via `bot_config.json`
- Comprehensive obfuscation documentation with compliance guidelines (PCI DSS, HIPAA, GDPR, SOC 2)
- Best practices for PII handling in chatbots
- Updated `aws_lexv2models_slot` resource with `obfuscation_setting` block

#### Examples
- **NEW**: `examples/lex-production-ready` - Complete production deployment example
  - Bot versioning for deployment control
  - Conversation logs (CloudWatch + S3)
  - Lambda fulfillment with DLQ
  - Advanced slot obfuscation (PII protection)
  - Multi-locale support (en_US, en_GB)
  - Environment-specific configurations (dev, staging, prod)
  - Cost estimation by environment
  - Complete monitoring and troubleshooting guide
  - Python Lambda handlers included

#### Validation & Testing
- Automated schema validation in CI/CD pipelines
- Pre-commit validation support
- Python-based validator (no Node.js dependency required)
- Clear error messages for schema violations
- Integration with existing terraform-preflight.sh

#### Documentation
- Conversation logs module README with setup instructions
- Slot obfuscation guide with compliance considerations
- JSON schema reference documentation
- Production deployment best practices
- Manual alias configuration instructions (workaround for Terraform limitation)
- Cost optimization strategies
- Complete validation workflow documentation

### Changed
- Enhanced `modules/lexv2models/main.tf`:
  - Added slot obfuscation support with dynamic `obfuscation_setting` block
  - Fixed multi-locale support with `locale_id` consistency
  - Fixed `for_each` type consistency with `tomap({})`
  - Updated locals to include both `locale` and `locale_id` for backward compatibility
- Updated `modules/lexv2models/README.md` with advanced slot features
- Improved production example documentation
- Enhanced `terraform-preflight.sh` with schema validation step
- Updated all example `bot_config.json` files to match schema
- Standardized JSON structure across all examples

### Fixed
- **CRITICAL**: Multi-locale bot configuration now works correctly
  - Fixed `locale` vs `locale_id` inconsistency in local variables
  - Fixed type mismatch in `null_resource.build_bot_locales` for_each
  - Added `tomap({})` for conditional type consistency
- **Schema Validation**: JSON validation catches errors early
- **Obfuscation**: Proper PII masking in CloudWatch and conversation logs

### Notes
- **Bot Aliases**: Not yet supported by Terraform AWS provider
  - Conversation logging requires manual alias configuration via AWS CLI or Console
  - Detailed workaround instructions provided in module documentation
- **Custom Vocabulary**: Deferred to future release due to AWS API limitations
  - Requires manual console initialization per bot locale
  - Batch API not reliably available in all regions
  - ResourceNotFoundException when attempting programmatic creation

### Migration Guide

#### Enabling JSON Schema Validation

1. **Install Python dependencies:**

```bash
pip3 install jsonschema
```

2. **Validate your bot configuration:**

```bash
# Validate single file
./validate_schema.py examples/my-bot/bot_config.json schema/bot_config_schema.json

# Validate all examples
./terraform-preflight.sh
```

3. **Fix any validation errors** before deploying

#### Enabling Conversation Logs

1. **Add conversation-logs module to your configuration:**

```hcl
module "conversation_logs" {
  source = "infrakraft/lexv2models/aws//modules/conversation-logs"
  version = "1.5.0"
  
  bot_id             = module.lex_bot.bot_id
  enable_text_logs   = true
  log_retention_days = 30
  enable_audio_logs  = false  # Set to true if needed
  
  tags = {
    Environment = "production"
  }
}
```

2. **Create bot alias and configure logging (manual step):**

```bash
# Create alias
aws lexv2-models create-bot-alias \
  --bot-id YOUR_BOT_ID \
  --bot-alias-name production \
  --bot-version 1

# Configure logging
aws lexv2-models update-bot-alias \
  --bot-id YOUR_BOT_ID \
  --bot-alias-id ALIAS_ID \
  --conversation-log-settings \
    textLogSettings=[{destination={cloudWatchLogs={cloudWatchLogGroupArn=LOG_GROUP_ARN,logPrefix=lex/}},enabled=true}]
```

#### Adding Slot Obfuscation

Update your `bot_config.json`:

```json
{
  "locales": {
    "en_US": {
      "intents": {
        "MyIntent": {
          "slots": {
            "Email": {
              "description": "Customer email",
              "slot_type": "AMAZON.EmailAddress",
              "required": true,
              "prompt": "What is your email?",
              "obfuscation": "DefaultObfuscation"
            },
            "OrderNumber": {
              "description": "Order number",
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

#### Multi-Locale Configurations

If you're using multiple locales, ensure your configuration includes all required fields:

```json
{
  "name": "my-bot",
  "type": "Bot",
  "idle_session_ttl": 300,
  "child_directed": false,
  "locales": {
    "en_US": { ... },
    "en_GB": { ... }
  }
}
```

### Breaking Changes

None. This release is fully backwards compatible.

- JSON schema validation is optional (recommended but not required)
- Conversation logs module is opt-in
- Slot obfuscation defaults to "None" if not specified
- Existing bot configurations continue to work

### Cost Impact

**New Costs (if conversation logs enabled):**
- CloudWatch Logs: ~$0.50/GB ingested + $0.03/GB/month storage
- S3 Audio Logs: ~$0.023/GB/month

**Typical Monthly Costs:**
- Low volume (1,000 conversations): ~$2-5
- Medium volume (10,000 conversations): ~$10-25
- High volume (100,000 conversations): ~$50-150

See `examples/lex-production-ready/README.md` for detailed cost breakdown.

### Schema Features

The JSON schema validates:
- ✅ Required fields (name, type, idle_session_ttl, child_directed, locales)
- ✅ Field types and formats
- ✅ Value ranges (e.g., idle_session_ttl: 60-86400)
- ✅ Enum values (e.g., voice engine: standard/neural)
- ✅ Locale IDs (en_US, en_GB, etc.)
- ✅ Intent and slot configurations
- ✅ Obfuscation settings
- ✅ Voice settings
- ✅ Slot types and values

### Compliance Benefits

Slot obfuscation helps with:
- ✅ **PCI DSS** - Credit card data protection
- ✅ **HIPAA** - Health information privacy
- ✅ **GDPR** - Personal data protection
- ✅ **SOC 2** - Information security
- ✅ **CCPA** - California consumer privacy

**Note:** Obfuscation alone does not guarantee compliance. Implement additional controls as needed.

---

## [1.4.0] - 2024-04-11

### Added
- **Lambda Fulfillment Module**: Complete Lambda function management for Lex bot fulfillment
  - New module: `modules/lambda-fulfillment/` - Standalone Lambda creation
  - Automatic Lex invoke permissions via `aws_lambda_permission`
  - **Configurable X-Ray tracing** (default: disabled to save costs)
  - **Configurable Lambda versioning** (default: enabled for Lex)
  - **Dead Letter Queue support** (optional)
  - **Ephemeral storage configuration** (optional, 512 MB - 10 GB)
  - **EFS file system support** (optional)
  - **Container image support** (optional)
  - VPC support for private resource access
  - Example: `examples/lex-with-lambda/` - Basic Lambda integration
  - Example: `examples/lex-with-lambda-and-cloudwatch-logs/` - Complete production setup
- **TFLint Integration**:
  - Added `.tflint.hcl` configuration file
  - AWS ruleset plugin (v0.47.0)
  - GitHub Actions workflow for automated linting
- **Documentation**:
  - Comprehensive Lambda fulfillment module README
  - Complete example READMEs with architecture diagrams
  - Cost analysis for Lambda + Lex + CloudWatch
  - Monitoring and troubleshooting guides

### Changed
- **BREAKING**: X-Ray tracing now disabled by default (was always enabled)
  - Reduces costs by ~$5-10/month
  - Enable via `enable_xray_tracing = true` when needed

---

## [1.3.0] - 2024-04-10

### Added
- **CloudWatch Logs Module**: Separate module for creating and managing CloudWatch log groups
  - New module: `modules/cloudwatch-logs/` - Standalone log group creation
  - Configurable retention (1-3653 days, default: 365)
  - Optional KMS encryption
  - Lifecycle protection for production logs
  - Example: `examples/lex-with-cloudwatch-logs/` - Complete logging implementation

---

## [1.2.0] - 2024-04-08

### Added
- **Automatic Bot Building**: Build bot locales automatically after deployment
  - New variable: `auto_build_bot_locales` (bool, default: true)
  - New variable: `wait_for_build_completion` (bool, default: false)
  - New variable: `build_timeout_seconds` (number, default: 300)
  - Example: `examples/lex-with-building/` - Complete working example

---

## [1.1.0] - 2024-04-05

### Added
- **Bot Versioning Support**: Create immutable snapshots of bot configurations
  - New variable: `create_bot_version` (bool, default: false)
  - New variable: `bot_version_description` (string, default: "")
  - New variable: `bot_version_locale_specification` (map, default: {})
  - Example: `examples/lex-with-versioning/` - Complete working example

---

## [1.0.0] - 2024-04-02

### Added
- **Initial Release**: Complete AWS Lex V2 bot management module
- Bot creation and configuration
- Multi-locale support
- Intent and slot management
- IAM role management
- Example: `examples/lex-only/` - Basic bot

---

## Version Comparison

| Version | Schema Validation | Conversation Logs | Slot Obfuscation | Lambda | CloudWatch | Building | Versioning |
|---------|------------------|-------------------|------------------|--------|------------|----------|------------|
| 1.5.0   | ✅ Yes           | ✅ Yes            | ✅ Yes           | ✅ Yes | ✅ Yes     | ✅ Yes   | ✅ Yes     |
| 1.4.0   | ❌ No            | ❌ No             | ❌ No            | ✅ Yes | ✅ Yes     | ✅ Yes   | ✅ Yes     |
| 1.3.0   | ❌ No            | ❌ No             | ❌ No            | ❌ No  | ✅ Yes     | ✅ Yes   | ✅ Yes     |
| 1.2.0   | ❌ No            | ❌ No             | ❌ No            | ❌ No  | ⚠️ Partial | ✅ Yes   | ✅ Yes     |
| 1.1.0   | ❌ No            | ❌ No             | ❌ No            | ❌ No  | ❌ No      | ❌ No    | ✅ Yes     |
| 1.0.0   | ❌ No            | ❌ No             | ❌ No            | ❌ No  | ❌ No      | ❌ No    | ❌ No      |

---

## Links

- **Repository**: [github.com/infrakraft/terraform-aws-lexv2models](https://github.com/infrakraft/terraform-aws-lexv2models)
- **Registry**: [registry.terraform.io/modules/infrakraft/lexv2models/aws](https://registry.terraform.io/modules/infrakraft/lexv2models/aws)
- **Issues**: [github.com/infrakraft/terraform-aws-lexv2models/issues](https://github.com/infrakraft/terraform-aws-lexv2models/issues)

[Unreleased]: https://github.com/infrakraft/terraform-aws-lexv2models/compare/v1.5.0...HEAD
[1.5.0]: https://github.com/infrakraft/terraform-aws-lexv2models/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/infrakraft/terraform-aws-lexv2models/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/infrakraft/terraform-aws-lexv2models/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/infrakraft/terraform-aws-lexv2models/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/infrakraft/terraform-aws-lexv2models/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/infrakraft/terraform-aws-lexv2models/releases/tag/v1.0.0