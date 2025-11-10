############################################
# Data — current region (used by dashboards)
############################################
data "aws_region" "current" {}

############################################
# Locals — Logs Insights query (explicit SOURCE)
############################################
locals {
  reaper_logs_query = format(
    "SOURCE '/aws/lambda/%s' | fields @timestamp, @message | sort @timestamp desc | limit 50",
    var.reaper_function_name
  )
}

############################################
# CloudWatch Dashboard — EC2 CPU + Status (main)
############################################
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
          "region" : data.aws_region.current.id,
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
          "region" : data.aws_region.current.id,
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

############################################
# CloudWatch Dashboard — EC2 + CWAgent Overview
############################################
resource "aws_cloudwatch_dashboard" "ci_cd_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.app.id],
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.app.id],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.app.id]
          ],
          "title" : "EC2 Instance — CPU & Network",
          "period" : 300,
          "stat" : "Average",
          "region" : data.aws_region.current.id,
          "view" : "timeSeries"
        }
      },
      {
        "type" : "metric",
        "x" : 12,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["CWAgent", "mem_used_percent", "InstanceId", aws_instance.app.id],
            ["CWAgent", "disk_used_percent", "InstanceId", aws_instance.app.id]
          ],
          "title" : "CWAgent Metrics — Memory & Disk",
          "period" : 300,
          "stat" : "Average",
          "region" : data.aws_region.current.id,
          "view" : "timeSeries"
        }
      }
    ]
  })
}

############################################
# CloudWatch Dashboard — Autowake Overview
############################################
resource "aws_cloudwatch_dashboard" "autowake" {
  dashboard_name = "${var.project_name}-${var.environment}-autowake"

  dashboard_body = jsonencode({
    widgets = [
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 24,
        "height" : 6,
        "properties" : {
          "region" : data.aws_region.current.id,
          "title" : "Lambda reaper — Invocations & Errors (1m)",
          "view" : "timeSeries",
          "stat" : "Sum",
          "period" : 60,
          "stacked" : false,
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", var.reaper_function_name, { "stat" : "Sum", "period" : 60 }],
            [".", "Errors", ".", ".", { "stat" : "Sum", "period" : 60, "yAxis" : "right" }]
          ],
          "yAxis" : {
            "left" : { "label" : "Invocations" },
            "right" : { "label" : "Errors" }
          }
        }
      },
      {
        "type" : "metric",
        "x" : 0,
        "y" : 6,
        "width" : 24,
        "height" : 6,
        "properties" : {
          "region" : data.aws_region.current.id,
          "title" : "EC2 — CPU & StatusChecks (1m)",
          "view" : "timeSeries",
          "stat" : "Average",
          "period" : 60,
          "stacked" : false,
          "metrics" : [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.app.id, { "stat" : "Average", "period" : 60 }],
            [".", "StatusCheckFailed_Instance", "InstanceId", aws_instance.app.id, { "stat" : "Maximum", "period" : 60, "yAxis" : "right" }],
            [".", "StatusCheckFailed_System", "InstanceId", aws_instance.app.id, { "stat" : "Maximum", "period" : 60, "yAxis" : "right" }]
          ],
          "yAxis" : {
            "left" : { "label" : "CPU %" },
            "right" : { "label" : "Status failed (0/1)" }
          }
        }
      },
      {
        "type" : "log",
        "x" : 0,
        "y" : 12,
        "width" : 24,
        "height" : 8,
        "properties" : {
          "region" : data.aws_region.current.id,
          "title" : "Reaper timeline — recent decisions",
          "query" : local.reaper_logs_query,
          "view" : "table"
        }
      }
    ]
  })
}
