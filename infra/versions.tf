# -----------------------------------------------------------------------------
# Terraform and provider version constraints
# -----------------------------------------------------------------------------
terraform {
  # Require at least Terraform 1.6.0
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40" # AWS provider version
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.0" # Used for packaging local files into ZIP
    }
  }
}