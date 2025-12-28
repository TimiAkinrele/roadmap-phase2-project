variable "vpc_id" {
  description = "The ID of my VPC where security groups will be created"
  type        = string
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/prod)"
  type        = string
}