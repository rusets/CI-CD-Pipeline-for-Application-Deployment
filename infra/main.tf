# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------
# main.tf (или где объявлены locals)
locals {
  site_dir    = "${path.module}/app/public" # ✅ правильный путь
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Data sources: default VPC, subnets, latest Amazon Linux 2023 AMI
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# Package local site into ZIP and pass to user_data as Base64
# -----------------------------------------------------------------------------
data "archive_file" "site_zip" {
  type        = "zip"
  source_dir  = local.site_dir
  output_path = "${path.module}/.site.zip"
}

# -----------------------------------------------------------------------------
# Security Group (HTTP always; SSH optional)
# -----------------------------------------------------------------------------
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Allow HTTP and optional SSH"
  vpc_id      = data.aws_vpc.default.id

  # HTTP open to the world (IPv4 + IPv6)
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # SSH only if a CIDR is provided (kept closed by default)
  dynamic "ingress" {
    for_each = var.ssh_ingress_cidr == "" ? [] : [var.ssh_ingress_cidr]
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Egress: allow all outbound traffic
  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-sg"
  }
}

# -----------------------------------------------------------------------------
# EC2 instance
# -----------------------------------------------------------------------------
resource "aws_instance" "app" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.cw_agent_profile.name
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null

  # Cloud-init (Bash). Receives the site ZIP as Base64 (decoded on instance).
  # NOTE: Ensure your user_data.sh escapes any Bash ${...} with $${...}
  # to avoid Terraform interpolation conflicts.
  user_data = templatefile("${path.module}/user_data.sh", {
    PROJECT_NAME = var.project_name
    ENVIRONMENT  = var.environment
    ARCHIVE_B64  = filebase64(data.archive_file.site_zip.output_path)
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}