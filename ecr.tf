resource "aws_ecr_repository" "app" {
  name                 = "jikchin-app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = "jikchin"
  }
}
