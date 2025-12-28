output "db_endpoint" {
  description = "The connection endpoint"
  value       = aws_db_instance.rds_db.address
}

output "db_secret_arn" {
  description = "The ARN of the secret storing the password"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_name" {
  value = aws_db_instance.rds_db.db_name
}