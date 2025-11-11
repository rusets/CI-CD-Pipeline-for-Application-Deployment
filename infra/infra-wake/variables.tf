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
  description = "Optional explicit EC2 instance ID; if null, resolve by tag"
  type        = string
  default     = null
}

variable "instance_tag_key" {
  description = "EC2 tag key used to locate the instance when instance_id is null"
  type        = string
  default     = "Name"
}

variable "instance_tag_value" {
  description = "EC2 tag value used to locate the instance when instance_id is null"
  type        = string
  default     = "ruslan-aws-dev"
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
