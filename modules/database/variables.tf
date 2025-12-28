variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to attach to the RDS instance"
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group (Private Subnets)"
  type        = list(string)
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "polldb"
}

variable "db_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "root"
}