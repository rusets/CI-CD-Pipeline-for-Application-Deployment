############################################
# Locals — paths, names
############################################
locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  project_root = abspath("${path.module}/../..")
  lambdas_root = "${local.project_root}/lambdas"
  build_root   = "${local.project_root}/build"
}

############################################
# Discover EC2 by tag when instance_id is empty
############################################
data "aws_instances" "by_tag" {
  filter {
    name   = "tag:${var.instance_tag_key}"
    values = [var.instance_tag_value]
  }
  instance_state_names = ["pending", "running", "stopping", "stopped"]
}

locals {
  instance_id_effective = coalesce(
    var.instance_id,
    length(data.aws_instances.by_tag.ids) > 0 ? data.aws_instances.by_tag.ids[0] : "MISSING"
  )
}

############################################
# ZIP — archive functions directly from source
############################################
data "archive_file" "wake_zip" {
  type        = "zip"
  source_dir  = "${local.lambdas_root}/wake"
  output_path = "${local.build_root}/wake.zip"
}

data "archive_file" "status_zip" {
  type        = "zip"
  source_dir  = "${local.lambdas_root}/status"
  output_path = "${local.build_root}/status.zip"
}

data "archive_file" "reaper_zip" {
  type        = "zip"
  source_dir  = "${local.lambdas_root}/reaper"
  output_path = "${local.build_root}/reaper.zip"
}

############################################
# Lambda — wake (Node.js 20)
############################################
resource "aws_lambda_function" "wake" {
  function_name    = "${local.name_prefix}-wake"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.wake_zip.output_path
  source_code_hash = data.archive_file.wake_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      INSTANCE_ID         = local.instance_id_effective
      SSM_PARAM_LAST_WAKE = var.ssm_param_last_wake
    }
  }
}

############################################
# Lambda — status (Python 3.12)
############################################
resource "aws_lambda_function" "status" {
  function_name    = "${local.name_prefix}-status"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.status_zip.output_path
  source_code_hash = data.archive_file.status_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      INSTANCE_ID = local.instance_id_effective
    }
  }
}

############################################
# Lambda — reaper (Python 3.12)
############################################
resource "aws_lambda_function" "reaper" {
  function_name    = "${local.name_prefix}-reaper"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.reaper_zip.output_path
  source_code_hash = data.archive_file.reaper_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      INSTANCE_ID         = local.instance_id_effective
      IDLE_MINUTES        = tostring(var.idle_minutes)
      SSM_PARAM_LAST_WAKE = var.ssm_param_last_wake
    }
  }
}
