# MAIN.TF
# In the same manner as functions in pythons, the below module requires 3 arguments
# EXAMPLE:
# create_networking(
# vpc_cidr = "10.0.0.0/16"
# project_name = "polling-application"
# environment = "dev"
# )
module "networking" {
  source = "./modules/networking"

  vpc_cidr     = var.vpc_cidr
  project_name = var.project_name
  environment  = var.environment
}

module "security" {
  source = "./modules/security"

  vpc_id       = module.networking.vpc_id
  project_name = var.project_name
  environment  = var.environment

}

module "database" {
  source = "./modules/database"

  # Dependency Injection -> Network
  subnet_ids = module.networking.private_subnet_ids # Required list of pricate subnet IDs so the DB is hidden from the internet

  # Dependency Injection -> Security 
  vpc_security_group_ids = [module.security.rds_sg_id] # Required RDS Security Group ID that expects a list, so its wrapped in []
  project_name           = var.project_name

  db_username = "root"
}

module "compute" {
  source = "./modules/compute"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id

  # Network Injection:
  # The ALB lives in the Public Subnets.
  public_subnet_ids = module.networking.public_subnet_ids

  # For my "Lean" architecture, I'm also running the App in Public Subnets
  # (to avoid paying for a NAT Gateway).
  app_subnet_ids = module.networking.public_subnet_ids

  # Security Injection
  alb_sg_id = module.security.alb_sg_id
  ecs_sg_id = module.security.ecs_tasks_sg_id

  # Database Injection:
  # The app needs to know WHERE the DB is and WHICH secret to read.
  db_endpoint   = module.database.db_endpoint
  db_name       = module.database.db_name
  db_secret_arn = module.database.db_secret_arn
  db_username   = "root" # Matches the default in database module

  # The Docker Image:
  # This defaults to "httpd" in the module variables, but we can override it here
  # to point to your real app if you are ready.
  container_image = "timiakinrele1/roadmap-phase1-project:v2"
}

module "github-oidc" {
  source = "./modules/github-oidc"

  project_name = var.project_name
  github_repo = "TimiAkinrele/roadmap-phase2-project"
}