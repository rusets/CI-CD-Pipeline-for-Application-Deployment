############################################
# Terraform Backend — shared S3 + DynamoDB
############################################
terraform {
  backend "s3" {
    bucket         = "tf-state-097635932419-us-east-1"
    key            = "ci-cd-pipeline-aws/infra-wake/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
