############################################
# Locals — paths & names
############################################
locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  project_root = abspath("${path.module}/../..")
  lambdas_root = "${local.project_root}/lambdas"
  build_root   = "${local.project_root}/build"
  stage_root   = "${local.build_root}/stage"
}

############################################
# Prepare build/ and stage/ directories
############################################
resource "null_resource" "prepare_build" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.build_root} ${local.stage_root}/status ${local.stage_root}/reaper"
  }
}

############################################
# Lambda — wake (Node.js 20) — pack directly from source
############################################
data "archive_file" "wake_zip" {
  type        = "zip"
  source_dir  = "${local.lambdas_root}/wake"
  output_path = "${local.build_root}/wake.zip"

  depends_on = [null_resource.prepare_build]
}

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
      INSTANCE_ID         = var.instance_id
      SSM_PARAM_LAST_WAKE = var.ssm_param_last_wake
    }
  }
}

############################################
# Stage — status (Python) + _common with content hashes
############################################
resource "null_resource" "stage_status" {
  triggers = {
    status_src_hash = sha256(join("", tolist([
      for f in fileset("${local.lambdas_root}/status", "**") :
      filesha256("${local.lambdas_root}/status/${f}")
    ])))
    common_src_hash = sha256(join("", tolist([
      for f in fileset("${local.lambdas_root}/_common", "**") :
      filesha256("${local.lambdas_root}/_common/${f}")
    ])))
  }

  provisioner "local-exec" {
    command = <<-SH
      rsync -a --delete "${local.lambdas_root}/status/" "${local.stage_root}/status/"
      mkdir -p "${local.stage_root}/status/_common"
      rsync -a "${local.lambdas_root}/_common/" "${local.stage_root}/status/_common/"
    SH
  }

  depends_on = [null_resource.prepare_build]
}

data "archive_file" "status_zip" {
  type        = "zip"
  source_dir  = "${local.stage_root}/status"
  output_path = "${local.build_root}/status.zip"

  depends_on = [null_resource.stage_status]
}

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
      INSTANCE_ID = var.instance_id
    }
  }
}

############################################
# Stage — reaper (Python) + _common with content hashes
############################################
resource "null_resource" "stage_reaper" {
  triggers = {
    reaper_src_hash = sha256(join("", tolist([
      for f in fileset("${local.lambdas_root}/reaper", "**") :
      filesha256("${local.lambdas_root}/reaper/${f}")
    ])))
    common_src_hash = sha256(join("", tolist([
      for f in fileset("${local.lambdas_root}/_common", "**") :
      filesha256("${local.lambdas_root}/_common/${f}")
    ])))
  }

  provisioner "local-exec" {
    command = <<-SH
      rsync -a --delete "${local.lambdas_root}/reaper/" "${local.stage_root}/reaper/"
      mkdir -p "${local.stage_root}/reaper/_common"
      rsync -a "${local.lambdas_root}/_common/" "${local.stage_root}/reaper/_common/"
    SH
  }

  depends_on = [null_resource.prepare_build]
}

data "archive_file" "reaper_zip" {
  type        = "zip"
  source_dir  = "${local.stage_root}/reaper"
  output_path = "${local.build_root}/reaper.zip"

  depends_on = [null_resource.stage_reaper]
}

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
      INSTANCE_ID         = var.instance_id
      IDLE_MINUTES        = tostring(var.idle_minutes)
      SSM_PARAM_LAST_WAKE = var.ssm_param_last_wake
    }
  }
}
