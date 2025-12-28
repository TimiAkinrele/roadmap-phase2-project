# PROVIDER.TF
# Defines aws, with these global settings

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Team-Timi"
    }
  }
}