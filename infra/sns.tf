# Email to send CloudWatch alarms (can be empty)
variable "alert_email" {
  type    = string
  default = ""
  description = "Email address to receive CloudWatch alarms. Leave empty to skip SNS subscription."
}

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
  tags = local.tags
}

# Create subscription only when email is provided
resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  # trimspace убирает случайные пробелы/переводы строки
  endpoint  = trimspace(var.alert_email)
}