# -----------------------------------------------------------------------------
# Input variables
# -----------------------------------------------------------------------------
variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Проект (общий префикс ресурсов)"
  default     = "ruslan-aws"
  validation {
    condition     = length(var.project_name) > 0
    error_message = "project_name не должен быть пустым."
  }
}

variable "environment" {
  type        = string
  description = "Окружение: dev или prod"
  default     = "dev"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment должен быть dev или prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Optional EC2 key pair name (leave empty to disable SSH)"
  type        = string
  default     = ""
}

variable "ssh_ingress_cidr" {
  description = "Optional CIDR allowed to SSH (e.g. 1.2.3.4/32). Leave empty to disable SSH."
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Where to send CloudWatch alarms"
  type        = string
}