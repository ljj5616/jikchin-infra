output "avatar_bucket_name" {
  description = "Name of the avatar bucket."
  value       = aws_s3_bucket.avatars.id
}

output "avatar_bucket_arn" {
  description = "ARN of the avatar bucket."
  value       = aws_s3_bucket.avatars.arn
}

output "server_instance_id" {
  description = "EC2 instance ID for Systems Manager sessions."
  value       = aws_instance.server.id
}

output "server_public_ip" {
  description = "Elastic IP address associated with the server."
  value       = aws_eip.server.public_ip
}
