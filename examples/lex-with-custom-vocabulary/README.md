# Lex Bot with Custom Vocabulary Example

Complete example demonstrating AWS Lex V2 custom vocabulary for domain-specific term recognition.

## What This Example Shows

- ✅ Custom vocabulary for insurance terminology
- ✅ Acronym recognition (NCB, TPL)
- ✅ Display formatting (No Claims Bonus → NCB)
- ✅ Weight prioritization for important terms
- ✅ S3 bucket management for vocabulary files
- ✅ Automatic bot building after vocabulary import
- ✅ Multi-term vocabulary management

## Architecture

┌──────────────────────────────────┐
│  User Input                      │
│  "What is my NCB?"               │
└────────┬─────────────────────────┘
│
↓
┌──────────────────────────────────┐
│  Custom Vocabulary               │
│  • No Claims Bonus → NCB         │
│  • Third Party Liability → TPL   │
│  • Windscreen Cover              │
└────────┬─────────────────────────┘
│
↓
┌──────────────────────────────────┐
│  AWS Lex V2 Bot                  │
│  • Recognizes custom terms       │
│  • Better NLU accuracy           │
│  • Formatted transcripts         │
└──────────────────────────────────┘

## What Gets Created

1. **S3 Bucket** - Stores vocabulary files
   - Versioning enabled
   - Lifecycle rules (30-day retention)
   - Automatic cleanup

2. **Lex Bot** - Insurance bot
   - CheckCoverageIntent
   - ExplainTermIntent
   - Custom slot types

3. **Custom Vocabulary** - Insurance terms
   - 7 domain-specific terms
   - Weighted by importance
   - Display name mapping

## Prerequisites

1. **AWS Account** with permissions for:
   - Lex V2
   - S3
   - IAM
2. **Terraform** >= 1.0
3. **AWS CLI** configured
4. **jq** installed

## Quick Start

### Step 1: Deploy

```bash
# Clone repository
cd examples/lex-with-custom-vocabulary

# Initialize
terraform init

# Configure
cat > terraform.tfvars << EOF
aws_region          = "eu-west-1"
environment         = "dev"
wait_for_vocabulary = true
vocabulary_timeout  = 300
EOF

# Deploy
terraform apply
```

### Step 2: Test Custom Vocabulary

**Get bot ID:**

```bash
BOT_ID=$(terraform output -raw bot_id)
```

**Test NCB recognition:**

```bash
aws lexv2-runtime recognize-text \
  --bot-id "$BOT_ID" \
  --bot-alias-id TSTALIASID \
  --locale-id en_GB \
  --session-id test-$(date +%s) \
  --text "What is my NCB?"
```

Expected: Intent recognized as CheckCoverageIntent

**Test Third Party Liability:**

```bash
aws lexv2-runtime recognize-text \
  --bot-id "$BOT_ID" \
  --bot-alias-id TSTALIASID \
  --locale-id en_GB \
  --session-id test-$(date +%s) \
  --text "Do I have TPL cover?"
```

**Test Windscreen Cover:**

```bash
aws lexv2-runtime recognize-text \
  --bot-id "$BOT_ID" \
  --bot-alias-id TSTALIASID \
  --locale-id en_GB \
  --session-id test-$(date +%s) \
  --text "Is windscreen cover included?"
```

### Step 3: Verify Vocabulary

```bash
# Check vocabulary status
aws lexv2-models describe-custom-vocabulary-metadata \
  --bot-id "$BOT_ID" \
  --bot-version DRAFT \
  --locale-id en_GB

# List vocabulary items
aws lexv2-models describe-custom-vocabulary \
  --bot-id "$BOT_ID" \
  --bot-version DRAFT \
  --locale-id en_GB
```

## Custom Vocabulary Configuration

### Current Terms

| Phrase | Display As | Weight | Purpose |
|--------|-----------|--------|---------|
| No Claims Bonus | NCB | 3 | High-priority acronym |
| Third Party Liability | TPL | 3 | High-priority acronym |
| Windscreen Cover | Windscreen Cover | 2 | Common term |
| Excess Fee | Excess | 2 | Common term |
| Comprehensive Cover | Comprehensive | 2 | Common term |
| Underwriter | Underwriter | 1 | Technical term |
| Policyholder | Policyholder | 1 | Technical term |

### Adding New Terms

Edit `main.tf`:

```hcl
custom_vocabularies = {
  en_GB = {
    items = [
      # ... existing terms ...
      
      # Add new term
      {
        phrase      = "Personal Injury Protection"
        display_as  = "PIP"
        weight      = 3
      }
    ]
  }
}
```

Then apply:

```bash
terraform apply
```

## Configuration Options

### Development

```hcl
environment         = "dev"
wait_for_vocabulary = false  # Faster deployments
vocabulary_timeout  = 120    # Shorter timeout
```

### Production

```hcl
environment         = "prod"
wait_for_vocabulary = true   # Ensure readiness
vocabulary_timeout  = 300    # Longer timeout
```

## Outputs

After deployment:

```bash
terraform output
```

Example:

bot_id               = "ABC123XYZ"
bot_name             = "InsuranceVocabBot"
vocabulary_s3_bucket = "lex-custom-vocabulary-20250411"
vocabulary_status    = {
"en_GB" = "Configured"
}
vocabulary_locales   = ["en_GB"]
vocabulary_item_counts = {
"en_GB" = 7
}

## Testing Recognition

### Before Custom Vocabulary

```bash
# "NCB" might not be recognized
"What is my ncb?" → Intent: None
```

### After Custom Vocabulary

```bash
# "NCB" recognized and formatted
"What is my NCB?" → Intent: CheckCoverageIntent
```

## Monitoring

### View Vocabulary Files in S3

```bash
BUCKET=$(terraform output -raw vocabulary_s3_bucket)

aws s3 ls "s3://$BUCKET/custom-vocabulary/" --recursive
```

### Check Import Status

```bash
BOT_ID=$(terraform output -raw bot_id)

aws lexv2-models describe-custom-vocabulary-metadata \
  --bot-id "$BOT_ID" \
  --bot-version DRAFT \
  --locale-id en_GB \
  --query '{Status: customVocabularyStatus, LastUpdated: lastUpdatedDateTime}'
```

## Troubleshooting

### Vocabulary Not Recognized

**Check status:**

```bash
aws lexv2-models describe-custom-vocabulary-metadata \
  --bot-id "$BOT_ID" \
  --bot-version DRAFT \
  --locale-id en_GB
```

**Solutions:**
1. Ensure status is "Ready"
2. Rebuild bot if needed
3. Increase weight for important terms
4. Add `sounds_like` for pronunciation

### Import Failed

**Check CloudWatch Logs:**

```bash
aws logs tail /aws/lex/InsuranceVocabBot --follow
```

**Common issues:**
- S3 bucket not accessible
- Invalid vocabulary file format
- Exceeded 5,000 term limit

### Slow Deployment

If vocabulary import is slow:

```hcl
# Disable waiting (faster, less safe)
wait_for_vocabulary = false

# Or increase timeout
vocabulary_timeout = 600
```

## Cost Estimate

| Component | Monthly Cost |
|-----------|--------------|
| Lex (10k requests) | $0.00 (free tier) |
| S3 storage | $0.001 |
| **Total** | **~$0.00** |

Custom vocabulary adds **no additional cost**.

## Best Practices

### 1. Start Small
- Add only essential terms
- Test recognition improvement
- Add more terms as needed

### 2. Use Appropriate Weights
- Weight 3: Critical terms (NCB, TPL)
- Weight 2: Important terms (Windscreen)
- Weight 1: Optional terms (Underwriter)

### 3. Test Thoroughly
- Test with voice input
- Verify formatting (NCB vs ncb)
- Check for false positives

### 4. Maintain Vocabulary
- Remove unused terms
- Update based on user feedback
- Keep under 5,000 terms

## Next Steps

1. **Add more locales** - Support en_US, es_ES
2. **Add Lambda fulfillment** - Process recognized terms
3. **Add CloudWatch Logs** - Monitor recognition
4. **Production deployment** - Version and deploy

## Clean Up

```bash
terraform destroy
```

**Note:** This deletes:
- Lex bot
- Custom vocabulary
- S3 bucket (if empty)

## Additional Resources

- [Custom Vocabulary Module](../../modules/custom-vocabulary/README.md)
- [Main Documentation](../../README.md)
- [AWS Lex Custom Vocabulary Guide](https://docs.aws.amazon.com/lexv2/latest/dg/custom-vocabulary.html)