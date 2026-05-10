resource "aws_cloudwatch_event_rule" "daily_trigger" {
  for_each            = toset(local.lambda_names)
  name                = "BoohooDailySchedule_${each.value}"
  description         = "Daily trigger for boohoo-${replace(each.value, "_", "-")}"
  schedule_expression = "cron(0 0 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  for_each = toset(local.lambda_names)
  rule      = aws_cloudwatch_event_rule.daily_trigger[each.key].name
  target_id = "boohoo-${replace(each.value, "_", "-")}"
  arn       = aws_lambda_function.data_generators[each.key].arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  for_each      = toset(local.lambda_names)
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_generators[each.key].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_trigger[each.key].arn
}
