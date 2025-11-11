############################################
# IAM — Lambda trust & permissions
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
# Locals — ARNs derived from vars
############################################
locals {
  instance_arn  = var.instance_id != "" ? "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/${var.instance_id}" : null
  ssm_param_arn = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_param_last_wake}"
}

############################################
# Inline policy — Start/Stop by ID or by Tag; +Describe, +SSM, +Logs
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

############################################
# GitHub OIDC role — allow Lambda CRUD for ruslan-aws-<env>-*
############################################

# Имя роли GitHub OIDC; при необходимости поменяй
locals {
  gh_oidc_role_name    = "github-actions-ci-cd-pipeline-aws"
  lambda_prefix_arn    = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-${var.environment}-*"
  lambda_exec_role_arn = aws_iam_role.lambda_role.arn
}

data "aws_iam_role" "gh_oidc_role" {
  name = local.gh_oidc_role_name
}

data "aws_iam_policy_document" "gh_lambda_admin" {
  statement {
    sid    = "LambdaCRUDLimitedToPrefix"
    effect = "Allow"
    actions = [
      "lambda:CreateFunction",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:PublishVersion",
      "lambda:CreateAlias",
      "lambda:UpdateAlias",
      "lambda:DeleteAlias",
      "lambda:DeleteFunction",
      "lambda:ListVersionsByFunction",
      "lambda:TagResource",
      "lambda:UntagResource",
      "lambda:ListTags",
      "lambda:AddPermission",
      "lambda:RemovePermission"
    ]
    resources = [local.lambda_prefix_arn]
  }

  statement {
    sid       = "PassExecutionRoleToLambda"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [local.lambda_exec_role_arn]
  }
}

resource "aws_iam_policy" "gh_lambda_admin" {
  name   = "${var.project_name}-${var.environment}-gh-lambda-admin"
  policy = data.aws_iam_policy_document.gh_lambda_admin.json
}

resource "aws_iam_role_policy_attachment" "gh_attach_lambda_admin" {
  role       = data.aws_iam_role.gh_oidc_role.name
  policy_arn = aws_iam_policy.gh_lambda_admin.arn
}

# Allow GetFunction on any Lambda (Terraform does existence checks by name)
data "aws_iam_policy_document" "gh_lambda_get_any" {
  statement {
    sid       = "LambdaGetFunctionAny"
    effect    = "Allow"
    actions   = ["lambda:GetFunction"]
    resources = ["arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:*"]
  }
}

resource "aws_iam_policy" "gh_lambda_get_any" {
  name   = "${var.project_name}-${var.environment}-gh-lambda-get-any"
  policy = data.aws_iam_policy_document.gh_lambda_get_any.json
}

resource "aws_iam_role_policy_attachment" "gh_attach_lambda_get_any" {
  role       = data.aws_iam_role.gh_oidc_role.name
  policy_arn = aws_iam_policy.gh_lambda_get_any.arn
}
