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
  # Dialog code hook (initial response)
  # Runs BEFORE slot elicitation for validation and initialization
  # ----------------------------------------------------------------------------

  dynamic "dialog_code_hook" {
    for_each = (
      lookup(each.value, "dialog_code_hook", null) != null &&
      lookup(each.value.dialog_code_hook, "enabled", false) == true &&
      each.value.fulfillment_lambda_name != null &&
      contains(keys(local.lambda_arns_effective), each.value.fulfillment_lambda_name)
    ) ? [1] : []

    content {
      enabled = true
    }
  }

  # ----------------------------------------------------------------------------
  # Initial response setting
  # Only created when dialog_code_hook is enabled
  # ----------------------------------------------------------------------------

  dynamic "initial_response_setting" {
    for_each = (
      lookup(each.value, "dialog_code_hook", null) != null &&
      lookup(each.value.dialog_code_hook, "enabled", false) == true &&
      each.value.fulfillment_lambda_name != null &&
      contains(keys(local.lambda_arns_effective), each.value.fulfillment_lambda_name)
    ) ? [1] : []

    content {
      # Initial response messages (optional)
      dynamic "initial_response" {
        for_each = lookup(each.value, "initial_response", null) != null ? [each.value.initial_response] : []

        content {
          message_group {
            message {
              plain_text_message {
                value = initial_response.value.message
              }
            }

            dynamic "variation" {
              for_each = lookup(initial_response.value, "variations", [])
              content {
                plain_text_message {
                  value = variation.value
                }
              }
            }
          }
        }
      }

      # Code hook configuration
      code_hook {
        active                      = true
        enable_code_hook_invocation = true
        invocation_label            = lookup(each.value, "dialog_invocation_label", null)

        # Post code hook specification (REQUIRED by AWS API)
        post_code_hook_specification {
          # Success response
          success_response {
            allow_interrupt = true

            dynamic "message_group" {
              for_each = (
                lookup(each.value, "dialog_success_response", null) != null
                ? [each.value.dialog_success_response]
                : []
              )

              content {
                message {
                  plain_text_message {
                    value = message_group.value.message
                  }
                }

                dynamic "variation" {
                  for_each = lookup(message_group.value, "variations", [])
                  content {
                    plain_text_message {
                      value = variation.value
                    }
                  }
                }
              }
            }
          }

          # Failure response
          failure_response {
            allow_interrupt = true

            dynamic "message_group" {
              for_each = (
                lookup(each.value, "dialog_failure_response", null) != null
                ? [each.value.dialog_failure_response]
                : []
              )

              content {
                message {
                  plain_text_message {
                    value = message_group.value.message
                  }
                }

                dynamic "variation" {
                  for_each = lookup(message_group.value, "variations", [])
                  content {
                    plain_text_message {
                      value = variation.value
                    }
                  }
                }
              }
            }
          }

          # Timeout response
          timeout_response {
            allow_interrupt = true

            dynamic "message_group" {
              for_each = (
                lookup(each.value, "dialog_timeout_response", null) != null
                ? [each.value.dialog_timeout_response]
                : []
              )

              content {
                message {
                  plain_text_message {
                    value = message_group.value.message
                  }
                }

                dynamic "variation" {
                  for_each = lookup(message_group.value, "variations", [])
                  content {
                    plain_text_message {
                      value = variation.value
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  # ----------------------------------------------------------------------------
  # Fulfillment code hook
  # Runs AFTER all slots are filled for final processing
  # ----------------------------------------------------------------------------

  dynamic "fulfillment_code_hook" {
    for_each = (
      lookup(each.value, "fulfillment_code_hook", null) != null &&
      lookup(each.value.fulfillment_code_hook, "enabled", false) == true &&
      each.value.fulfillment_lambda_name != null &&
      contains(keys(local.lambda_arns_effective), each.value.fulfillment_lambda_name)
    ) ? [1] : []

    content {
      enabled = true

      # Post-fulfillment status specification (optional)
      dynamic "post_fulfillment_status_specification" {
        for_each = lookup(each.value, "fulfillment_response", null) != null ? [1] : []

        content {
          success_response {
            allow_interrupt = true

            dynamic "message_group" {
              for_each = lookup(each.value, "fulfillment_response", null) != null ? [each.value.fulfillment_response] : []

              content {
                message {
                  plain_text_message {
                    value = message_group.value.message
                  }
                }

                dynamic "variation" {
                  for_each = lookup(message_group.value, "variations", [])
                  content {
                    plain_text_message {
                      value = variation.value
                    }
                  }
                }
              }
            }
          }

          failure_response {
            allow_interrupt = true
          }

          timeout_response {
            allow_interrupt = true
          }
        }
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

# resource "aws_lexv2models_slot" "slots" {
#   for_each = {
#     for slot in local.slots :
#     "${slot.locale}-${slot.intent}-${slot.name}" => slot
#   }

#   bot_id      = aws_lexv2models_bot.this.id
#   bot_version = "DRAFT"
#   locale_id   = each.value.locale
#   intent_id   = aws_lexv2models_intent.intents["${each.value.locale}-${each.value.intent}"].intent_id
#   name        = each.value.name
#   description = each.value.description

#   slot_type_id = (
#     startswith(each.value.slot_type, "AMAZON.")
#     ? each.value.slot_type
#     : aws_lexv2models_slot_type.slot_types["${each.value.locale}-${each.value.slot_type}"].slot_type_id
#   )

#   value_elicitation_setting {
#     slot_constraint = each.value.required ? "Required" : "Optional"

#     prompt_specification {
#       max_retries                = 2
#       allow_interrupt            = true
#       message_selection_strategy = "Random"

#       message_group {
#         message {
#           plain_text_message {
#             value = each.value.prompt
#           }
#         }
#       }

#       dynamic "prompt_attempts_specification" {
#         for_each = ["Initial", "Retry1", "Retry2"]
#         content {
#           map_block_key   = prompt_attempts_specification.value
#           allow_interrupt = true

#           allowed_input_types {
#             allow_audio_input = true
#             allow_dtmf_input  = true
#           }

#           audio_and_dtmf_input_specification {
#             start_timeout_ms = 4000

#             audio_specification {
#               max_length_ms  = 15000
#               end_timeout_ms = 640
#             }

#             dtmf_specification {
#               max_length         = 513
#               end_timeout_ms     = 5000
#               deletion_character = "*"
#               end_character      = "#"
#             }
#           }

#           text_input_specification {
#             start_timeout_ms = 30000
#           }
#         }
#       }
#     }
#   }

#   lifecycle {
#     ignore_changes = [
#       value_elicitation_setting[0].prompt_specification[0].prompt_attempts_specification,
#       value_elicitation_setting[0].prompt_specification[0].allow_interrupt,
#       value_elicitation_setting[0].prompt_specification[0].message_selection_strategy,
#     ]
#   }

#   depends_on = [
#     aws_lexv2models_intent.intents,
#     aws_lexv2models_slot_type.slot_types,
#   ]
# }

resource "aws_lexv2models_slot" "slots" {
  for_each = {
    for slot in local.slots :
    "${slot.locale}-${slot.intent}-${slot.name}" => slot
  }
  bot_id      = aws_lexv2models_bot.this.id
  bot_version = "DRAFT"
  intent_id   = aws_lexv2models_intent.intents[each.value.intent_key].intent_id
  locale_id   = each.value.locale_id
  name        = each.value.name
  description = each.value.description != "" ? each.value.description : null

  slot_type_id = each.value.slot_type_id != null ? (
    startswith(each.value.slot_type_id, "AMAZON.") ?
    each.value.slot_type_id :
    aws_lexv2models_slot_type.slot_types["${each.value.locale_id}-${each.value.slot_type_id}"].slot_type_id
  ) : null

  value_elicitation_setting {
    slot_constraint = lookup(each.value.config, "required", false) ? "Required" : "Optional"

    prompt_specification {
      max_retries                = lookup(each.value.config, "max_retries", 2)
      allow_interrupt            = lookup(each.value.config, "allow_interrupt", true)
      message_selection_strategy = lookup(each.value.config, "message_selection_strategy", "Random")

      message_group {
        message {
          plain_text_message {
            value = lookup(each.value.config, "prompt", "Please provide ${each.value.name}")
          }
        }

        # Prompt variations
        dynamic "variation" {
          for_each = lookup(each.value.config, "prompt_variations", [])

          content {
            plain_text_message {
              value = variation.value
            }
          }
        }
      }

      # Prompt attempt specifications
      dynamic "prompt_attempts_specification" {
        for_each = ["Initial", "Retry1", "Retry2"]

        content {
          allow_interrupt = lookup(each.value.config, "allow_interrupt", true)
          map_block_key   = prompt_attempts_specification.value

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

  # Obfuscation setting for PII/sensitive data
  # Supported values: "None" or "DefaultObfuscation"
  dynamic "obfuscation_setting" {
    for_each = lookup(each.value.config, "obfuscation", null) != null ? [each.value.config.obfuscation] : []

    content {
      obfuscation_setting_type = obfuscation_setting.value
    }
  }

  depends_on = [
    aws_lexv2models_bot_locale.locales,
    aws_lexv2models_slot_type.slot_types,
    aws_lexv2models_intent.intents
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

# ==============================================================================
# Bot Locale Building (v1.2.0)
# ==============================================================================
# Automatically builds bot locales after creation/update.
# This makes the bot ready for testing without manual intervention.
# ==============================================================================

# resource "null_resource" "build_bot_locales" {
#   for_each = var.auto_build_bot_locales ? local.locales : {}
#   //for_each = tomap(var.auto_build_bot_locales ? local.locales : {})
#   triggers = {
#     bot_id    = aws_lexv2models_bot.this.id
#     locale_id = each.key
#     # Rebuild when intents or slots change
#     intents_hash = md5(jsonencode([
#       for intent in local.intents : intent
#       if intent.locale == each.key
#     ]))
#     slots_hash = md5(jsonencode([
#       for slot in local.slots : slot
#       if slot.locale == each.key
#     ]))
#     slot_types_hash = md5(jsonencode([
#       for st in local.slot_types : st
#       if st.locale == each.key
#     ]))
#   }

#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]
#     command     = <<-BASH
#       set -euo pipefail

#       BOT_ID="${aws_lexv2models_bot.this.id}"
#       LOCALE_ID="${each.key}"
#       REGION="${data.aws_region.current.id}"
#       WAIT_FOR_COMPLETION="${var.wait_for_build_completion}"
#       TIMEOUT="${var.build_timeout_seconds}"

#       echo "Building bot locale: $LOCALE_ID for bot: $BOT_ID"

#       # Trigger the build
#       aws lexv2-models build-bot-locale \
#         --region "$REGION" \
#         --bot-id "$BOT_ID" \
#         --bot-version DRAFT \
#         --locale-id "$LOCALE_ID" \
#         --output json

#       echo "✓ Build triggered for locale: $LOCALE_ID"

#       # Wait for build to complete if requested
#       if [ "$WAIT_FOR_COMPLETION" = "true" ]; then
#         echo "Waiting for build to complete (timeout: $${TIMEOUT}s)..."

#         ELAPSED=0
#         SLEEP_INTERVAL=5

#         while [ $ELAPSED -lt $TIMEOUT ]; do
#           # Check build status
#           STATUS=$(aws lexv2-models describe-bot-locale \
#             --region "$REGION" \
#             --bot-id "$BOT_ID" \
#             --bot-version DRAFT \
#             --locale-id "$LOCALE_ID" \
#             --query 'botLocaleStatus' \
#             --output text)

#           echo "  Status: $STATUS ($${ELAPSED}s elapsed)"

#           # Check if build completed successfully
#           if [ "$STATUS" = "Built" ] || [ "$STATUS" = "ReadyExpressTesting" ]; then
#             echo "✓ Build completed successfully for locale: $LOCALE_ID"
#             exit 0
#           fi

#           # Check if build failed
#           if [ "$STATUS" = "Failed" ] || [ "$STATUS" = "Deleting" ]; then
#             echo "✗ Build failed for locale: $LOCALE_ID with status: $STATUS"

#             # Try to get failure reasons
#             FAILURES=$(aws lexv2-models describe-bot-locale \
#               --region "$REGION" \
#               --bot-id "$BOT_ID" \
#               --bot-version DRAFT \
#               --locale-id "$LOCALE_ID" \
#               --query 'failureReasons' \
#               --output text 2>/dev/null || echo "Unknown")

#             echo "Failure reasons: $FAILURES"
#             exit 1
#           fi

#           # Wait before next check
#           sleep $SLEEP_INTERVAL
#           ELAPSED=$((ELAPSED + SLEEP_INTERVAL))
#         done

#         echo "⚠ Build timeout reached for locale: $LOCALE_ID after $${TIMEOUT}s"
#         echo "  Build may still be in progress. Check AWS Console for status."
#         exit 0
#       else
#         echo "Build triggered but not waiting for completion (wait_for_build_completion = false)"
#       fi
#     BASH
#   }

#   # Ensure all resources are created before building
#   depends_on = [
#     aws_lexv2models_bot_locale.locales,
#     aws_lexv2models_intent.intents,
#     aws_lexv2models_slot.slots,
#     aws_lexv2models_slot_type.slot_types,
#     null_resource.slot_priorities
#   ]
# }

# ==============================================================================
# Build Bot Locales
# ==============================================================================

resource "null_resource" "build_bot_locales" {
  # Use tomap({}) to ensure type consistency
  for_each = var.auto_build_bot_locales ? local.locales : tomap({})

  triggers = {
    bot_id    = aws_lexv2models_bot.this.id
    locale_id = each.key
    # Rebuild when intents or slots change
    intents_hash = md5(jsonencode([
      for intent in local.intents :
      intent if intent.locale_id == each.key
    ]))
    slots_hash = md5(jsonencode([
      for slot in local.slots :
      slot if slot.locale_id == each.key
    ]))
    slot_types_hash = md5(jsonencode([
      for st in local.slot_types :
      st if st.locale_id == each.key
    ]))
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-BASH
      set -euo pipefail

      BOT_ID="${aws_lexv2models_bot.this.id}"
      LOCALE_ID="${each.key}"
      REGION="${data.aws_region.current.id}"
      WAIT_FOR_COMPLETION="${var.wait_for_build_completion}"
      TIMEOUT="${var.build_timeout_seconds}"

      echo "Building bot locale: $LOCALE_ID for bot: $BOT_ID"

      # Trigger the build
      aws lexv2-models build-bot-locale \
        --region "$REGION" \
        --bot-id "$BOT_ID" \
        --bot-version DRAFT \
        --locale-id "$LOCALE_ID" \
        --output json

      echo "✓ Build triggered for locale: $LOCALE_ID"

      # Wait for build to complete if requested
      if [ "$WAIT_FOR_COMPLETION" = "true" ]; then
        echo "Waiting for build to complete (timeout: $${TIMEOUT}s)..."
        
        ELAPSED=0
        SLEEP_INTERVAL=5
        
        while [ $ELAPSED -lt $TIMEOUT ]; do
          # Check build status
          STATUS=$(aws lexv2-models describe-bot-locale \
            --region "$REGION" \
            --bot-id "$BOT_ID" \
            --bot-version DRAFT \
            --locale-id "$LOCALE_ID" \
            --query 'botLocaleStatus' \
            --output text)
          
          echo "  Status: $STATUS ($${ELAPSED}s elapsed)"
          
          # Check if build completed successfully
          if [ "$STATUS" = "Built" ] || [ "$STATUS" = "ReadyExpressTesting" ]; then
            echo "✓ Build completed successfully for locale: $LOCALE_ID"
            exit 0
          fi
          
          # Check if build failed
          if [ "$STATUS" = "Failed" ] || [ "$STATUS" = "Deleting" ]; then
            echo "✗ Build failed for locale: $LOCALE_ID with status: $STATUS"
            
            # Try to get failure reasons
            FAILURES=$(aws lexv2-models describe-bot-locale \
              --region "$REGION" \
              --bot-id "$BOT_ID" \
              --bot-version DRAFT \
              --locale-id "$LOCALE_ID" \
              --query 'failureReasons' \
              --output text 2>/dev/null || echo "Unknown")
            
            echo "Failure reasons: $FAILURES"
            exit 1
          fi
          
          # Wait before next check
          sleep $SLEEP_INTERVAL
          ELAPSED=$((ELAPSED + SLEEP_INTERVAL))
        done
        
        echo "⚠ Build timeout reached for locale: $LOCALE_ID after $${TIMEOUT}s"
        echo "  Build may still be in progress. Check AWS Console for status."
        exit 0
      else
        echo "Build triggered but not waiting for completion (wait_for_build_completion = false)"
      fi
    BASH
  }

  # Ensure all resources are created before building
  depends_on = [
    aws_lexv2models_bot_locale.locales,
    aws_lexv2models_intent.intents,
    aws_lexv2models_slot.slots,
    aws_lexv2models_slot_type.slot_types,
    null_resource.slot_priorities
  ]
}