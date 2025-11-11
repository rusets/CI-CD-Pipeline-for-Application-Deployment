############################################
# GitHub OIDC role — full Lambda CRUD (scoped),
# CloudWatch Logs for those Lambdas,
# EventBridge rules for reaper schedule,
# and PassRole to the Lambda execution role
############################################

# Имя существующей роли GitHub OIDC (замени при необходимости)
locals {
  gh_oidc_role_name = "github-actions-ci-cd-pipeline-aws"

  # Префиксы ресурсов под проект/окружение
  lambda_fn_prefix_arn   = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-${var.environment}-*"
  logs_group_prefix_arn  = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-${var.environment}-*"
  logs_stream_prefix_arn = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-${var.environment}-*:*"
  events_rule_prefix_arn = "arn:aws:events:${var.region}:${data.aws_caller_identity.current.account_id}:rule/${var.project_name}-${var.environment}-*"

  # Роль, под которой работают Lambdas из этого модуля
  lambda_exec_role_arn = aws_iam_role.lambda_role.arn
}

data "aws_iam_role" "gh_oidc_role" {
  name = local.gh_oidc_role_name
}

data "aws_iam_policy_document" "gh_lambda_admin_all" {
  # Lambda CRUD на функции проекта по префиксу
  statement {
    sid    = "LambdaCrudScopedToPrefix"
    effect = "Allow"
    actions = [
      "lambda:CreateFunction",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:PublishVersion",
      "lambda:CreateAlias",
      "lambda:UpdateAlias",
      "lambda:DeleteAlias",
      "lambda:DeleteFunction",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:ListVersionsByFunction",
      "lambda:TagResource",
      "lambda:UntagResource",
      "lambda:ListTags",
      "lambda:AddPermission",
      "lambda:RemovePermission"
    ]
    resources = [local.lambda_fn_prefix_arn]
  }

  # На случай проверок существования — разрешить GetFunction по имени (безопасно)
  statement {
    sid       = "LambdaGetFunctionAnyByName"
    effect    = "Allow"
    actions   = ["lambda:GetFunction"]
    resources = ["arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:*"]
  }

  # Логи тех же функций
  statement {
    sid    = "LogsForLambdaPrefix"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      local.logs_group_prefix_arn,
      local.logs_stream_prefix_arn
    ]
  }

  # EventBridge для reaper (правило/таргеты)
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

  # PassRole только на exec-роль лямбд из этого модуля
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
}

resource "aws_iam_role_policy_attachment" "gh_attach_lambda_admin_all" {
  role       = data.aws_iam_role.gh_oidc_role.name
  policy_arn = aws_iam_policy.gh_lambda_admin_all.arn
}
