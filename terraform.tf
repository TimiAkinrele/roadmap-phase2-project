# TERRAFORM.TF
# Tells terraform what provider we want to use

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}