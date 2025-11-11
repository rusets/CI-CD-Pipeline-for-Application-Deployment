############################################
# Resolve EC2 by tag when instance_id is null
############################################
data "aws_instances" "by_tag" {
  filter {
    name   = "tag:${var.instance_tag_key}"
    values = [var.instance_tag_value]
  }
  instance_state_names = ["pending", "running", "stopping", "stopped"]
}

############################################
# Locals — paths, names, effective instance
############################################
locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  project_root = abspath("${path.module}/../..")
  lambdas_root = "${local.project_root}/lambdas"
  build_root   = "${local.project_root}/build"
  stage_root   = "${local.build_root}/stage"

  instance_id_effective = coalesce(
    var.instance_id,
    length(data.aws_instances.by_tag.ids) > 0 ? data.aws_instances.by_tag.ids[0] : null,
    "MISSING"
  )
}

############################################
# Fail-fast if no instance discovered (apply-time guard)
############################################
resource "null_resource" "assert_instance" {
  count = local.instance_id_effective == "MISSING" ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'ERROR: No EC2 instance found by tag ${var.instance_tag_key}=${var.instance_tag_value}, and instance_id not provided.' >&2; exit 1"
  }
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
      INSTANCE_ID         = local.instance_id_effective
      SSM_PARAM_LAST_WAKE = var.ssm_param_last_wake
    }
  }

  depends_on = [null_resource.assert_instance]
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
      set -euo pipefail
      rsync -a --delete "${local.lambdas_root}/status/" "${local.stage_root}/status/"
      mkdir -p "${local.stage_root}/status/_common"
      rsync -a "${local.lambdas_root}/_common/" "${local.stage_root}/status/_common/"
    SH
  }

  depends_on = [null_resource.prepare_build, null_resource.assert_instance]
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
      INSTANCE_ID = local.instance_id_effective
    }
  }

  depends_on = [null_resource.assert_instance]
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
      set -euo pipefail
      rsync -a --delete "${local.lambdas_root}/reaper/" "${local.stage_root}/reaper/"
      mkdir -p "${local.stage_root}/reaper/_common"
      rsync -a "${local.lambdas_root}/_common/" "${local.stage_root}/reaper/_common/"
    SH
  }

  depends_on = [null_resource.prepare_build, null_resource.assert_instance]
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
      INSTANCE_ID         = local.instance_id_effective
      IDLE_MINUTES        = tostring(var.idle_minutes)
      SSM_PARAM_LAST_WAKE = var.ssm_param_last_wake
    }
  }

  depends_on = [null_resource.assert_instance]
}
