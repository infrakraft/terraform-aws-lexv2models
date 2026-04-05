# ==============================================================================
# Lex V2 Bot
# ==============================================================================

resource "aws_lexv2models_bot" "this" {
  name        = local.bot_name
  description = lookup(var.bot_config, "description", "Lex bot managed by Terraform")
  role_arn    = aws_iam_role.lex_role.arn
  type        = lookup(var.bot_config, "type", "Bot")

  data_privacy {
    child_directed = lookup(var.bot_config, "child_directed", false)
  }

  idle_session_ttl_in_seconds = var.bot_config.idle_session_ttl
  tags                        = var.tags
}

# ==============================================================================
# Bot locales
# ==============================================================================

resource "aws_lexv2models_bot_locale" "locales" {
  for_each = local.locales

  bot_id                           = aws_lexv2models_bot.this.id
  bot_version                      = "DRAFT"
  locale_id                        = each.key
  description                      = lookup(each.value, "description", "")
  n_lu_intent_confidence_threshold = each.value.confidence_threshold

  dynamic "voice_settings" {
    for_each = lookup(each.value, "voice_settings", null) != null ? [each.value.voice_settings] : []
    content {
      voice_id = voice_settings.value.voice_id
      engine   = lookup(voice_settings.value, "engine", null)
    }
  }
}

# ==============================================================================
# Slot types
# ==============================================================================

resource "aws_lexv2models_slot_type" "slot_types" {
  for_each = {
    for st in local.slot_types :
    "${st.locale}-${st.name}" => st
  }

  bot_id      = aws_lexv2models_bot.this.id
  bot_version = "DRAFT"
  locale_id   = each.value.locale
  name        = each.value.lex_id
  description = each.value.description

  dynamic "slot_type_values" {
    for_each = each.value.values
    content {
      sample_value {
        value = slot_type_values.value.value
      }

      dynamic "synonyms" {
        for_each = lookup(slot_type_values.value, "synonyms", [])
        content {
          value = synonyms.value
        }
      }
    }
  }

  value_selection_setting {
    resolution_strategy = (
      each.value.value_selection_strategy == "RestrictToSlotValues"
      ? "TopResolution"
      : "OriginalValue"
    )
  }

  depends_on = [aws_lexv2models_bot_locale.locales]
}

# ==============================================================================
# Intents
# ==============================================================================

resource "aws_lexv2models_intent" "intents" {
  for_each = {
    for intent in local.intents :
    "${intent.locale}-${intent.name}" => intent
  }

  bot_id      = aws_lexv2models_bot.this.id
  bot_version = "DRAFT"
  locale_id   = each.value.locale
  name        = each.value.lex_id
  description = each.value.description

  # ----------------------------------------------------------------------------
  # Sample utterances
  # ----------------------------------------------------------------------------

  dynamic "sample_utterance" {
    for_each = each.value.sample_utterances
    content {
      utterance = sample_utterance.value
    }
  }

  # ----------------------------------------------------------------------------
  # Fulfillment code hook
  # Enabled only when the intent names a Lambda that exists in
  # lambda_arns_effective. The nested ternary avoids passing null into
  # contains(), which would cause a type error at plan time.
  # ----------------------------------------------------------------------------

  dynamic "fulfillment_code_hook" {
    for_each = (
      each.value.fulfillment_lambda_name != null
      ? (contains(keys(local.lambda_arns_effective), each.value.fulfillment_lambda_name) ? [1] : [])
      : []
    )
    content {
      enabled = true
    }
  }

  # ----------------------------------------------------------------------------
  # Initial response code hook — same guard as fulfillment_code_hook
  # ----------------------------------------------------------------------------

  dynamic "initial_response_setting" {
    for_each = (
      each.value.fulfillment_lambda_name != null
      ? (contains(keys(local.lambda_arns_effective), each.value.fulfillment_lambda_name) ? [1] : [])
      : []
    )
    content {
      code_hook {
        active                      = true
        enable_code_hook_invocation = true
      }
    }
  }

  # ----------------------------------------------------------------------------
  # Confirmation (prompt + yes / no responses)
  # ----------------------------------------------------------------------------

  dynamic "confirmation_setting" {
    for_each = each.value.confirmation_prompt != null ? [each.value.confirmation_prompt] : []
    content {
      active = true

      prompt_specification {
        message_selection_strategy = confirmation_setting.value.message_selection_strategy
        max_retries                = confirmation_setting.value.max_retries

        message_group {
          message {
            plain_text_message {
              value = confirmation_setting.value.message
            }
          }

          dynamic "variation" {
            for_each = lookup(confirmation_setting.value, "variations", [])
            content {
              plain_text_message {
                value = variation.value
              }
            }
          }
        }
      }

      dynamic "confirmation_response" {
        for_each = each.value.confirmation_response != null ? [each.value.confirmation_response] : []
        content {
          message_group {
            message {
              plain_text_message {
                value = confirmation_response.value.message
              }
            }
            dynamic "variation" {
              for_each = lookup(confirmation_response.value, "variations", [])
              content {
                plain_text_message { value = variation.value }
              }
            }
          }
        }
      }

      dynamic "declination_response" {
        for_each = each.value.declination_response != null ? [each.value.declination_response] : []
        content {
          message_group {
            message {
              plain_text_message {
                value = declination_response.value.message
              }
            }
            dynamic "variation" {
              for_each = lookup(declination_response.value, "variations", [])
              content {
                plain_text_message { value = variation.value }
              }
            }
          }
        }
      }

      dynamic "failure_response" {
        for_each = each.value.failure_response != null ? [each.value.failure_response] : []
        content {
          message_group {
            message {
              plain_text_message {
                value = failure_response.value.message
              }
            }
            dynamic "variation" {
              for_each = lookup(failure_response.value, "variations", [])
              content {
                plain_text_message { value = variation.value }
              }
            }
          }
        }
      }
    }
  }

  # ----------------------------------------------------------------------------
  # Closing response
  # ----------------------------------------------------------------------------

  dynamic "closing_setting" {
    for_each = each.value.closing_prompt != null ? [each.value.closing_prompt] : []
    content {
      active = true
      closing_response {
        message_group {
          message {
            plain_text_message {
              value = closing_setting.value.message
            }
          }
          dynamic "variation" {
            for_each = closing_setting.value.variations
            content {
              plain_text_message { value = variation.value }
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      closing_setting[0].closing_response[0].allow_interrupt,
    ]
  }

  depends_on = [aws_lexv2models_bot_locale.locales]
}

# ==============================================================================
# Slots
# ==============================================================================

resource "aws_lexv2models_slot" "slots" {
  for_each = {
    for slot in local.slots :
    "${slot.locale}-${slot.intent}-${slot.name}" => slot
  }

  bot_id      = aws_lexv2models_bot.this.id
  bot_version = "DRAFT"
  locale_id   = each.value.locale
  intent_id   = aws_lexv2models_intent.intents["${each.value.locale}-${each.value.intent}"].intent_id
  name        = each.value.name
  description = each.value.description

  slot_type_id = (
    startswith(each.value.slot_type, "AMAZON.")
    ? each.value.slot_type
    : aws_lexv2models_slot_type.slot_types["${each.value.locale}-${each.value.slot_type}"].slot_type_id
  )

  value_elicitation_setting {
    slot_constraint = each.value.required ? "Required" : "Optional"

    prompt_specification {
      max_retries                = 2
      allow_interrupt            = true
      message_selection_strategy = "Random"

      message_group {
        message {
          plain_text_message {
            value = each.value.prompt
          }
        }
      }

      dynamic "prompt_attempts_specification" {
        for_each = ["Initial", "Retry1", "Retry2"]
        content {
          map_block_key   = prompt_attempts_specification.value
          allow_interrupt = true

          allowed_input_types {
            allow_audio_input = true
            allow_dtmf_input  = true
          }

          audio_and_dtmf_input_specification {
            start_timeout_ms = 4000

            audio_specification {
              max_length_ms  = 15000
              end_timeout_ms = 640
            }

            dtmf_specification {
              max_length         = 513
              end_timeout_ms     = 5000
              deletion_character = "*"
              end_character      = "#"
            }
          }

          text_input_specification {
            start_timeout_ms = 30000
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      value_elicitation_setting[0].prompt_specification[0].prompt_attempts_specification,
      value_elicitation_setting[0].prompt_specification[0].allow_interrupt,
      value_elicitation_setting[0].prompt_specification[0].message_selection_strategy,
    ]
  }

  depends_on = [
    aws_lexv2models_intent.intents,
    aws_lexv2models_slot_type.slot_types,
  ]
}

resource "null_resource" "slot_priorities" {
  for_each = {
    for intent in local.intents :
    "${intent.locale}-${intent.name}" => intent
    if length(intent.slots) > 0
  }

  triggers = {
    # Re-run whenever any slot ID in this intent changes
    slot_ids = join(",", [
      for slot_name in keys(each.value.slots) :
      aws_lexv2models_slot.slots["${each.value.locale}-${each.value.name}-${slot_name}"].slot_id
    ])
    intent_id = aws_lexv2models_intent.intents[each.key].intent_id
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<-BASH
      set -euo pipefail

      BOT_ID="${aws_lexv2models_bot.this.id}"
      INTENT_ID="${aws_lexv2models_intent.intents[each.key].intent_id}"
      LOCALE="${each.value.locale}"
      REGION="${data.aws_region.current.id}"

      # Build the slot priority JSON array — first slot = priority 1, etc.
      PRIORITIES='${jsonencode([
    for idx, slot_name in keys(each.value.slots) : {
      priority = idx + 1
      slotId   = aws_lexv2models_slot.slots["${each.value.locale}-${each.value.name}-${slot_name}"].slot_id
    }
])}'

      # Fetch the current intent definition.
      # --region is explicit to match the Terraform AWS provider region,
      # avoiding ResourceNotFoundException when the CLI default region differs.
      CURRENT=$(aws lexv2-models describe-intent \
        --region "$REGION" \
        --bot-id "$BOT_ID" \
        --bot-version DRAFT \
        --locale-id "$LOCALE" \
        --intent-id "$INTENT_ID" \
        --output json)

      # Strip all read-only / identity fields that UpdateIntent rejects,
      # then inject the slot priorities array.
      UPDATED=$(echo "$CURRENT" | jq \
        --argjson priorities "$PRIORITIES" \
        'del(
           .creationDateTime,
           .lastUpdatedDateTime,
           .botId,
           .botVersion,
           .localeId,
           .intentId
         )
         | .slotPriorities = $priorities')

      aws lexv2-models update-intent \
        --region "$REGION" \
        --bot-id "$BOT_ID" \
        --bot-version DRAFT \
        --locale-id "$LOCALE" \
        --intent-id "$INTENT_ID" \
        --cli-input-json "$UPDATED"
    BASH
}

depends_on = [aws_lexv2models_slot.slots]
}


# ==============================================================================
# Bot Version (v1.1.0)
# ==============================================================================
# Creates an immutable numbered version from the DRAFT bot.
# Versions are required for creating bot aliases and production deployments.
# ==============================================================================

resource "aws_lexv2models_bot_version" "this" {
  count = var.create_bot_version ? 1 : 0

  bot_id      = aws_lexv2models_bot.this.id
  description = var.bot_version_description

  # locale_specification is a MAP attribute, not a block!
  # Each key is a locale_id, value is an object with source_bot_version
  locale_specification = {
    for locale_id in keys(local.locales) :
    locale_id => {
      source_bot_version = lookup(
        var.bot_version_locale_specification,
        locale_id,
        "DRAFT"
      )
    }
  }

  # Ensure all locales, intents, slots are created before versioning
  depends_on = [
    aws_lexv2models_bot_locale.locales,
    aws_lexv2models_intent.intents,
    aws_lexv2models_slot.slots,
    null_resource.slot_priorities,
  ]
}