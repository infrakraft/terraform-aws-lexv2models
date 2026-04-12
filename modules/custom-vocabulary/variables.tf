variable "bot_id" {
  description = "The ID of the Lex bot"
  type        = string
}

variable "custom_vocabularies" {
  description = <<-EOT
    Map of custom vocabularies by locale ID.
    
    Each vocabulary contains a list of items with:
    - phrase: The word or phrase to recognize (required)
    - display_as: How to display the phrase in transcripts (optional)
    - weight: Importance weight 1-3 (optional, default: 1)
    
    Note: AWS Lex V2 custom vocabulary only supports phrase, displayAs, and weight.
    IPA and soundsLike are not supported by the batch API.
    
    Example:
    {
      "en_US" = {
        items = [
          {
            phrase      = "AWS"
            display_as  = "AWS"
            weight      = 3
          },
          {
            phrase      = "No Claims Bonus"
            display_as  = "NCB"
            weight      = 2
          }
        ]
      },
      "en_GB" = {
        items = [
          {
            phrase      = "Third Party Liability"
            display_as  = "TPL"
            weight      = 2
          }
        ]
      }
    }
  EOT
  
  type = map(object({
    items = list(object({
      phrase      = string
      display_as  = optional(string)
      weight      = optional(number, 1)
    }))
  }))
  
  default = {}
  
  validation {
    condition = alltrue([
      for locale_id, vocab in var.custom_vocabularies :
      alltrue([
        for item in vocab.items :
        item.weight >= 1 && item.weight <= 3
      ])
    ])
    error_message = "Weight must be between 1 and 3."
  }
}

variable "vocabulary_s3_bucket" {
  description = <<-EOT
    S3 bucket for storing custom vocabulary files.
    
    Required by AWS API - vocabulary files must be uploaded to S3 before
    they can be imported into Lex.
    
    The bucket should:
    - Be in the same region as your Lex bot
    - Have versioning enabled (recommended)
    - Have lifecycle rules to clean up old vocabulary files
  EOT
  type        = string
}

variable "wait_for_vocabulary_ready" {
  description = <<-EOT
    Whether to wait for vocabulary to be ready before completing.
    
    When true:
    - Terraform waits for vocabulary import to finish
    - Ensures bot is fully ready before deployment completes
    - Increases deployment time (typically 30-60 seconds)
    
    When false:
    - Terraform continues immediately after triggering import
    - Faster deployments
    - Bot may not recognize custom terms immediately
    
    Recommended: true for production, false for development
  EOT
  type        = bool
  default     = true
}

variable "vocabulary_timeout_seconds" {
  description = <<-EOT
    Maximum time to wait for vocabulary to be ready (in seconds).
    
    Typical import times:
    - Small vocabulary (< 100 terms): 15-30 seconds
    - Medium vocabulary (100-500 terms): 30-60 seconds
    - Large vocabulary (500+ terms): 60-120 seconds
    
    Set higher for large vocabularies or slower regions.
  EOT
  type        = number
  default     = 300
  
  validation {
    condition     = var.vocabulary_timeout_seconds >= 30 && var.vocabulary_timeout_seconds <= 600
    error_message = "Timeout must be between 30 and 600 seconds."
  }
}