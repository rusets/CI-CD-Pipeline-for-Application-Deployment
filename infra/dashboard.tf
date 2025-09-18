# data source to get the current AWS region
data "aws_region" "current" {}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "region" : data.aws_region.current.id, # ✅ use id instead of name
          "title" : "EC2 CPU Utilization (%)",
          "view" : "timeSeries",
          "stat" : "Average",
          "period" : 60,
          "yAxis" : { "left" : { "min" : 0 } },
          "metrics" : [
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
          "region" : data.aws_region.current.id, # ✅ use id instead of name
          "title" : "EC2 Status Check Failed",
          "view" : "timeSeries",
          "stat" : "Maximum",
          "period" : 60,
          "metrics" : [
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.app.id]
          ]
        }
      }
    ]
  })
}