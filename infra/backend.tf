terraform {
  backend "s3" {
    bucket         = "tf-state-097635932419-us-east-1" # ← твой бакет
    key            = "ci-cd-pipeline-aws/infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
