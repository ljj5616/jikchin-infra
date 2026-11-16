data "aws_partition" "current" {}

data "aws_iam_policy_document" "server_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "server" {
  name               = "jikchin-server"
  assume_role_policy = data.aws_iam_policy_document.server_assume_role.json

  tags = {
    Project = "jikchin"
  }
}

resource "aws_iam_role_policy_attachment" "server_ssm" {
  role       = aws_iam_role.server.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "server_avatar_upload" {
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.avatars.arn}/avatars/users/*"]
  }
}

resource "aws_iam_role_policy" "server_avatar_upload" {
  name   = "avatar-upload"
  role   = aws_iam_role.server.id
  policy = data.aws_iam_policy_document.server_avatar_upload.json
}

data "aws_iam_policy_document" "server_ecr_pull" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [aws_ecr_repository.app.arn]
  }
}

resource "aws_iam_role_policy" "server_ecr_pull" {
  name   = "ecr-pull"
  role   = aws_iam_role.server.id
  policy = data.aws_iam_policy_document.server_ecr_pull.json
}

resource "aws_iam_instance_profile" "server" {
  name = "jikchin-server"
  role = aws_iam_role.server.name
}

