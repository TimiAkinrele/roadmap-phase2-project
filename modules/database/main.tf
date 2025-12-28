# 1. Create a Random Password using "hashicorp/random provider"
resource "random_password" "db_password" {
  length  = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>?" 
}

# 2. Store the Password in AWS Secrets Manager - timestamped for secure logging practices

# Create the Vault
resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.project_name}-db-password-${formatdate("YYYYMMDDhhmmss", timestamp())}-v2"
  description = "RDS master password for ${var.project_name}"

  # No. Days before AWS can force delete the password, need immediately deletion for my lab, typically 7 days to prevent accidental data loss
  recovery_window_in_days = 0
}

# Store the password in the Vault
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result # my randomly IaC generated password
}


# 3. Create the Subnet Group
resource "aws_db_subnet_group" "db_subnet_g" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# 4. Create the RDS Database Instance
resource "aws_db_instance" "rds_db" {
  identifier        = "${var.project_name}-db"
  allocated_storage = 20 # 20GB Free Tier limit :(
  db_name           = var.db_name
  username          = var.db_username
  password          = random_password.db_password.result

  engine         = "postgres"
  engine_version = "16.3"
  instance_class = "db.t3.micro"
  storage_type   = "gp2"

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_g.name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = false # Default is false, but re-iterated for clarity (SECURE PRACTICES)
  multi_az               = false # Set to false to avoid exceeding free-tier cost, but True = High Availability which is a MUST for a db instance.

  skip_final_snapshot = true # Important for "terraform destroy" purposes

  apply_immediately = true # for quick fixes currently




}