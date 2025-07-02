######################
# EventBridge Lambda #
######################

resource "aws_cloudwatch_event_rule" "lambda" {
  name                = "event-rule-${local.lambda_name}"
  description         = "Event Rule for ${local.lambda_name}"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = aws_cloudwatch_event_rule.lambda.name
  arn  = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda.arn
}
