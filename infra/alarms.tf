############################################
# CloudWatch Alarms — EC2 instance
# Status checks (1m) and CPU high (10m)
############################################

############################################
# Alarm — status check failure (immediate)
############################################
resource "aws_cloudwatch_metric_alarm" "status_failed" {
  alarm_name = "${var.project_name}-${var.environment}-StatusCheckFailedAny"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1

  namespace   = "AWS/EC2"
  metric_name = "StatusCheckFailed"
  period      = 60
  statistic   = "Maximum"
  threshold   = 0

  dimensions = {
    InstanceId = aws_instance.app.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

############################################
# Alarm — high CPU utilization (10 minutes)
############################################
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name = "${var.project_name}-${var.environment}-CPUHigh"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"
  period      = 300
  statistic   = "Average"
  threshold   = 70

  dimensions = {
    InstanceId = aws_instance.app.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

