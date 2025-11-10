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
# Inline policy — exact EC2 & exact SSM param
############################################
# EC2 instance ARN from var.instance_id
locals {
  instance_arn  = "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/${var.instance_id}"
  ssm_param_arn = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_param_last_wake}"
}

data "aws_iam_policy_document" "lambda_inline" {

  statement {
    sid = "EC2StartStopExact"
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances"
    ]
    resources = [local.instance_arn]
  }

  statement {
    sid = "EC2DescribeAll"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus"
    ]
    resources = ["*"]
  }

  statement {
    sid = "SSMParamGetPutExact"
    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter"
    ]
    resources = [local.ssm_param_arn]
  }
}

resource "aws_iam_role_policy" "lambda_inline" {
  name   = "${var.project_name}-${var.environment}-inline"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_inline.json
}

############################################
# Managed policy — logs only (keep minimal)
############################################
data "aws_iam_policy_document" "logs_only" {
  statement {
    sid = "LogsBasic"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
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
