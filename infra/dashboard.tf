# dashboard.tf
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0, y = 0, width = 12, height = 6,
        properties = {
          title   = "CPU Utilization",
          view    = "timeSeries",
          metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.app.id]]
        }
      },
      {
        type = "metric",
        x    = 12, y = 0, width = 12, height = 6,
        properties = {
          title   = "Status Check Failed",
          view    = "timeSeries",
          metrics = [["AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.app.id]]
        }
      }
    ]
  })
}
