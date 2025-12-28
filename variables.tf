# VARIABLES.TF
# Defines what values are expected, not neccessarily our actual values

variable "aws_region" {
  description = "AWS region to deploy my resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "AWS Project Name (tagging and naming)"
  type        = string
  default     = "poll-app"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16" # Provides 2^16 (2^32-CIDR val = 65,536) IP address range for our classless interdomain routing block

}