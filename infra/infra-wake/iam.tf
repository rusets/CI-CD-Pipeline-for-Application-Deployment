############################################
# IAM — Lambda trust & permissions
############################################
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-${var.environment}-wake-sleep-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

############################################
# Locals — ARNs derived from vars
############################################
locals {
  instance_arn  = var.instance_id != "" ? "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/${var.instance_id}" : null
  ssm_param_arn = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_param_last_wake}"
}

############################################
# Inline policy — Start/Stop by ID (if set) or by Tag; +Describe, +SSM, +Logs
############################################
resource "aws_iam_role_policy" "lambda_inline" {
  name = "${var.project_name}-${var.environment}-inline"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      var.instance_id != "" ? [
        {
          Sid      = "EC2StartStopById"
          Effect   = "Allow"
          Action   = ["ec2:StartInstances", "ec2:StopInstances"]
          Resource = local.instance_arn
        }
      ] : [],
      var.instance_id == "" ? [
        {
          Sid      = "EC2StartStopByTag"
          Effect   = "Allow"
          Action   = ["ec2:StartInstances", "ec2:StopInstances"]
          Resource = "*"
          Condition = {
            StringEquals = {
              "ec2:ResourceTag/${var.instance_tag_key}" = var.instance_tag_value
            }
          }
        }
      ] : [],
      [
        {
          Sid      = "EC2DescribeAll"
          Effect   = "Allow"
          Action   = ["ec2:DescribeInstances", "ec2:DescribeInstanceStatus"]
          Resource = "*"
        },
        {
          Sid      = "SSMParamGetPutExact"
          Effect   = "Allow"
          Action   = ["ssm:GetParameter", "ssm:PutParameter"]
          Resource = local.ssm_param_arn
        },
        {
          Sid    = "LogsBasic"
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
          ]
          Resource = "*"
        }
      ]
    )
  })
}
