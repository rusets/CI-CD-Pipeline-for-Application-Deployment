# -----------------------------------------------------------------------------
# AWS Provider
# -----------------------------------------------------------------------------
provider "aws" {
  # Region is passed in via variable
  region = var.region

  # Default tags applied to all resources created by this provider
  default_tags {
    tags = {
      Project     = var.project_name # Project name for grouping
      Environment = var.environment  # Environment (dev, prod, etc.)
      ManagedBy   = "terraform"      # Tag to indicate IaC ownership
    }
  }
}