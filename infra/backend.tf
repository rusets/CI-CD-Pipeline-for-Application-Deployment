terraform {
  backend "s3" {
    # S3 bucket to store the remote Terraform state
    bucket = "tf-state-097635932419-us-east-1"

    # Path (key) inside the bucket where the state file will be stored
    key = "ci-cd-pipeline-aws/infra/terraform.tfstate"

    # AWS region of the S3 bucket
    region = "us-east-1"

    # DynamoDB table for state locking and consistency checks
    dynamodb_table = "terraform-locks"

    # Enable server-side encryption of the state file in S3
    encrypt = true
  }
}