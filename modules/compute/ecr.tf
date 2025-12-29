# Creating an ECR repository
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"

  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-repo"
  }
}

# Outputting the repo URL for planned CI/CD pipeline usage
output "repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "The URL of the ECR Repository"
}

