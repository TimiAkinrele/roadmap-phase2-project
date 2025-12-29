# 1. Create the OIDC Provider for GitHub (public/standard information)
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # handled automatically for aws, but good for explicability  
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]

}

# 2. Generate the Trust Policy Document using AWS template
data "aws_iam_policy_document" "github_trust_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Condition 1: Audience Check (Security Best Practice) 
    # Ensure the token is intended for AWS
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Condition 2: Subject Check (Repository Lock)
    # Ensure the request comes from YOUR specific repo
    # We use StringLike with '*' to allow any branch (main, feature, tags)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}


# 3. Create the IAM Role
resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_trust_policy.json
}

# 4. Attach Custom "Least Privilege" Policy Access for Terraform
# I chose to avoid giving full admin access, but rather explicitly list the services Terraform needs

resource "aws_iam_policy" "terraform_permissions" {
  name        = "${var.project_name}-terraform-policy"
  description = "Permissions for GitHub Actions to deploy infrastructure (will be updated with more perms, if needed)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Networking and Compute Perms
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "ecs:*",
          "ecr:*"
        ]
        Resource = "*"
      },
      # DB and Storage Perms
      {
        Effect = "Allow"
        Action = [
          "rds:*",
          "s3:*",
          "dynamodb:*",
          "secretsmanager:*",
          "kms:*"
        ]
        Resource = "*"
      },
      # IAM Management (Restricted Perms) since Terraform needs to create roles for ECS
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies"
        ]
        Resource = "*"
      },
      # Logging and Monitoring
      {
        Effect = "Allow"
        Action = [
          "logs:*",
          "cloudwatch:*"
        ]
        Resource = "*"
      }
    ]
  })

}

# 5. Attach the Custom Policy to github actions role
resource "aws_iam_role_policy_attachment" "terraform" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.terraform_permissions.arn
}