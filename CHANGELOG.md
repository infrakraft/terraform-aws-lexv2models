# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Custom vocabulary support
- Bot alias support (pending provider)

---

## [1.4.0] - 2025-04-11

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
  - Lambda versioning (published versions for Lex integration)
  - VPC support for private resource access
  - Environment variables (global and per-function)
  - IAM roles with CloudWatch Logs permissions
  - Optional Lambda aliases for environment management
  - Example: `examples/lex-with-lambda/` - Basic Lambda integration
  - Example: `examples/lex-with-lambda-and-cloudwatch-logs/` - Complete production setup
- **TFLint Integration**:
  - Added `.tflint.hcl` configuration file
  - AWS ruleset plugin (v0.47.0)
  - GitHub Actions workflow for automated linting
  - Local development validation support
- **Python Lambda Examples**:
  - `lambda/claims_handler/index.py` - Insurance claim processing
  - `lambda/policy_lookup/index.py` - Policy information lookup
  - Production-ready code patterns
  - Local testing support
- **Documentation**:
  - Comprehensive Lambda fulfillment module README
  - Complete example READMEs with architecture diagrams
  - Lambda code structure and best practices
  - Cost analysis for Lambda + Lex + CloudWatch
  - Monitoring and troubleshooting guides
  - TFLint usage documentation

### Changed
- `modules/lexv2models/variables.tf` - Added `lambda_functions` variable (new structure)
- Root `main.tf`, `variables.tf` - Updated for Lambda integration support
- Root `README.md` - Enhanced with Lambda section, complete production example
- Updated roadmap and features list
- GitHub Actions workflow updated with TFLint validation
- Examples structure expanded to include Lambda patterns
- **X-Ray tracing default changed from `Active` to `PassThrough`** (disabled by default)
  - Reduces costs by ~$5-10/month for production workloads
  - Can be enabled via `enable_xray_tracing = true`
  - Recommended: Enable only for production observability or debugging
- Lambda versioning now configurable via `publish_lambda_versions` (default: true for Lex)
- Enhanced Lambda configuration with advanced options

### Fixed
- None - New feature release

### Breaking Changes
- None - Fully backwards compatible
- Lambda integration is optional (default: no Lambda functions)
- Existing configurations work without modification

### Migration Notes

No migration required. Lambda fulfillment is opt-in.

**To add Lambda fulfillment:**

```hcl
# Step 1: Create Lambda functions
module "lambda_fulfillment" {
  source = "infrakraft/lexv2models/aws//modules/lambda-fulfillment"
  version = "1.4.0"
  
  lambda_functions = {
    my_handler = {
      namespace    = "my-bot"
      description  = "Fulfillment handler"
      handler      = "index.handler"
      runtime      = "python3.11"
      timeout      = 30
      memory_size  = 512
      s3_bucket    = "my-lambda-bucket"
      s3_key       = "handler.zip"
    }
  }
}

# Step 2: Connect to Lex bot
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.4.0"
  
  bot_config = {
    # ... config with fulfillment_lambda_name ...
  }
  
  # NEW: Provide Lambda ARNs
  lambda_arns = module.lambda_fulfillment.lambda_qualified_arns
}
```

### Technical Details

#### Lambda Fulfillment Module

**Inputs:**
- `lambda_functions` - Map of Lambda configurations
- `enable_lex_invocation` - Grant Lex invoke permission (default: true)
- `global_environment_variables` - Global env vars for all functions
- `vpc_config` - Optional VPC configuration
- `create_aliases` - Create Lambda aliases (default: false)
- `alias_name` - Alias name (default: "live")

**Outputs:**
- `lambda_function_arns` - Function ARNs
- `lambda_function_names` - Function names
- `lambda_qualified_arns` - **Versioned ARNs (use for Lex)**
- `lambda_versions` - Published versions
- `lambda_role_arns` - IAM role ARNs
- `functions` - Complete function details

**Features:**
- Automatic `lexv2.amazonaws.com` invoke permissions
- Published versions (required for Lex)
- CloudWatch Logs permissions
- Optional VPC access permissions
- X-Ray tracing enabled
- Lifecycle management (create_before_destroy)

#### TFLint Integration

**Configuration:**
- AWS plugin enabled (v0.47.0)
- Validates:
  - AWS resource configurations
  - Best practices
  - Common mistakes
  - Deprecated syntax

**Usage:**
```bash
# Initialize
tflint --init

# Run linting
tflint

# Recursive (all modules)
tflint --recursive
```

#### GitHub Actions

**Added jobs:**
- `tflint` - Validates all Terraform code
- `validate-lambda` - Checks Python Lambda code (optional)

**Workflow improvements:**
- Multi-version Terraform testing (1.5.7, 1.9.8)
- TFLint validation on all modules
- Python syntax validation for Lambda functions

### Lambda Function Structure

The module expects Lambda deployment packages in S3:

s3://my-bucket/
├── claims_handler.zip
│   └── index.py
└── policy_lookup.zip
└── index.py

**Lambda Event Structure (Lex V2):**
```python
{
  "sessionId": "...",
  "inputTranscript": "...",
  "interpretations": [...],
  "sessionState": {
    "intent": {
      "name": "FileClaimIntent",
      "slots": {
        "PolicyNumber": {
          "value": {
            "interpretedValue": "ABC123"
          }
        }
      }
    }
  }
}
```

**Lambda Response Structure:**
```python
{
  "sessionState": {
    "dialogAction": {
      "type": "Close"  # or "Delegate", "ElicitIntent", "ElicitSlot"
    },
    "intent": {
      "name": "FileClaimIntent",
      "state": "Fulfilled"  # or "Failed", "ReadyForFulfillment"
    }
  },
  "messages": [
    {
      "contentType": "PlainText",
      "content": "Your claim has been submitted."
    }
  ]
}
```

### Cost Impact

**Lambda costs (per month):**
- Free tier: 1M requests + 400,000 GB-seconds
- Development (3K invocations): $0.00
- Production (30K invocations): $0.80-4.00

**Total with CloudWatch Logs:**
- Development: $0.50-1.00/month
- Production: $10-25/month

### Examples Comparison

| Feature | lex-only | lex-with-versioning | lex-with-building | lex-with-cloudwatch-logs | **lex-with-lambda** | **lex-with-lambda-and-cloudwatch-logs** |
|---------|----------|---------------------|-------------------|--------------------------|---------------------|----------------------------------------|
| Bot Creation | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Bot Versioning | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Auto Building | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| CloudWatch Logs | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| **Lambda Fulfillment** | ❌ | ❌ | ❌ | ❌ | **✅** | **✅** |
| **Production Ready** | ❌ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | **✅** |

---

## [1.3.0] - 2025-04-10

### Added
- **CloudWatch Logs Module**: Separate module for creating and managing CloudWatch log groups
  - New module: `modules/cloudwatch-logs/` - Standalone log group creation
  - New variable: `name` - Log group name
  - New variable: `retention_in_days` - Configurable retention (1-3653 days, default: 365)
  - New variable: `prevent_destroy` - Protect production logs from accidental deletion
  - New variable: `kms_key_id` - Optional KMS encryption for logs at rest
  - New outputs: `cloudwatch_log_group_name`, `cloudwatch_log_group_arn`
  - Dual resource pattern (protected/unprotected) for lifecycle management
  - Example: `examples/lex-with-cloudwatch-logs/` - Complete logging implementation
- **CloudWatch Logging Integration**:
  - New variable: `enable_cloudwatch_logging` - Boolean flag to enable/disable logging
  - Automatic IAM permissions for Lex to write logs
  - Support for log streams (`:*` resource pattern)
  - Environment-based configuration (dev vs prod)
- **Documentation**:
  - Comprehensive CloudWatch logging guide in main README
  - Complete example README with:
    - Architecture diagrams
    - Configuration patterns (dev/staging/prod)
    - KMS encryption setup guide
    - CloudWatch Insights query examples
    - Cost analysis and optimization tips
    - Troubleshooting guide
  - Updated CHANGELOG with detailed migration notes

### Changed
- `modules/lexv2models/iam.tf` - Added CloudWatch logging IAM policy with boolean flag
- `modules/lexv2models/variables.tf` - Added `enable_cloudwatch_logging` and `cloudwatch_log_group_arn`
- Root `main.tf`, `variables.tf` - Pass-through CloudWatch logging configuration
- README enhanced with CloudWatch logging section and modular examples
- Updated roadmap and features list
- Examples structure expanded to include logging patterns

### Fixed
- **Breaking Fix**: CloudWatch IAM policy now uses boolean flag instead of computed count
- Resolved "count depends on resource attributes" error
- Log stream permissions now correctly scoped with `:*` pattern
- Proper handling of null vs empty string for log group ARN

### Breaking Changes
- None - Fully backwards compatible
- CloudWatch logging is optional (default: `enable_cloudwatch_logging = false`)
- Existing configurations work without modification

### Cost Optimization
- **X-Ray disabled by default** - Saves ~$5-10/month per application
- Ephemeral storage defaults to 512 MB (included in pricing)
- Optional features only enabled when explicitly configured

### Migration Notes

**X-Ray Tracing Change:**
If you relied on X-Ray being always enabled, explicitly enable it:

\`\`\`hcl
module "lambda_fulfillment" {
  source = "infrakraft/lexv2models/aws//modules/lambda-fulfillment"
  version = "1.4.0"
  
  lambda_functions = { ... }
  
  # Explicitly enable X-Ray (was default in alpha)
  enable_xray_tracing = true
}
\`\`\`

**Backward Compatibility:**
- All existing configurations work without changes
- X-Ray now disabled by default (breaking change for cost optimization)
- Lambda versioning still enabled by default (required for Lex)

**To enable CloudWatch logging:**

```hcl
# Step 1: Create log group module
module "cloudwatch_logs" {
  source = "infrakraft/lexv2models/aws//modules/cloudwatch-logs"
  version = "1.3.0"
  
  name              = "/aws/lex/MyBot"
  retention_in_days = 365
  prevent_destroy   = true  # For production
}

# Step 2: Enable in bot module
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.3.0"
  
  # ... existing config ...
  
  # NEW: Enable CloudWatch logging
  enable_cloudwatch_logging = true
  cloudwatch_log_group_arn  = module.cloudwatch_logs.cloudwatch_log_group_arn
}
```

### Technical Details

- Uses boolean flag to avoid computed count issues
- Modular design allows independent log group management
- IAM policies automatically created when logging enabled
- Supports environment-specific retention policies
- Protected vs unprotected resources for lifecycle management
- Log stream permissions included (`:*` pattern)

### CloudWatch Logs Module

The new `cloudwatch-logs` module provides:
- Configurable retention (1 day to 10 years)
- Optional KMS encryption
- Lifecycle protection for production
- Automatic tagging
- Clean outputs for integration

**Module Inputs:**
- `name` - Log group name (required)
- `retention_in_days` - Retention period (default: 365)
- `prevent_destroy` - Lifecycle protection (default: false)
- `kms_key_id` - KMS key for encryption (optional)
- `tags` - Resource tags (optional)

**Module Outputs:**
- `cloudwatch_log_group_name` - Log group name
- `cloudwatch_log_group_arn` - Log group ARN

---

## [1.2.0] - 2025-04-08

### Added
- **Automatic Bot Building**: Build bot locales automatically after deployment (no manual console clicking!)
  - New variable: `auto_build_bot_locales` (bool, default: true) - Enable/disable automatic building
  - New variable: `wait_for_build_completion` (bool, default: false) - Wait for build to complete
  - New variable: `build_timeout_seconds` (number, default: 300) - Maximum wait time for builds
  - New resource: `null_resource.build_bot_locales` - Triggers build via AWS CLI
  - New outputs: `bot_build_triggered`, `bot_locales_to_build` - Build status information
  - Example: `examples/lex-with-building/` - Complete working example with automatic building
- **Build Status Monitoring**: Real-time build progress tracking with status checks
- **Build Error Handling**: Automatic failure detection and reporting
- **Documentation**:
  - Comprehensive building documentation in main README
  - Detailed README for `lex-with-building` example
  - Build configuration best practices
  - Troubleshooting guide for build issues

### Changed
- Root module `main.tf` updated to pass building variables to submodule
- Root module `variables.tf` updated with building variable definitions
- Root module `outputs.tf` updated with build-related outputs
- Submodule `main.tf` updated with `null_resource.build_bot_locales` resource
- Submodule `variables.tf` updated with building variables
- Submodule `outputs.tf` updated with build outputs
- Enhanced README with bot building section and examples
- Updated roadmap to reflect completed and planned features
- Updated known limitations section

### Fixed
- None

### Breaking Changes
- None - This release is fully backwards compatible
- Existing configurations continue to work without modification
- Bot building is enabled by default but doesn't wait for completion (fast deployments)
- To disable building: set `auto_build_bot_locales = false`

### Migration Notes

No migration required. Bot building is enabled by default with sensible defaults.

**To use automatic building with wait:**
```hcl
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.2.0"  # Update from 1.1.0

  # ... existing configuration ...

  # Optional: Wait for build completion (default: false)
  wait_for_build_completion = true
  build_timeout_seconds     = 300
}
```

**To disable automatic building:**
```hcl
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.2.0"

  # ... existing configuration ...

  # Disable automatic building
  auto_build_bot_locales = false
}
```

### Technical Details

- Uses AWS CLI `build-bot-locale` command via `null_resource`
- Triggers rebuild when intents, slots, or slot types change (hash-based)
- Polls build status every 5 seconds when waiting for completion
- Supports timeouts from 30 seconds to 30 minutes
- Provides detailed build failure messages

---

## [1.1.0] - 2025-04-05

### Added
- **Bot Versioning Support**: Create immutable snapshots of bot configurations for production deployments
  - New variable: `create_bot_version` (bool, default: false) - Enable/disable version creation
  - New variable: `bot_version_description` (string, default: "") - Document what changed in each version
  - New variable: `bot_version_locale_specification` (map, default: {}) - Specify different source versions per locale
  - New resource: `aws_lexv2models_bot_version` in submodule - Creates numbered bot versions
  - New outputs: `bot_version`, `bot_version_id`, `bot_version_arn` - Access version information
  - Example: `examples/lex-with-versioning/` - Complete working example with versioning enabled
- **Documentation**:
  - Comprehensive versioning documentation in main README
  - Detailed README for `lex-with-versioning` example
  - Updated README for `lex-only` example
  - Version workflow and best practices guide
  - Locale-specific versioning examples

### Changed
- Root module `main.tf` updated to pass versioning variables to submodule
- Root module `variables.tf` updated with versioning variable definitions
- Root module `outputs.tf` updated with version-related outputs
- Submodule `main.tf` updated with `aws_lexv2models_bot_version` resource
- Submodule `variables.tf` updated with versioning variables
- Submodule `outputs.tf` updated with version outputs
- Enhanced README with bot versioning section and examples
- Improved example structure and documentation

### Fixed
- None

### Breaking Changes
- None - This release is fully backwards compatible
- Existing configurations continue to work without modification
- Versioning is opt-in via `create_bot_version` variable (defaults to `false`)

### Migration Notes
No migration required. To enable versioning in existing deployments:

```hcl
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.1.0"  # Update from 1.0.0

  # ... existing configuration ...

  # Add these new variables
  create_bot_version      = true
  bot_version_description = "v1.0 - Migrated to versioning"
}
```

---

## [1.0.0] - 2025-04-02

### Added
- **Initial Release**: Complete AWS Lex V2 bot management module
- Bot creation and configuration with `aws_lexv2models_bot` resource
- Multi-locale support with `aws_lexv2models_bot_locale` resource
- Intent management with `aws_lexv2models_intent` resource
- Slot type and slot management
- Slot priority configuration using `null_resource` with `local-exec` provisioner
- Lambda function integration for fulfillment and validation hooks
- IAM role management with automatic policy attachments:
  - Lex bot policy
  - CloudWatch Logs policy (optional)
  - Polly policy for voice settings (optional)
  - Lambda invoke permissions
- Voice settings with Amazon Polly integration
- Conversation logging support (CloudWatch Logs)
- Flexible bot configuration via `bot_config` variable
- Example: `examples/lex-only/` - Basic bot without versioning
- Comprehensive documentation and README
- MIT License
- GitHub Actions CI/CD workflow for validation

### Features
- JSON-based bot configuration structure
- Support for custom slot types with values and synonyms
- Sample utterance management
- Confirmation prompts and responses
- Closing prompts with variations
- Fulfillment code hooks
- Initial response settings
- Resource tagging support
- Configurable session timeout (idle_session_ttl)
- Child-directed privacy settings

### Technical Details
- Terraform >= 1.0 required
- AWS Provider >= 4.0 required
- Uses `jq` for slot priority management via local-exec
- Nested dynamic blocks for flexible configuration
- Local variables for data transformation and flattening
- Proper dependency management between resources

---

## Version Comparison

| Version | Lambda Fulfillment | CloudWatch Logs | Bot Building | Bot Versioning | TFLint |
|---------|-------------------|-----------------|--------------|----------------|--------|
| 1.4.0   | ✅ Yes            | ✅ Yes          | ✅ Yes       | ✅ Yes         | ✅ Yes |
| 1.3.0   | ❌ No             | ✅ Yes          | ✅ Yes       | ✅ Yes         | ❌ No  |
| 1.2.0   | ❌ No             | ⚠️ Partial      | ✅ Yes       | ✅ Yes         | ❌ No  |
| 1.1.0   | ❌ No             | ❌ No           | ❌ No        | ✅ Yes         | ❌ No  |
| 1.0.0   | ❌ No             | ❌ No           | ❌ No        | ❌ No          | ❌ No  |

---

## Upgrade Guides

### Upgrading from 1.0.0 to 1.1.0

**No breaking changes.** Update the version and optionally enable versioning:

```hcl
# Before (v1.0.0)
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.0.0"
  
  # ... configuration ...
}

# After (v1.1.0) - No changes required
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.1.0"  # Just update version
  
  # ... same configuration works ...
}

# After (v1.1.0) - With versioning enabled
module "lex_bot" {
  source  = "infrakraft/lexv2models/aws"
  version = "1.1.0"
  
  # ... configuration ...
  
  # New optional features
  create_bot_version      = true
  bot_version_description = "v1.0 - Production release"
}
```

**Terraform commands:**
```bash
# Update module version
terraform init -upgrade

# Review changes (should show minimal changes)
terraform plan

# Apply if desired
terraform apply
```

---

## Future Roadmap

### v1.2.0 (Planned)
- Bot alias support
- Alias-specific Lambda configurations
- Conversation log settings per alias
- Sentiment analysis per alias

### v1.3.0 (Planned)
- Enhanced conversation logging
- S3 audio log support
- CloudWatch Insights queries
- Log retention management

### v1.4.0 (Planned)
- Built-in slot types library
- Common intent templates
- Multi-region deployment examples
- Failover configurations

### v2.0.0 (Future - Breaking Changes)
- Replace `jq` dependency with native Terraform
- Refactored variable structure
- Enhanced type constraints
- Improved validation rules

---

## Links

- **Repository**: [github.com/infrakraft/terraform-aws-lexv2models](https://github.com/infrakraft/terraform-aws-lexv2models)
- **Registry**: [registry.terraform.io/modules/infrakraft/lexv2models/aws](https://registry.terraform.io/modules/infrakraft/lexv2models/aws)
- **Issues**: [github.com/infrakraft/terraform-aws-lexv2models/issues](https://github.com/infrakraft/terraform-aws-lexv2models/issues)
- **Discussions**: [github.com/infrakraft/terraform-aws-lexv2models/discussions](https://github.com/infrakraft/terraform-aws-lexv2models/discussions)

[Unreleased]: https://github.com/infrakraft/terraform-aws-lexv2models/compare/v1.4.0...HEAD
[1.4.0]: https://github.com/infrakraft/terraform-aws-lexv2models/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/infrakraft/terraform-aws-lexv2models/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/infrakraft/terraform-aws-lexv2models/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/infrakraft/terraform-aws-lexv2models/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/infrakraft/terraform-aws-lexv2models/releases/tag/v1.0.0
