variable "aws_region" {
  description = "AWS region for the avatar bucket."
  type        = string
  default     = "ap-northeast-2"
}

variable "avatar_bucket_name" {
  description = "Globally unique name of the new S3 avatar bucket."
  type        = string
}

variable "server_instance_type" {
  description = "EC2 instance type for the server (x86_64)."
  type        = string
  default     = "t3.small"
}

variable "server_root_volume_size" {
  description = "Size in GiB of the server's gp3 root volume."
  type        = number
  default     = 20

  validation {
    condition     = var.server_root_volume_size >= 20 && var.server_root_volume_size == floor(var.server_root_volume_size)
    error_message = "The root volume size must be a whole number of at least 20 GiB."
  }
}
