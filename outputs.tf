output "avatar_bucket_name" {
  description = "Name of the avatar bucket."
  value       = aws_s3_bucket.avatars.id
}

output "avatar_bucket_arn" {
  description = "ARN of the avatar bucket."
  value       = aws_s3_bucket.avatars.arn
}
