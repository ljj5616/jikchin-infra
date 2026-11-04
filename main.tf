provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "avatars" {
  bucket = var.avatar_bucket_name

  tags = {
    Project = "jikchin"
    Purpose = "profile-avatars"
  }
}

resource "aws_s3_bucket_public_access_block" "avatars" {
  bucket = aws_s3_bucket.avatars.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "avatars" {
  bucket = aws_s3_bucket.avatars.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
