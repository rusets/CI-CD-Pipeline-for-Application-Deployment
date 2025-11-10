############################################
# Locals — project root & paths
############################################
locals {
  project_root = abspath("${path.module}/..")
  site_dir     = "${local.project_root}/app/public"
  name_prefix  = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

############################################
# Data — Default VPC / Subnets / Latest Amazon Linux 2023 AMI
############################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "al2023" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

############################################
# Package site → <repo>/build/site.zip
############################################
data "archive_file" "site_zip" {
  type        = "zip"
  source_dir  = local.site_dir
  output_path = "${local.project_root}/build/site.zip"
}

############################################
# Security Group — HTTP only (no SSH, no IPv6)
############################################
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Allow HTTP traffic only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-sg"
  })
}

############################################
# EC2 Instance — inject site ZIP via user_data
############################################
resource "aws_instance" "app" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.cw_agent_profile.name
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null

  user_data = templatefile("${path.module}/user_data.sh", {
    PROJECT_NAME = var.project_name
    ENVIRONMENT  = var.environment
    ARCHIVE_B64  = filebase64(data.archive_file.site_zip.output_path)
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}"
  })
}
