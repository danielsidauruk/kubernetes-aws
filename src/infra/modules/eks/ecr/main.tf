resource "aws_ecr_repository" "main" {
  name                 = "ecr-${var.project_name}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1,
      description  = "Expire untagged images older than 30 days"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 30
      }
      action = {
        type = "expire"
      }
    }]
  })
}
