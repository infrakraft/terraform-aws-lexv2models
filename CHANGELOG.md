# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Lambda fulfillment module
- Custom vocabulary support
- Bot alias support (pending provider)

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

### Migration Notes

No migration required. CloudWatch logging is opt-in.

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

| Version | Bot Versioning | Bot Building | CloudWatch Logs | Bot Aliases | Multi-Locale |
|---------|----------------|--------------|-----------------|-------------|--------------|
| 1.3.0   | ✅ Yes         | ✅ Yes       | ✅ Yes          | ❌ No       | ✅ Yes       |
| 1.2.0   | ✅ Yes         | ✅ Yes       | ⚠️ Partial      | ❌ No       | ✅ Yes       |
| 1.1.0   | ✅ Yes         | ❌ No        | ❌ No           | ❌ No       | ✅ Yes       |
| 1.0.0   | ❌ No          | ❌ No        | ❌ No           | ❌ No       | ✅ Yes       |

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

[Unreleased]: https://github.com/infrakraft/terraform-aws-lexv2models/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/infrakraft/terraform-aws-lexv2models/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/infrakraft/terraform-aws-lexv2models/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/infrakraft/terraform-aws-lexv2models/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/infrakraft/terraform-aws-lexv2models/releases/tag/v1.0.0
