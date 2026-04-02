data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Source ARN scoped to this bot + alias (principle of least privilege).
  # Restricts which bot alias can trigger the Lambda — prevents other bots
  # in the same account from invoking your fulfillment functions.
  lex_bot_alias_source_arn = format(
    "arn:aws:lex:%s:%s:bot-alias/%s/%s",
    data.aws_region.current.id,
    data.aws_caller_identity.current.account_id,
    aws_lexv2models_bot.this.id,
    var.lex_bot_alias_id
  )
}

# Grant Lex permission to invoke each Lambda function.
# One aws_lambda_permission per function — not a single wildcard — so that
# removing a function from the map cleanly removes only that permission.
resource "aws_lambda_permission" "this" {
  for_each = var.lambda_functions

  statement_id  = "AllowLexInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.arn
  principal     = "lex.amazonaws.com"
  source_arn    = local.lex_bot_alias_source_arn
}
