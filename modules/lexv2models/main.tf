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

# ==============================================================================
# Slot priorities
#
# KNOWN PROVIDER BUG: slot_priority is a block on aws_lexv2models_intent, but
# it requires slot IDs that don't exist until aws_lexv2models_slot is applied.
# This creates an inescapable cycle in the Terraform graph.
# See: https://github.com/hashicorp/terraform-provider-aws/issues/36863
#      https://github.com/hashicorp/terraform-provider-aws/issues/39948
#
# Workaround: after slots are created, we call the Lex V2 UpdateIntent API
# via AWS CLI using a null_resource local-exec. This runs outside Terraform's
# dependency graph, so no cycle exists. The null_resource re-triggers whenever
# slot IDs change (tracked via triggers).
#
# The bot locale must be built after priorities are set, so
# aws_lexv2models_bot_locale depends on this resource implicitly via the
# build_bot_locale null_resource below.
# ==============================================================================

# resource "null_resource" "slot_priorities" {
#   for_each = {
#     for intent in local.intents :
#     "${intent.locale}-${intent.name}" => intent
#     if length(intent.slots) > 0
#   }

#   triggers = {
#     # Re-run whenever any slot ID in this intent changes
#     slot_ids = join(",", [
#       for slot_name in keys(each.value.slots) :
#       aws_lexv2models_slot.slots["${each.value.locale}-${each.value.name}-${slot_name}"].slot_id
#     ])
#     intent_id = aws_lexv2models_intent.intents[each.key].intent_id
#   }

#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]
#     command     = <<-BASH
#       set -euo pipefail

#       BOT_ID="${aws_lexv2models_bot.this.id}"
#       INTENT_ID="${aws_lexv2models_intent.intents[each.key].intent_id}"
#       LOCALE="${each.value.locale}"

#       # Build the slot priority JSON array — first slot = priority 1, etc.
#       PRIORITIES='${jsonencode([
#         for idx, slot_name in keys(each.value.slots) : {
#           priority = idx + 1
#           slotId   = aws_lexv2models_slot.slots["${each.value.locale}-${each.value.name}-${slot_name}"].slot_id
#         }
#       ])}'

#       # Fetch the current intent definition (note: describe-intent, not get-intent)
#       CURRENT=$(aws lexv2-models describe-intent \
#         --bot-id "$BOT_ID" \
#         --bot-version DRAFT \
#         --locale-id "$LOCALE" \
#         --intent-id "$INTENT_ID" \
#         --output json)

#       # Strip all read-only / identity fields that UpdateIntent rejects,
#       # then inject the slot priorities array.
#       UPDATED=$(echo "$CURRENT" | jq \
#         --argjson priorities "$PRIORITIES" \
#         'del(
#            .creationDateTime,
#            .lastUpdatedDateTime,
#            .botId,
#            .botVersion,
#            .localeId,
#            .intentId
#          )
#          | .slotPriorities = $priorities')

#       aws lexv2-models update-intent \
#         --bot-id "$BOT_ID" \
#         --bot-version DRAFT \
#         --locale-id "$LOCALE" \
#         --intent-id "$INTENT_ID" \
#         --cli-input-json "$UPDATED"
#     BASH
#   }

#   depends_on = [aws_lexv2models_slot.slots]
# }

# resource "null_resource" "update_intent_slots" {
#     triggers = {
#         always_run = timestamp()
#     }
#     for_each = { for item in local.intent_slot_pairs : "${item.bot_name}_${item.intent_name}_${item.slot_name}" => item }

#     provisioner "local-exec" {
#         command = <<EOT
#         aws lexv2-models update-intent \
#         --bot-id ${aws_lexv2models_bot.this[each.value.bot_name].id} \
#         --bot-version ${aws_lexv2models_bot_locale.this[each.value.bot_name].bot_version} \
#         --locale-id ${aws_lexv2models_bot_locale.this[each.value.bot_name].locale_id} \
#         --intent-id ${split(":", aws_lexv2models_intent.this["${each.value.bot_name}_${each.value.intent_name}"].id)[0]} \
#         --intent-name ${each.value.intent_name} \
#         --slot-priorities "[{\"priority\": ${each.value.priority}, \"slotId\": \"${split(",", aws_lexv2models_slot.this["${each.value.intent_name}_${each.value.slot_name}"].id)[4]}\"}]"
#         EOT
#     }
#     depends_on = [
#     aws_lexv2models_intent.this,
#     aws_lexv2models_slot.this
#   ]
# }

# resource "null_resource" "update_intent_slot_priorities" {
#   for_each = {
#     for intent in local.intents :
#     "${intent.locale}-${intent.name}" => intent
#     if length(intent.slots) > 0
#   }

#   triggers = {
#     intent_id = aws_lexv2models_intent.intents[each.key].intent_id

#     slot_ids = join(",", [
#       for s in local.slot_priorities_by_intent[each.key] : s.slot_id
#     ])
#   }

#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]

#     command = <<-EOT
#       set -euo pipefail

#       BOT_ID="${aws_lexv2models_bot.this.id}"
#       INTENT_ID="${aws_lexv2models_intent.intents[each.key].intent_id}"
#       LOCALE="${each.value.locale}"

#       echo "Waiting for intent to become available..."

#       for i in {1..30}; do
#         if aws lexv2-models describe-intent \
#           --bot-id "$BOT_ID" \
#           --bot-version DRAFT \
#           --locale-id "$LOCALE" \
#           --intent-id "$INTENT_ID" > /dev/null 2>&1; then
#           echo "Intent ready"
#           break
#         fi
#         sleep 5
#       done

#       PRIORITIES='${jsonencode(local.slot_priorities_by_intent[each.key])}'

#       CURRENT=$(aws lexv2-models describe-intent \
#         --bot-id "$BOT_ID" \
#         --bot-version DRAFT \
#         --locale-id "$LOCALE" \
#         --intent-id "$INTENT_ID" \
#         --output json)

#       UPDATED=$(echo "$CURRENT" | jq \
#         --argjson priorities "$PRIORITIES" \
#         'del(
#            .creationDateTime,
#            .lastUpdatedDateTime,
#            .botId,
#            .botVersion,
#            .localeId,
#            .intentId
#          )
#          | .slotPriorities = $priorities')

#       aws lexv2-models update-intent \
#         --bot-id "$BOT_ID" \
#         --bot-version DRAFT \
#         --locale-id "$LOCALE" \
#         --intent-id "$INTENT_ID" \
#         --cli-input-json "$UPDATED"

#       echo "Updated slot priorities for intent: $INTENT_ID"
#     EOT
#   }

#   depends_on = [
#     aws_lexv2models_slot.slots
#   ]
# }

# resource "null_resource" "build_bot_locale" {
#   for_each = local.locales

#   provisioner "local-exec" {
#     command = <<EOT
# aws lexv2-models build-bot-locale \
#   --bot-id ${aws_lexv2models_bot.this.id} \
#   --bot-version DRAFT \
#   --locale-id ${each.key}
# EOT
#   }

#   depends_on = [
#     null_resource.update_intent_slot_priorities
#   ]
# }


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

# resource "null_resource" "build_bot_locale_before_priorities" {
#   for_each = local.locales

#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]

#     command = <<-EOT
#       set -euo pipefail

#       BOT_ID="${aws_lexv2models_bot.this.id}"
#       LOCALE="${each.key}"

#       echo "Starting build for locale: $LOCALE"

#       aws lexv2-models build-bot-locale \
#         --bot-id "$BOT_ID" \
#         --bot-version DRAFT \
#         --locale-id "$LOCALE"

#       echo "Waiting for build to complete..."

#       for i in {1..60}; do
#         STATUS=$(aws lexv2-models describe-bot-locale \
#           --bot-id "$BOT_ID" \
#           --bot-version DRAFT \
#           --locale-id "$LOCALE" \
#           --query 'botLocaleStatus' \
#           --output text 2>/dev/null || echo "NOT_READY")

#         echo "Status: $STATUS"

#         if [ "$STATUS" = "Built" ]; then
#           echo "Build completed for locale: $LOCALE"
#           exit 0
#         fi

#         sleep 5
#       done

#       echo "ERROR: Build did not complete in time"
#       exit 1
#     EOT
#   }

#   depends_on = [
#     aws_lexv2models_intent.intents,
#     aws_lexv2models_slot.slots
#   ]
# }

# resource "null_resource" "update_intent_slot_priorities" {
#   for_each = {
#     for intent in local.intents :
#     "${intent.locale}-${intent.name}" => intent
#     if length(intent.slots) > 0
#   }

#   triggers = {
#     intent_id = aws_lexv2models_intent.intents[each.key].intent_id

#     slot_ids = join(",", [
#       for s in local.slot_priorities_by_intent[each.key] : s.slotId
#     ])
#   }

#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]

#     command = <<-EOT
#       set -euo pipefail

#       BOT_ID="${aws_lexv2models_bot.this.id}"
#       INTENT_ID="${aws_lexv2models_intent.intents[each.key].intent_id}"
#       LOCALE="${each.value.locale}"

#       echo "Fetching intent definition..."

#       CURRENT=$(aws lexv2-models describe-intent \
#         --bot-id "$BOT_ID" \
#         --bot-version DRAFT \
#         --locale-id "$LOCALE" \
#         --intent-id "$INTENT_ID" \
#         --output json)

#       PRIORITIES='${jsonencode(local.slot_priorities_by_intent[each.key])}'

#       echo "Updating slot priorities..."

#       UPDATED=$(echo "$CURRENT" | jq \
#         --argjson priorities "$PRIORITIES" \
#         'del(
#            .creationDateTime,
#            .lastUpdatedDateTime,
#            .botId,
#            .botVersion,
#            .localeId,
#            .intentId
#          )
#          | .slotPriorities = $priorities')

#       aws lexv2-models update-intent \
#         --bot-id "$BOT_ID" \
#         --bot-version DRAFT \
#         --locale-id "$LOCALE" \
#         --intent-id "$INTENT_ID" \
#         --cli-input-json "$UPDATED"

#       echo "Updated slot priorities for intent: $INTENT_ID"
#     EOT
#   }

#   depends_on = [
#     null_resource.build_bot_locale_before_priorities
#   ]
# }

# resource "null_resource" "build_bot_locale_final" {
#   for_each = local.locales

#   provisioner "local-exec" {
#     command = <<EOT
# aws lexv2-models build-bot-locale \
#   --bot-id ${aws_lexv2models_bot.this.id} \
#   --bot-version DRAFT \
#   --locale-id ${each.key}
# EOT
#   }

#   depends_on = [
#     null_resource.update_intent_slot_priorities
#   ]
# }