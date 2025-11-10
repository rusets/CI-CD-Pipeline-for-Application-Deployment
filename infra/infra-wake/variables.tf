############################################
# Input variables
############################################
variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project prefix for tagging"
  type        = string
  default     = "ruslan-aws"
}

variable "environment" {
  description = "Environment name (dev|prod)"
  type        = string
  default     = "dev"
}

variable "instance_id" {
  description = "Existing EC2 instance to wake/sleep (i-xxxxxxxxxxxxxx)"
  type        = string
}

variable "idle_minutes" {
  description = "Minutes of inactivity before auto-sleep"
  type        = number
  default     = 15
}

variable "ssm_param_last_wake" {
  description = "SSM parameter path to store last wake timestamp"
  type        = string
  default     = "/ci-wake/last_wake"
}

