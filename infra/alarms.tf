# alarms.tf
# -----------------------------------------------------------------------------
# CloudWatch alarms for the EC2 instance:
# 1) Instance status checks (any failure -> alarm immediately)
# 2) High CPU usage (sustained over 10 minutes: 2x 5-minute periods)
#
# Requirements:
# - aws_instance.app must exist (we use its ID in dimensions).
# - aws_sns_topic.alerts must exist (we notify this topic on ALARM/OK).
# - The IAM principal applying this must have permissions to create alarms
#   and to publish/subscribe to the SNS topic (if needed).
# -----------------------------------------------------------------------------

# Alarm: ANY status check failure (instance or system) triggers immediately.
resource "aws_cloudwatch_metric_alarm" "status_failed" {
  # Alarm name pattern: <project>-<env>-StatusCheckFailedAny
  alarm_name = "${var.project_name}-${var.environment}-StatusCheckFailedAny"

  # Alarm when metric is > threshold (0). Any non-zero failure => ALARM.
  comparison_operator = "GreaterThanThreshold"

  # Number of evaluation periods (each = period seconds) to trigger ALARM.
  evaluation_periods = 1

  # CloudWatch metric details
  metric_name = "StatusCheckFailed" # 1 = failed, 0 = OK
  namespace   = "AWS/EC2"
  period      = 60        # one-minute granularity
  statistic   = "Maximum" # any failure in the minute trips it
  threshold   = 0

  # Scope the metric to our EC2 instance
  dimensions = {
    InstanceId = aws_instance.app.id
  }

  # Notify SNS topic when the alarm state changes
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  # Note: We intentionally do not set treat_missing_data or datapoints_to_alarm
  # to keep behavior identical to your original configuration.
}

# Alarm: High average CPU utilization for 10 minutes (2 x 5-minute periods).
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  # Alarm name pattern: <project>-<env>-CPUHigh
  alarm_name = "${var.project_name}-${var.environment}-CPUHigh"

  # Alarm when metric is > threshold (70%).
  comparison_operator = "GreaterThanThreshold"

  # Require two consecutive periods above threshold before ALARM.
  evaluation_periods = 2

  # CloudWatch metric details
  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  period      = 300       # 5 minutes
  statistic   = "Average" # smooth spikes within the window
  threshold   = 70        # %
  # If you prefer a different sensitivity, adjust threshold/periods accordingly.

  # Scope the metric to our EC2 instance
  dimensions = {
    InstanceId = aws_instance.app.id
  }

  # Notify SNS topic when the alarm state changes
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  # Same note as above: no behavior changes added (only comments).
}

# Optional tips (commented):
# - To avoid flapping during instance stop/terminate, consider:
#   # treat_missing_data = "notBreaching"
# - To require N of M periods to breach:
#   # datapoints_to_alarm = 2