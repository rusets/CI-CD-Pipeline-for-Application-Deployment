############################################
# Input Variables
############################################

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "ruslan-aws"

  validation {
    condition     = length(var.project_name) > 0
    error_message = "project_name must not be empty"
  }
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either 'dev' or 'prod'"
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Optional EC2 key pair name (leave empty to disable SSH access)"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email address for CloudWatch alarms (optional)"
  type        = string
  default     = ""
}

variable "reaper_function_name" {
  description = "Lambda function name for the reaper (e.g., ruslan-aws-dev-reaper)"
  type        = string
}

