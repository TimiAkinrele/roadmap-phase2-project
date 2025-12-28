terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # Industry Standard for Secure IaC Random Password Generation
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}