# Security Chain of Dependency ALB -> APP -> DB
# previously NGINX proxy -> Web App -> PostgreSQL DB

# Load Balancer (ALB) Security Group
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Controls access to the ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# Rule: Allow inbound traffic to HTTP (80) from Anywhere (IPv4) - will be permanently redirected to HTTPS connection later
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# Rule: Allow inbound traffic to HTTPS (443) from Anywhere (IPv4)
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Rule: Allow all Outbound Traffic
resource "aws_vpc_security_group_egress_rule" "alb_egress_all" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports

}

# ECS Tasks (APP) Security Group
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Allow inbound access from the ALB only"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-ecs-tasks-sg"
  }

}

# Rule: Allow Port 5000 ONLY from ALB Security Group
resource "aws_vpc_security_group_ingress_rule" "ecs_alb_ingress" {
  security_group_id            = aws_security_group.ecs_tasks_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id # CHAIN OF TRUST/1-WAY DEPENDENCY -> Referenced means that it requires Terraform to have created that SG first so that it can be associated with this resource
  from_port                    = 5000
  ip_protocol                  = "tcp"
  to_port                      = 5000
}

# Rule: Allow All Outbound Traffic
resource "aws_vpc_security_group_egress_rule" "ecs_egress_all" {
  security_group_id = aws_security_group.ecs_tasks_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# RDS (Database) Security Group
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow inbound access from ECS tasks only"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# Rule: Allow Port 5432 ONLY (PostgreSQL) from ECS Security Group
resource "aws_vpc_security_group_ingress_rule" "rds_ecs_ingress" {
  security_group_id            = aws_security_group.rds_sg.id
  referenced_security_group_id = aws_security_group.ecs_tasks_sg.id # CHAIN OF TRUST/1-WAY DEPENDENCY -> Referenced means that it requires Terraform to have created that SG first so that it can be associated with this resource
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

# Rule: Allow All Outbound Traffic (For Updates, Logs, Backups) - typically this would be locked down for the places it needs (e.g., S3, CloudWatch, and the app Subnet)
resource "aws_vpc_security_group_egress_rule" "rds_egress_all" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}