# Custom Vocabulary Module

Add custom vocabulary to AWS Lex V2 bots for better recognition of domain-specific terms, acronyms, and technical jargon.

## What is Custom Vocabulary?

Custom vocabulary helps Lex recognize:
- **Domain-specific terms** - Insurance terms, medical terminology
- **Acronyms** - AWS, NCB, TPL
- **Product names** - Brand names, service names
- **Technical jargon** - Industry-specific language
- **Proper nouns** - Company names, locations

## How It Works

1. **Define terms** in Terraform configuration
2. **Upload to S3** - Module uploads vocabulary file automatically
3. **Import to Lex** - AWS processes and indexes the vocabulary
4. **Recognition improved** - Lex now recognizes your custom terms

## Usage

```hcl
# S3 bucket for vocabulary files
resource "aws_s3_bucket" "vocabulary" {
  bucket = "my-lex-vocabulary"
}

# Custom vocabulary module
module "custom_vocabulary" {
  source = "infrakraft/lexv2models/aws//modules/custom-vocabulary"
  version = "1.5.0"
  
  bot_id = module.lex_bot.bot_id
  
  custom_vocabularies = {
    en_US = {
      items = [
        {
          phrase      = "AWS"
          sounds_like = "A W S"
          display_as  = "AWS"
          weight      = 3
        },
        {
          phrase      = "No Claims Bonus"
          display_as  = "NCB"
          weight      = 2
        }
      ]
    }
  }
  
  vocabulary_s3_bucket       = aws_s3_bucket.vocabulary.id
  wait_for_vocabulary_ready  = true
  vocabulary_timeout_seconds = 300
}
```

## Vocabulary Item Fields

### Required
- **phrase** - The word or phrase to recognize

### Optional
- **ipa** - International Phonetic Alphabet pronunciation
- **sounds_like** - Phonetic spelling (e.g., "A W S" for AWS)
- **display_as** - How to display in transcripts (e.g., "AWS" instead of "aws")
- **weight** - Importance (1-3, higher = more important)

## Weight Guidelines

| Weight | When to Use | Examples |
|--------|-------------|----------|
| 3 | Critical terms, frequently used | Company name, key product names |
| 2 | Important terms, moderate frequency | Department names, common acronyms |
| 1 | Optional terms, low frequency | Rare technical terms |

## Examples

### Insurance Bot

```hcl
custom_vocabularies = {
  en_GB = {
    items = [
      {
        phrase      = "No Claims Bonus"
        display_as  = "NCB"
        weight      = 3
      },
      {
        phrase      = "Third Party Liability"
        display_as  = "TPL"
        weight      = 2
      },
      {
        phrase      = "Windscreen Cover"
        weight      = 1
      }
    ]
  }
}
```

### Tech Support Bot

```hcl
custom_vocabularies = {
  en_US = {
    items = [
      {
        phrase      = "AWS"
        sounds_like = "A W S"
        display_as  = "AWS"
        weight      = 3
      },
      {
        phrase      = "EC2"
        sounds_like = "E C two"
        display_as  = "EC2"
        weight      = 3
      },
      {
        phrase      = "S3"
        sounds_like = "S three"
        display_as  = "S3"
        weight      = 3
      },
      {
        phrase      = "Lambda"
        display_as  = "Lambda"
        weight      = 2
      }
    ]
  }
}
```

### Medical Bot

```hcl
custom_vocabularies = {
  en_US = {
    items = [
      {
        phrase = "acetaminophen"
        ipa    = "əˌsiːtəˈmɪnəfən"
        weight = 3
      },
      {
        phrase      = "MRI"
        sounds_like = "M R I"
        display_as  = "MRI"
        weight      = 3
      },
      {
        phrase = "hypertension"
        weight = 2
      }
    ]
  }
}
```

## Multi-Locale Support

```hcl
custom_vocabularies = {
  en_US = {
    items = [
      { phrase = "elevator", weight = 2 }
    ]
  },
  en_GB = {
    items = [
      { phrase = "lift", weight = 2 }
    ]
  },
  es_ES = {
    items = [
      { phrase = "ascensor", weight = 2 }
    ]
  }
}
```

## S3 Bucket Configuration

### Basic Setup

```hcl
resource "aws_s3_bucket" "vocabulary" {
  bucket = "my-lex-vocabulary"
}

resource "aws_s3_bucket_versioning" "vocabulary" {
  bucket = aws_s3_bucket.vocabulary.id
  
  versioning_configuration {
    status = "Enabled"
  }
}
```

### With Lifecycle Rules

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "vocabulary" {
  bucket = aws_s3_bucket.vocabulary.id
  
  rule {
    id     = "cleanup-old-vocabulary"
    status = "Enabled"
    
    expiration {
      days = 30  # Keep vocabulary files for 30 days
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bot_id | The ID of the Lex bot | `string` | n/a | yes |
| custom_vocabularies | Map of vocabularies by locale | `map(object)` | `{}` | no |
| vocabulary_s3_bucket | S3 bucket for vocabulary files | `string` | n/a | yes |
| wait_for_vocabulary_ready | Wait for import to complete | `bool` | `true` | no |
| vocabulary_timeout_seconds | Maximum wait time | `number` | `300` | no |

## Outputs

| Name | Description |
|------|-------------|
| vocabulary_status | Configuration status by locale |
| vocabulary_locales | List of configured locales |
| vocabulary_item_counts | Number of items per locale |

## Best Practices

### 1. Keep It Focused
- Add only terms Lex has trouble recognizing
- Don't add common words
- Test without custom vocabulary first

### 2. Use Appropriate Weights
- Reserve weight 3 for critical terms only
- Use weight 2 for important, frequent terms
- Use weight 1 for optional terms

### 3. Provide Context
- Use `sounds_like` for unusual pronunciations
- Use `display_as` for consistent formatting
- Use `ipa` for complex pronunciations

### 4. Test Thoroughly
- Test with real voice input
- Verify recognition improvement
- Check for false positives

### 5. Maintain Vocabulary
- Remove terms that don't help
- Add new terms as needed
- Update weights based on usage

## Limitations

- **Maximum terms:** 5,000 per locale
- **Term length:** 1-100 characters
- **Processing time:** 30-120 seconds for import
- **Updates:** Require rebuild (automatic in module)

## Troubleshooting

### Vocabulary Not Recognized

**Check:**
1. Vocabulary status: `aws lexv2-models describe-custom-vocabulary-metadata`
2. Bot built after vocabulary added
3. Weight appropriate for term importance
4. `sounds_like` matches actual pronunciation

### Import Failed

**Common causes:**
- Invalid characters in phrases
- S3 bucket not accessible
- Vocabulary file format incorrect
- Exceeded 5,000 term limit

**Solution:**
- Check CloudWatch Logs for error details
- Verify S3 bucket permissions
- Validate vocabulary file format
- Reduce number of terms

### Slow Recognition

**If recognition is slower:**
- Reduce vocabulary size
- Lower weights for less important terms
- Remove rarely-used terms
- Use more specific phrases

## Cost

Custom vocabulary has **no additional cost** beyond:
- S3 storage for vocabulary files (~$0.001/month)
- Lex text/voice requests (same as without vocabulary)

## See Also

- [Main Module Documentation](../../README.md)
- [Lex V2 Custom Vocabulary Guide](https://docs.aws.amazon.com/lexv2/latest/dg/custom-vocabulary.html)
- [Example: Lex with Custom Vocabulary](../../examples/lex-with-custom-vocabulary)



## Prerequisites

⚠️ **IMPORTANT:** Custom vocabulary must be manually enabled in AWS Console before using this module.

### One-Time Setup (Per Bot Locale)

1. Go to [AWS Lex Console](https://console.aws.amazon.com/lexv2/)
2. Select your bot
3. Select the locale (e.g., en_GB, en_US)
4. Click "Custom vocabulary" in left sidebar
5. Click "Add custom vocabulary" or "Enable custom vocabulary"
6. Add one test term (e.g., phrase: "test", display: "test")
7. Save

After this one-time setup, Terraform can manage all vocabulary items.

### Why This Is Needed

AWS Lex V2's `batch-create-custom-vocabulary-item` API requires the custom vocabulary feature to be initialized first. This cannot be done via API and must be done through the console.

This is a **one-time setup per bot locale**. Once enabled, Terraform fully manages all vocabulary items.