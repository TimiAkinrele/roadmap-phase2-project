output "website_url" {
  description = "The URL of the Load Balancer"
  value       = "http://${module.compute.alb_dns_name}"
}

# Outputting the repo URL for planned CI/CD pipeline usage
output "repository_url" {
  value       = module.compute.repository_url
  description = "The URL of the ECR repository"
}

output "github_role_arn" {
  value       = module.github-oidc.role_arn
  description = "ARN of the IAM role for github actions"
}