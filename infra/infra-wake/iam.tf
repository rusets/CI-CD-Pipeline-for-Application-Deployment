############################################
# IAM for Lambdas — trust role
############################################
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-${var.environment}-wake-sleep-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

############################################
# Locals — ARNs & conditions
############################################
locals {
  # instance ARN only if instance_id provided; otherwise null
  instance_arn = var.instance_id != "" ? "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/${var.instance_id}" : null

  # exact SSM parameter ARN (e.g. /ci-wake/last_wake)
  ssm_param_arn = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_param_last_wake}"
}

############################################
# Inline policy — EC2 (by ID or by Tag) + SSM + Describe
############################################
resource "aws_iam_role_policy" "lambda_inline" {
  name = "${var.project_name}-${var.environment}-inline"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = compact([
      # If instance_id is known — allow start/stop that exact instance
      var.instance_id != "" ? {
        Sid      = "EC2StartStopById"
        Effect   = "Allow"
        Action   = ["ec2:StartInstances", "ec2:StopInstances"]
        Resource = local.instance_arn
      } : null,

      # If instance_id is NOT known — allow start/stop only for instances with specific tag
      var.instance_id == "" ? {
        Sid      = "EC2StartStopByTag"
        Effect   = "Allow"
        Action   = ["ec2:StartInstances", "ec2:StopInstances"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/${var.instance_tag_key}" = var.instance_tag_value
          }
        }
      } : null,

      # Describe is needed broadly so the lambdas can read state
      {
        Sid      = "EC2DescribeAll"
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstances", "ec2:DescribeInstanceStatus"]
        Resource = "*"
      },

      # Exact SSM parameter (get/put last wake)
      {
        Sid      = "SSMParamGetPutExact"
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:PutParameter"]
        Resource = local.ssm_param_arn
      }
    ])
  })
}

############################################
# Logs policy (minimal) + attachment
############################################
data "aws_iam_policy_document" "logs_only" {
  statement {
    sid = "LogsBasic"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_logs" {
  name   = "${var.project_name}-${var.environment}-logs-policy"
  policy = data.aws_iam_policy_document.logs_only.json
}

resource "aws_iam_role_policy_attachment" "attach_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logs.arn
}
