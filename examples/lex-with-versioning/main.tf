locals {
  bot_config = jsondecode(file("${path.module}/bot_config.json"))
}

module "lex_with_versioning" {
  source = "../../modules/lexv2models"

  bot_config          = local.bot_config
  lexv2_bot_role_name = "${var.environment}-${local.bot_config.name}-lex-role"

  # Enable versioning
  create_bot_version      = true
  bot_version_description = "v1.0.0 - Initial release"

  tags = {
    Environment = var.environment
    Feature     = "Versioning"
    ManagedBy   = "Terraform"
  }
}

# module "lex" {
#   source = "../../modules/lexv2models"

#   lexv2_bot_role_name = "example-versioned-bot-role"

#   bot_config = {
#     name             = "VersionedGreetingBot"
#     description      = "Example bot demonstrating versioning"
#     idle_session_ttl = 300

#     data_privacy = {
#       child_directed = false
#     }

#     locales = {
#       en_US = {
#         locale_id                = "en_US"
#         description              = "English US"
#         confidence_threshold = 0.4

#         voice_settings = {
#           voice_id = "Joanna"
#         }

#         intents = {
#           Greeting = {
#             description = "Greet the user"

#             sample_utterances = [
#               { utterance = "Hello" },
#               { utterance = "Hi" }
#             ]

#             closing_prompt = {
#               message    = "Hello! How can I help you?"
#               variations = []
#             }
#           }
#         }
#       }
#     }
#   }

#   # Enable versioning
#   create_bot_version      = true
#   bot_version_description = "v1.0.0 - Initial release"

#   tags = {
#     Environment = "example"
#     Feature     = "versioning"
#   }
# }