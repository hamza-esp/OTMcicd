# ECR Repository for Product Catalog Microservice
resource "aws_ecr_repository" "product_catalog" {
  name                 = "ecr-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "product-catalog"
    Service     = "product-catalog"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ECR Lifecycle Policy - Automatically delete old images to save storage costs
resource "aws_ecr_lifecycle_policy" "product_catalog_policy" {
  repository = aws_ecr_repository.product_catalog.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# IAM Policy for GitHub Actions to push to ECR - 
resource "aws_iam_policy" "github_ecr_push_policy" {
  name        = "GitHubActionsECRPushPolicy"
  description = "Policy for GitHub Actions to push Docker images to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetAuthorizationToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = aws_ecr_repository.product_catalog.arn
      }
    ]
  })
}

# IAM User for GitHub Actions
resource "aws_iam_user" "github_actions_user" {
  name = "github-actions-ecr-user"

  tags = {
    Name      = "github-actions-ecr-user"
    Purpose   = "CI/CD for GitHub Actions"
    ManagedBy = "Terraform"
  }
}

# Attach the ECR push policy to the IAM user
resource "aws_iam_user_policy_attachment" "github_actions_ecr_attach" {
  user       = aws_iam_user.github_actions_user.name
  policy_arn = aws_iam_policy.github_ecr_push_policy.arn
}

# Create access keys for the IAM user (for GitHub Actions)
resource "aws_iam_access_key" "github_actions_key" {
  user = aws_iam_user.github_actions_user.name
}

# Outputs - You'll need these values for GitHub Actions secrets
output "ecr_repository_url" {
  value       = aws_ecr_repository. product_catalog.repository_url
  description = "The URL of the ECR repository for product-catalog"
}

output "ecr_repository_name" {
  value       = aws_ecr_repository.product_catalog.name
  description = "The name of the ECR repository"
}

output "ecr_repository_arn" {
  value       = aws_ecr_repository.product_catalog.arn
  description = "The ARN of the ECR repository"
}

output "ecr_registry_id" {
  value       = aws_ecr_repository. product_catalog.registry_id
  description = "The registry ID (AWS Account ID)"
}

output "github_actions_access_key_id" {
  value       = aws_iam_access_key.github_actions_key.id
  description = "Access Key ID for GitHub Actions (store this in GitHub secrets as AWS_ACCESS_KEY_ID)"
  sensitive   = true
}

output "github_actions_secret_access_key" {
  value       = aws_iam_access_key.github_actions_key. secret
  description = "Secret Access Key for GitHub Actions (store this in GitHub secrets as AWS_SECRET_ACCESS_KEY)"
  sensitive   = true
}

output "aws_region" {
  value       = var.region
  description = "AWS region where ECR repository is created"
}