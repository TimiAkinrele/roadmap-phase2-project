terraform {
  backend "s3" {
    bucket         = "terraform-state-devsecops-admin-timi-unique-1"
    dynamodb_table = "terraform-state-locks"
    key            = "global/s3/terraform.tfstate" # where i want to store it
    region         = "us-east-1"
    encrypt        = true
  }
}