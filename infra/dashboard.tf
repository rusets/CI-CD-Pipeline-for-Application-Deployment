# Data source to get the current AWS region (e.g., us-east-1)
data "aws_region" "current" {}

# CloudWatch dashboard for monitoring the EC2 instance
resource "aws_cloudwatch_dashboard" "main" {
  # Dashboard name will include project and environment (e.g., ruslan-aws-dev)
  dashboard_name = "${var.project_name}-${var.environment}"

  # JSON body of the dashboard
  dashboard_body = jsonencode({
    widgets = [
      {
        "type" : "metric",
        "x" : 0, # position on the X-axis
        "y" : 0, # position on the Y-axis
        "width" : 12,
        "height" : 6,
        "properties" : {
          # Use AWS region dynamically from data source
          "region" : data.aws_region.current.id,
          "title" : "EC2 CPU Utilization (%)",
          "view" : "timeSeries",
          "stat" : "Average",
          "period" : 60,
          "yAxis" : { "left" : { "min" : 0 } },
          "metrics" : [
            # Metric for CPU usage of the EC2 instance
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.app.id]
          ]
        }
      },
      {
        "type" : "metric",
        "x" : 12,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "region" : data.aws_region.current.id,
          "title" : "EC2 Status Check Failed",
          "view" : "timeSeries",
          "stat" : "Maximum",
          "period" : 60,
          "metrics" : [
            # Metric for failed EC2 instance status checks
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.app.id]
          ]
        }
      }
    ]
  })
}