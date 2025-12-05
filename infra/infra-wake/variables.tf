############################################
# Input variables
############################################
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project prefix"
  type        = string
  default     = "ruslan-aws"
}

variable "environment" {
  description = "Environment (dev|prod)"
  type        = string
  default     = "dev"
}

variable "instance_id" {
  description = "Optional explicit EC2 instance ID (overrides tag discovery)"
  type        = string
  default     = ""
}

variable "instance_tag_key" {
  description = "Tag key to discover EC2 when instance_id is empty"
  type        = string
  default     = "Name"
}

variable "instance_tag_value" {
  description = "Tag value to discover EC2 when instance_id is empty"
  type        = string
  default     = "ruslan-aws-dev"
}

variable "idle_minutes" {
  description = "Minutes of inactivity before auto-stop"
  type        = number
  default     = 15
}

variable "ssm_param_last_wake" {
  description = "SSM parameter to store last wake timestamp (e.g., /ci-wake/last_wake)"
  type        = string
  default     = "/ci-wake/last_wake"
}


############################################
# API Gateway custom domain name
############################################
variable "apigw_domain_name" {
  type        = string
  description = "Existing API Gateway v2 custom domain for ci-wake"
  default     = "api.ci-wake.online"
}
