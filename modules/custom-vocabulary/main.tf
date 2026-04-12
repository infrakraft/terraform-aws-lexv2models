# ==============================================================================
# Custom Vocabulary for AWS Lex V2
# ==============================================================================
# Uses AWS CLI to manage custom vocabulary via batch operations
# ==============================================================================

data "aws_region" "current" {}

# ==============================================================================
# Local Variables
# ==============================================================================

locals {
  # Flatten custom vocabulary items for processing
  vocabulary_items = {
    for locale_id, vocab in var.custom_vocabularies : locale_id => [
      for item in vocab.items : {
        phrase     = item.phrase
        display_as = item.display_as != null ? item.display_as : ""
        weight     = item.weight
      }
    ]
  }
}

# ==============================================================================
# Custom Vocabulary via AWS CLI
# ==============================================================================

resource "null_resource" "custom_vocabulary" {
  for_each = var.custom_vocabularies

  triggers = {
    bot_id     = var.bot_id
    locale_id  = each.key
    vocab_hash = md5(jsonencode(local.vocabulary_items[each.key]))
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-BASH
      set -euo pipefail

      BOT_ID="${var.bot_id}"
      LOCALE_ID="${each.key}"
      REGION="${data.aws_region.current.id}"

      echo "=== Setting up custom vocabulary for bot: $BOT_ID, locale: $LOCALE_ID ==="

      # Wait for bot locale to be ready
      echo "Checking bot locale status..."
      MAX_WAIT=60
      ELAPSED=0
      
      while [ $ELAPSED -lt $MAX_WAIT ]; do
        LOCALE_STATUS=$(aws lexv2-models describe-bot-locale \
          --region "$REGION" \
          --bot-id "$BOT_ID" \
          --bot-version DRAFT \
          --locale-id "$LOCALE_ID" \
          --query 'botLocaleStatus' \
          --output text 2>/dev/null || echo "NotFound")
        
        if [ "$LOCALE_STATUS" = "Built" ] || [ "$LOCALE_STATUS" = "ReadyExpressTesting" ]; then
          echo "✓ Bot locale is ready ($LOCALE_STATUS)"
          break
        fi
        
        echo "  Waiting for bot locale to be ready... ($LOCALE_STATUS, $${ELAPSED}s elapsed)"
        sleep 5
        ELAPSED=$((ELAPSED + 5))
      done

      # Create vocabulary items JSON
      VOCAB_JSON=$(mktemp)
      cat > "$VOCAB_JSON" << 'VOCABEOF'
${jsonencode([
  for item in local.vocabulary_items[each.key] :
  merge(
    {
      phrase = item.phrase
      weight = item.weight
    },
    item.display_as != "" ? { displayAs = item.display_as } : {}
  )
])}
VOCABEOF

      echo "Vocabulary items to create:"
      cat "$VOCAB_JSON" | jq -c .

      # Try batch create (may fail if custom vocabulary doesn't exist yet)
      echo "Attempting to create custom vocabulary items..."
      
      if aws lexv2-models batch-create-custom-vocabulary-item \
        --region "$REGION" \
        --bot-id "$BOT_ID" \
        --bot-version DRAFT \
        --locale-id "$LOCALE_ID" \
        --custom-vocabulary-item-list "file://$VOCAB_JSON" 2>&1; then
        
        echo "✓ Custom vocabulary items created successfully"
        
      else
        echo "⚠ Batch create failed (this is normal for first-time setup)"
        echo "Custom vocabulary feature may not be initialized for this bot locale"
        echo "Please enable custom vocabulary in AWS Console:"
        echo "  1. Go to AWS Lex Console"
        echo "  2. Select bot: $BOT_ID"
        echo "  3. Select locale: $LOCALE_ID"
        echo "  4. Go to 'Custom vocabulary' section"
        echo "  5. Click 'Add vocabulary'"
        echo "  6. After initialization, run terraform apply again"
        
        rm -f "$VOCAB_JSON"
        exit 1
      fi

      # Wait for vocabulary to be ready
      if [ "${var.wait_for_vocabulary_ready}" = "true" ]; then
        echo "Waiting for vocabulary to be ready..."
        
        ELAPSED=0
        TIMEOUT=${var.vocabulary_timeout_seconds}
        
        while [ $ELAPSED -lt $TIMEOUT ]; do
          STATUS=$(aws lexv2-models describe-custom-vocabulary-metadata \
            --region "$REGION" \
            --bot-id "$BOT_ID" \
            --bot-version DRAFT \
            --locale-id "$LOCALE_ID" \
            --query 'customVocabularyStatus' \
            --output text 2>/dev/null || echo "Unknown")
          
          if [ "$STATUS" = "Ready" ]; then
            echo "✓ Custom vocabulary ready"
            break
          fi
          
          if [ "$STATUS" = "Failed" ]; then
            echo "✗ Custom vocabulary failed"
            rm -f "$VOCAB_JSON"
            exit 1
          fi
          
          sleep 5
          ELAPSED=$((ELAPSED + 5))
        done
      fi

      rm -f "$VOCAB_JSON"
      echo "✓ Custom vocabulary configuration complete"
    BASH
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["bash", "-c"]
    command     = <<-BASH
      set -euo pipefail
      
      # Delete custom vocabulary on destroy
      aws lexv2-models delete-custom-vocabulary \
        --region "${data.aws_region.current.id}" \
        --bot-id "${self.triggers.bot_id}" \
        --bot-version DRAFT \
        --locale-id "${self.triggers.locale_id}" 2>/dev/null || true
      
      echo "✓ Custom vocabulary cleanup complete"
    BASH
  }
}