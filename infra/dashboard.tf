# data source to get the current AWS region
data "aws_region" "current" {}

# CloudWatch Dashboard with explicit region in each widget
resource "aws_cloudwatch_dashboard" "main" {
  # Dashboard name: <project>-<env>
  dashboard_name = "${var.project_name}-${var.environment}"

  # IMPORTANT: build JSON body via jsonencode so it's always valid
  dashboard_body = jsonencode({
    widgets = [
      {
        "type"  : "metric",
        "x"     : 0,
        "y"     : 0,
        "width" : 12,
        "height": 6,
        "properties": {
          "region" : data.aws_region.current.name,   # explicit region
          "title"  : "EC2 CPU Utilization (%)",
          "view"   : "timeSeries",
          "stat"   : "Average",
          "period" : 60,
          "yAxis"  : { "left": { "min": 0 } },
          "metrics": [
            # namespace, metric, dimension-key, dimension-value
            [ "AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.app.id ]
          ]
        }
      },
      {
        "type"  : "metric",
        "x"     : 12,
        "y"     : 0,
        "width" : 12,
        "height": 6,
        "properties": {
          "region" : data.aws_region.current.name,   # explicit region
          "title"  : "EC2 Status Check Failed",
          "view"   : "timeSeries",
          "stat"   : "Maximum",
          "period" : 60,
          "metrics": [
            [ "AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.app.id ]
          ]
        }
      }
    ]
  })
}