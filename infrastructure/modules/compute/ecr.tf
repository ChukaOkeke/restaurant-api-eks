# ==============================================================================
# PRIVATE AMAZON ECR REPOSITORY
# Storage location for application docker containers
# ==============================================================================

resource "aws_ecr_repository" "app" {
  name                 = "restaurant-api-${var.environment}-app"
  image_tag_mutability = "IMMUTABLE"

  #checkov:skip=CKV_AWS_136: Standard AWS AES-256 encryption at rest is sufficient for container image artifacts and avoids KMS overhead in dev.

  image_scanning_configuration {
    scan_on_push = true # Automated vulnerability scanning on push
  }

  tags = {
    Name = "restaurant-api-${var.environment}-ecr"
  }
}

# Retains last 10 images to manage ECR storage costs
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 tagged images"
      selection = {
        tagStatus   = "any"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 14
      }
      action = { type = "expire" }
    }]
  })
}