# 1. Naming & Governance

# How will I know which ALB belongs to this project, which is Test or Prod? Tagging solves this.
variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

# 2. Network Placement

# AWS requires me to specify which VPC this target group belongs to, what network am I in? VPC ID solves this
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

# Internet-Facing ALB's sit on the Public Edge of the network, which subnets have an IGW attached? A list of Public Subnet IDs
variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

# When launching Fargate containers, where should they run physically, public/ private zone? A list of subnets for the tasks
variable "app_subnet_ids" {
  description = "List of subnet IDs where ECS tasks will run"
  type        = list(string)
}

# 3. Security & Access

# A previously created SG/firewall attached to my ALB allows port 80, how do i tell this module to use that one? The ID of the SG allowing HTTP/HTTPS
variable "alb_sg_id" {
  description = "Security Group ID for the ALB"
  type        = string
}

# A previously created SG/firewall attached to ECS tasks, I need to use this? The ID of the SG allowing Port 5000
variable "ecs_sg_id" {
  description = "Security Group ID for the ECS Tasks"
  type        = string
}

# My container needs to login to the DB, the password is NOT in plaintext, I need to give the IAM Role perms to read this previously made Secret? The Amazon Resource Number (ARN) of the secret created in the DB module is used in the IAM policy
variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret for DB creds"
  type        = string
}

# 4. Application Configuration

# My Python app is starting, it needs the address of the DB server, how do i pass this info to the container? Environment Variables inside the ECS Task Definition. The Docker container reads os.environ['DB_HOST'] to find the DB
variable "db_endpoint" {
  description = "The RDS Endpoint URL"
  type        = string
}

variable "db_name" {
  description = "The database name"
  type        = string
}

variable "db_username" {
  description = "The database username"
  type        = string
}

# ECS is an orchestrator, but what software am I actually orchestrating, which docker image am i pulling from the docker registry? The String pointing to my image registry
variable "container_image" {
  description = "Docker image to run"
  type        = string
  default     = "public.ecr.aws/docker/library/httpd:latest" # Placeholder (Apache)
}