############################################
# EventBridge rule — run reaper every 1 minute
############################################
resource "aws_cloudwatch_event_rule" "reaper_every_min" {
  name                = "${local.name_prefix}-reaper-1m"
  description         = "Invoke ${aws_lambda_function.reaper.function_name} every minute to auto-sleep EC2 when idle"
  schedule_expression = "rate(1 minute)"
}

############################################
# Event target — send to the reaper Lambda
############################################
resource "aws_cloudwatch_event_target" "reaper_target" {
  rule      = aws_cloudwatch_event_rule.reaper_every_min.name
  target_id = "lambda"
  arn       = aws_lambda_function.reaper.arn
}

############################################
# Permission — allow EventBridge to invoke Lambda
############################################
resource "aws_lambda_permission" "reaper_events_invoke" {
  statement_id  = "AllowExecutionFromEventBridgeEveryMin"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reaper.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.reaper_every_min.arn
}
