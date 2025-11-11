############################################
# Identity — current AWS account
############################################
data "aws_caller_identity" "current" {}

############################################
# IAM — Lambda trust policy
############################################
data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

############################################
# IAM — Execution role for Lambdas
############################################
resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-${var.environment}-wake-sleep-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

############################################
# Locals — common ARNs and names
############################################
locals {
  instance_arn  = var.instance_id != "" ? "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/${var.instance_id}" : null
  ssm_param_arn = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_param_last_wake}"

  gh_oidc_role_name = "github-actions-ci-cd-pipeline-aws"

  lambda_fn_prefix_arn   = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-${var.environment}-*"
  logs_group_prefix_arn  = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-${var.environment}-*"
  logs_stream_prefix_arn = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-${var.environment}-*:*"
  events_rule_prefix_arn = "arn:aws:events:${var.region}:${data.aws_caller_identity.current.account_id}:rule/${var.project_name}-${var.environment}-*"

  lambda_exec_role_arn = aws_iam_role.lambda_role.arn
}

############################################
# IAM — Inline policy for Lambda execution
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
            "logs:DescribeLogStreams",
            "logs:PutLogEvents"
          ]
          Resource = "*"
        }
      ]
    )
  })
}

############################################
# IAM — Existing GitHub OIDC role
############################################
data "aws_iam_role" "gh_oidc_role" {
  name = local.gh_oidc_role_name
}

############################################
# IAM — Policy doc for GitHub CI Lambda admin
############################################
data "aws_iam_policy_document" "gh_lambda_admin_all" {
  statement {
    sid       = "LambdaCrudOnPrefixedFunctions"
    effect    = "Allow"
    actions   = ["lambda:*"]
    resources = [local.lambda_fn_prefix_arn]
  }

  statement {
    sid       = "LambdaReadAny"
    effect    = "Allow"
    actions   = ["lambda:Get*", "lambda:List*"]
    resources = ["*"]
  }

  statement {
    sid    = "LogsForLambdaPrefix"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:PutLogEvents"
    ]
    resources = [
      local.logs_group_prefix_arn,
      local.logs_stream_prefix_arn
    ]
  }

  statement {
    sid    = "EventsForReaperPrefix"
    effect = "Allow"
    actions = [
      "events:PutRule",
      "events:PutTargets",
      "events:RemoveTargets",
      "events:DeleteRule",
      "events:DescribeRule",
      "events:ListTargetsByRule"
    ]
    resources = [local.events_rule_prefix_arn]
  }

  statement {
    sid       = "PassExecRoleToLambda"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [local.lambda_exec_role_arn]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }
}

############################################
# IAM — Managed policy for CI role
############################################
resource "aws_iam_policy" "gh_lambda_admin_all" {
  name   = "${var.project_name}-${var.environment}-gh-lambda-admin"
  policy = data.aws_iam_policy_document.gh_lambda_admin_all.json

  lifecycle {
    ignore_changes  = [policy]
    prevent_destroy = true
  }
}

############################################
# IAM — Attach CI policy to OIDC role
############################################
resource "aws_iam_role_policy_attachment" "gh_attach_lambda_admin_all" {
  role       = data.aws_iam_role.gh_oidc_role.name
  policy_arn = aws_iam_policy.gh_lambda_admin_all.arn
}
