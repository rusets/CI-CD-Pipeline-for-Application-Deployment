############################################
# IAM — Lambda trust, Lambda exec role, inline EC2/SSM/logs, and GitHub OIDC admin
############################################

data "aws_caller_identity" "current" {}

# Trust policy for Lambda
data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Execution role for wake/status/reaper Lambdas
resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-${var.environment}-wake-sleep-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

# Common ARNs and names
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

# Inline policy for Lambda execution role:
# - Start/Stop EC2 by ID OR by Tag
# - Describe EC2
# - Get/Put exact SSM parameter
# - Basic CloudWatch Logs
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
# GitHub OIDC role — wide Lambda admin for your prefix + read-any
############################################

data "aws_iam_role" "gh_oidc_role" {
  name = local.gh_oidc_role_name
}

# Broad but scoped policy so Terraform in GitHub Actions stops hitting 403s
data "aws_iam_policy_document" "gh_lambda_admin_all" {
  # Full Lambda CRUD on functions with your prefix (ruslan-aws-<env>-*)
  statement {
    sid       = "LambdaCrudOnPrefixedFunctions"
    effect    = "Allow"
    actions   = ["lambda:*"]
    resources = [local.lambda_fn_prefix_arn]
  }

  # Read/list ANY Lambda metadata (provider does wide reads incl. code-signing config)
  statement {
    sid       = "LambdaReadAny"
    effect    = "Allow"
    actions   = ["lambda:Get*", "lambda:List*"]
    resources = ["*"]
  }

  # CloudWatch Logs for your Lambda prefix
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

  # EventBridge rules/targets for reaper scheduler with your prefix
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

  # Allow passing the Lambda execution role
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

resource "aws_iam_policy" "gh_lambda_admin_all" {
  name   = "${var.project_name}-${var.environment}-gh-lambda-admin"
  policy = data.aws_iam_policy_document.gh_lambda_admin_all.json

  # Avoid needing iam:CreatePolicyVersion on updates from CI: keep the first version
  lifecycle {
    ignore_changes  = [policy]
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "gh_attach_lambda_admin_all" {
  role       = data.aws_iam_role.gh_oidc_role.name
  policy_arn = aws_iam_policy.gh_lambda_admin_all.arn
}
