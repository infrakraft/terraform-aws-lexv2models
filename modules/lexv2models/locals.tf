# locals {

#   # ============================================================================
#   # Bot name + locales
#   # ============================================================================

#   bot_name = var.bot_config.name
#   locales  = var.bot_config.locales

#   # ============================================================================
#   # Effective Lambda ARN map
#   # Merges both input paths: lambda_functions (full objects) and lambda_arns
#   # (simple ARN map). lambda_arns wins on key overlap so callers can override.
#   # ============================================================================

#   lambda_arns_effective = merge(
#     { for k, v in var.lambda_functions : k => v.arn },
#     var.lambda_arns
#   )

#   # ============================================================================
#   # Slot types — flattened from locales
#   # ============================================================================

#   slot_types = flatten([
#     for locale, locale_data in local.locales : [
#       for slot_type_name, slot_type_data in lookup(locale_data, "slot_types", {}) : {
#         locale      = locale
#         name        = slot_type_name
#         description = lookup(slot_type_data, "description", "")

#         values = [
#           for v in slot_type_data.values : {
#             value    = try(v.value, tostring(v))
#             synonyms = try(v.synonyms, [])
#           }
#         ]

#         value_selection_strategy = lookup(
#           slot_type_data,
#           "value_selection_strategy",
#           "ExpandValues"
#         )

#         lex_id = substr(
#           replace(slot_type_name, "/[^0-9a-zA-Z_]/", ""),
#           0,
#           100
#         )
#       }
#     ]
#   ])

#   # ============================================================================
#   # Intents — flattened from locales
#   # ============================================================================

#   intents = flatten([
#     for locale, locale_data in local.locales : [
#       for intent_name, intent_data in lookup(locale_data, "intents", {}) : {
#         locale                  = locale
#         name                    = intent_name
#         description             = lookup(intent_data, "description", "")
#         sample_utterances       = lookup(intent_data, "sample_utterances", [])
#         slots                   = lookup(intent_data, "slots", {})
#         fulfillment_lambda_name = lookup(intent_data, "fulfillment_lambda_name", null)

#         confirmation_prompt = contains(keys(intent_data), "confirmation_prompt") ? {
#           message                    = lookup(intent_data.confirmation_prompt, "message", "")
#           variations                 = lookup(intent_data.confirmation_prompt, "variations", [])
#           message_selection_strategy = lookup(intent_data.confirmation_prompt, "message_selection_strategy", "Ordered")
#           max_retries                = lookup(intent_data.confirmation_prompt, "max_retries", 1)
#         } : null

#         confirmation_response = contains(keys(intent_data), "confirmation_response") ? {
#           message    = lookup(intent_data.confirmation_response, "message", "")
#           variations = lookup(intent_data.confirmation_response, "variations", [])
#         } : null

#         declination_response = contains(keys(intent_data), "declination_response") ? {
#           message    = lookup(intent_data.declination_response, "message", "")
#           variations = lookup(intent_data.declination_response, "variations", [])
#         } : null

#         failure_response = contains(keys(intent_data), "failure_response") ? {
#           message    = lookup(intent_data.failure_response, "message", "")
#           variations = lookup(intent_data.failure_response, "variations", [])
#         } : null

#         closing_prompt = contains(keys(intent_data), "closing_prompt") ? {
#           message = lookup(intent_data.closing_prompt, "message", "")
#           variations = slice(
#             lookup(intent_data.closing_prompt, "variations", []),
#             0,
#             min(2, length(lookup(intent_data.closing_prompt, "variations", [])))
#           )
#           ssml_message = lookup(intent_data.closing_prompt, "ssml_message", "")
#         } : null

#         # Alphanumeric only, max 100 chars — Lex resource name constraint
#         lex_id = substr(
#           replace(intent_name, "/[^0-9a-zA-Z]/", ""),
#           0,
#           100
#         )
#       }
#     ]
#   ])

#   # ============================================================================
#   # Slots — flattened from intents
#   # ============================================================================

#   # slots = flatten([
#   #   for intent in local.intents : [
#   #     for slot_name, slot_data in intent.slots : {
#   #       locale      = intent.locale
#   #       intent      = intent.name
#   #       name        = slot_name
#   #       description = lookup(slot_data, "description", "")
#   #       slot_type   = slot_data.slot_type
#   #       required    = slot_data.required
#   #       prompt      = slot_data.prompt

#   #       lex_intent_id = intent.lex_id

#   #       lex_slot_type_id = lookup(
#   #         {
#   #           for st in local.slot_types :
#   #           "${st.locale}-${st.name}" => st.lex_id
#   #         },
#   #         "${intent.locale}-${slot_data.slot_type}",
#   #         slot_data.slot_type
#   #       )
#   #     }
#   #   ]
#   # ])

#   slots = flatten([
#     for intent in local.intents : [
#       for slot_name, slot_data in intent.slots : {
#         # Core identifiers
#         locale     = intent.locale
#         locale_id  = intent.locale
#         intent     = intent.name
#         intent_key = "${intent.locale}-${intent.name}"
#         name       = slot_name

#         # Basic attributes (backward compatible)
#         description = lookup(slot_data, "description", "")
#         slot_type   = slot_data.slot_type

#         # Normalized slot type id
#         slot_type_id = lookup(
#           {
#             for st in local.slot_types :
#             "${st.locale}-${st.name}" => st.lex_id
#           },
#           "${intent.locale}-${slot_data.slot_type}",
#           slot_data.slot_type
#         )

#         # ✅ NEW: unified config block (works for BOTH JSONs)
#         config = {
#           required                   = lookup(slot_data, "required", false)
#           prompt                     = lookup(slot_data, "prompt", null)
#           max_retries                = lookup(slot_data, "max_retries", 2)
#           allow_interrupt            = lookup(slot_data, "allow_interrupt", true)
#           message_selection_strategy = lookup(slot_data, "message_selection_strategy", "Random")
#           prompt_variations          = lookup(slot_data, "prompt_variations", [])
#           obfuscation                = lookup(slot_data, "obfuscation", null)
#         }
#       }
#     ]
#   ])

#   # ============================================================================
#   # Slot priorities per intent
#   # Required by Lex V2: every intent that has slots must declare their priority
#   # order. We derive this from the order slots appear in the config map.
#   # ============================================================================

#   # Group slots by their composite intent key so we can assign priority indices
#   # slots_by_intent = {
#   #   for key, slot in {
#   #     for slot in local.slots :
#   #     "${slot.locale}-${slot.intent}-${slot.name}" => slot
#   #   } :
#   #   "${slot.locale}-${slot.intent}" => slot...
#   # }

#   # ============================================================================
#   # Lambda map — intent key → ARN (for reference; hooks use lambda_arns_effective)
#   # ============================================================================

#   #   lambda_map = {
#   #     for intent in local.intents :
#   #     "${intent.locale}-${intent.name}" => lookup(local.lambda_arns_effective, intent.fulfillment_lambda_name, null)
#   #     if intent.fulfillment_lambda_name != null
#   #   }

#   #   slot_priorities_by_intent = {
#   #     for intent_key, slots in local.slots_by_intent :
#   #     intent_key => [
#   #       for idx, slot_name in sort([
#   #         for s in slots : s.name
#   #         ]) : {
#   #         priority = idx + 1

#   #         slotId = aws_lexv2models_slot.slots[
#   #           "${split("-", intent_key)[0]}-${split("-", intent_key)[1]}-${slot_name}"
#   #         ].slot_id
#   #       }
#   #     ]
#   #   }
# }

locals {

  # ============================================================================
  # Bot name + locales
  # ============================================================================

  bot_name = var.bot_config.name
  locales  = var.bot_config.locales

  # ============================================================================
  # Effective Lambda ARN map
  # Merges both input paths: lambda_functions (full objects) and lambda_arns
  # (simple ARN map). lambda_arns wins on key overlap so callers can override.
  # ============================================================================

  lambda_arns_effective = merge(
    { for k, v in var.lambda_functions : k => v.arn },
    var.lambda_arns
  )

  # ============================================================================
  # Slot types — flattened from locales
  # ============================================================================

  slot_types = flatten([
    for locale_id, locale_data in local.locales : [
      for slot_type_name, slot_type_data in lookup(locale_data, "slot_types", {}) : {
        locale      = locale_id
        locale_id   = locale_id
        name        = slot_type_name
        description = lookup(slot_type_data, "description", "")

        values = [
          for v in slot_type_data.values : {
            value    = try(v.value, tostring(v))
            synonyms = try(v.synonyms, [])
          }
        ]

        value_selection_strategy = lookup(
          slot_type_data,
          "value_selection_strategy",
          "TopResolution"
        )

        lex_id = substr(
          replace(slot_type_name, "/[^0-9a-zA-Z_]/", ""),
          0,
          100
        )
      }
    ]
  ])

  # ============================================================================
  # Intents — flattened from locales
  # ============================================================================

  intents = flatten([
    for locale_id, locale_data in local.locales : [
      for intent_name, intent_data in lookup(locale_data, "intents", {}) : {
        locale                  = locale_id
        locale_id               = locale_id
        name                    = intent_name
        description             = lookup(intent_data, "description", "")
        sample_utterances       = lookup(intent_data, "sample_utterances", [])
        slots                   = lookup(intent_data, "slots", {})
        fulfillment_lambda_name = lookup(intent_data, "fulfillment_lambda_name", null)

        confirmation_prompt = contains(keys(intent_data), "confirmation_prompt") ? {
          message                    = lookup(intent_data.confirmation_prompt, "message", "")
          variations                 = lookup(intent_data.confirmation_prompt, "variations", [])
          message_selection_strategy = lookup(intent_data.confirmation_prompt, "message_selection_strategy", "Ordered")
          max_retries                = lookup(intent_data.confirmation_prompt, "max_retries", 1)
        } : null

        confirmation_response = contains(keys(intent_data), "confirmation_response") ? {
          message    = lookup(intent_data.confirmation_response, "message", "")
          variations = lookup(intent_data.confirmation_response, "variations", [])
        } : null

        declination_response = contains(keys(intent_data), "declination_response") ? {
          message    = lookup(intent_data.declination_response, "message", "")
          variations = lookup(intent_data.declination_response, "variations", [])
        } : null

        failure_response = contains(keys(intent_data), "failure_response") ? {
          message    = lookup(intent_data.failure_response, "message", "")
          variations = lookup(intent_data.failure_response, "variations", [])
        } : null

        closing_prompt = contains(keys(intent_data), "closing_prompt") ? {
          message = lookup(intent_data.closing_prompt, "message", "")
          variations = slice(
            lookup(intent_data.closing_prompt, "variations", []),
            0,
            min(2, length(lookup(intent_data.closing_prompt, "variations", [])))
          )
          ssml_message = lookup(intent_data.closing_prompt, "ssml_message", "")
        } : null

        lex_id = substr(
          replace(intent_name, "/[^0-9a-zA-Z]/", ""),
          0,
          100
        )
      }
    ]
  ])

  # ============================================================================
  # Slots — flattened from intents
  # ============================================================================

  slots = flatten([
    for intent in local.intents : [
      for slot_name, slot_data in intent.slots : {
        # Core identifiers
        locale     = intent.locale_id
        locale_id  = intent.locale_id
        intent     = intent.name
        intent_key = "${intent.locale_id}-${intent.name}"
        name       = slot_name

        # Basic attributes
        description = lookup(slot_data, "description", "")
        slot_type   = slot_data.slot_type

        # Normalized slot type id
        slot_type_id = lookup(
          {
            for st in local.slot_types :
            "${st.locale_id}-${st.name}" => st.lex_id
          },
          "${intent.locale_id}-${slot_data.slot_type}",
          slot_data.slot_type
        )

        # Unified config block
        config = {
          required                   = lookup(slot_data, "required", false)
          prompt                     = lookup(slot_data, "prompt", null)
          max_retries                = lookup(slot_data, "max_retries", 2)
          allow_interrupt            = lookup(slot_data, "allow_interrupt", true)
          message_selection_strategy = lookup(slot_data, "message_selection_strategy", "Random")
          prompt_variations          = lookup(slot_data, "prompt_variations", [])
          obfuscation                = lookup(slot_data, "obfuscation", null)
        }
      }
    ]
  ])
}