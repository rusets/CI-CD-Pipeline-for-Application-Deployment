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
  description = "Project name (used as a prefix for all resources)"
  default     = "ruslan-aws"

  validation {
    condition     = length(var.project_name) > 0
    error_message = "project_name must not be empty."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment: dev or prod"
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either 'dev' or 'prod'."
  }
}

variable "instance_type" {
  description = "EC2 instance type to use"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Optional EC2 key pair name (leave empty to disable SSH access)"
  type        = string
  default     = ""
}

variable "ssh_ingress_cidr" {
  description = "Optional CIDR block allowed for SSH access (e.g. 1.2.3.4/32). Leave empty to disable SSH."
  type        = string
  default     = ""
}

variable "alert_email" {
  type        = string
  default     = ""
  description = "Email address to receive CloudWatch alarms. Leave empty to skip SNS subscription."
}