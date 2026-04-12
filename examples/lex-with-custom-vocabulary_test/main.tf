# ============================================================================
# Data Sources
# ============================================================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ============================================================================
# Local Variables
# ============================================================================

locals {
  bot_config = jsondecode(file("${path.module}/bot_config.json"))
  namespace  = "${var.environment}-vocab-bot"
}

# ============================================================================
# S3 Bucket for Custom Vocabulary
# ============================================================================

resource "aws_s3_bucket" "vocabulary" {
  bucket_prefix = "lex-custom-vocabulary-"
  
  tags = {
    Environment = var.environment
    Purpose     = "LexCustomVocabulary"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "vocabulary" {
  bucket = aws_s3_bucket.vocabulary.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "vocabulary" {
  bucket = aws_s3_bucket.vocabulary.id
  
  rule {
    id     = "cleanup-old-vocabulary-files"
    status = "Enabled"
    
    expiration {
      days = 30
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# ============================================================================
# Lex Bot
# ============================================================================

module "lex_bot" {
  source = "../../modules/lexv2models"
  
  bot_config          = local.bot_config
  lexv2_bot_role_name = "${local.namespace}-lex-role"
  
  # Build bot automatically
  auto_build_bot_locales    = true
  wait_for_build_completion = true
  build_timeout_seconds     = 300
  
  tags = {
    Environment = var.environment
    Feature     = "CustomVocabulary"
    ManagedBy   = "Terraform"
  }
}

# ============================================================================
# Custom Vocabulary
# ============================================================================

module "custom_vocabulary" {
  source = "../../modules/custom-vocabulary"
  
  bot_id = module.lex_bot.bot_id
  
  custom_vocabularies = {
    en_GB = {
      items = [
        # Insurance-specific acronyms (high priority)
        {
          phrase      = "No Claims Bonus"
          display_as  = "NCB"
          weight      = 3
        },
        {
          phrase      = "Third Party Liability"
          display_as  = "TPL"
          weight      = 3
        },
        
        # Common insurance terms (medium priority)
        {
          phrase      = "Windscreen Cover"
          display_as  = "Windscreen Cover"
          weight      = 2
        },
        {
          phrase      = "Excess Fee"
          display_as  = "Excess"
          weight      = 2
        },
        {
          phrase      = "Comprehensive Cover"
          display_as  = "Comprehensive"
          weight      = 2
        },
        
        # Technical terms (low priority)
        {
          phrase = "Underwriter"
          weight = 1
        },
        {
          phrase = "Policyholder"
          weight = 1
        }
      ]
    }
  }
  
  vocabulary_s3_bucket       = aws_s3_bucket.vocabulary.id
  wait_for_vocabulary_ready  = var.wait_for_vocabulary
  vocabulary_timeout_seconds = var.vocabulary_timeout
  
  # CRITICAL: Wait for bot to be built first
  depends_on = [
    module.lex_bot
  ]
}