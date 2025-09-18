# -----------------------------------------------------------------------------
# Input variables
# -----------------------------------------------------------------------------
variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name tag and on-page label"
  type        = string
  default     = "neon-aurora"
}

variable "environment" {
  description = "Environment label"
  type        = string
  default     = "dev"
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