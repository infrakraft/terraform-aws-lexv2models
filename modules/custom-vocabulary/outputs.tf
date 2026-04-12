output "vocabulary_status" {
  description = "Status of custom vocabulary configuration by locale"
  value = {
    for locale_id, _ in var.custom_vocabularies :
    locale_id => "Configured"
  }
}

output "vocabulary_locales" {
  description = "List of locales with custom vocabulary configured"
  value       = keys(var.custom_vocabularies)
}

output "vocabulary_item_counts" {
  description = "Number of vocabulary items per locale"
  value = {
    for locale_id, vocab in var.custom_vocabularies :
    locale_id => length(vocab.items)
  }
}