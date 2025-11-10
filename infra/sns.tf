############################################
# SNS Topic — CloudWatch alarms
############################################
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
  tags = local.common_tags
}

############################################
# SNS Subscription — email (optional)
############################################
resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = trimspace(var.alert_email)
}
