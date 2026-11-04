variable "aws_region" {
  description = "AWS region for the avatar bucket."
  type        = string
  default     = "ap-northeast-2"
}

variable "avatar_bucket_name" {
  description = "Globally unique name of the new S3 avatar bucket."
  type        = string
}
