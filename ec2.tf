# AWS maintains this parameter for the latest x86_64 Amazon Linux 2023 AMI.
data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "server" {
  name        = "jikchin-server"
  description = "Public web traffic for the Jikchin server; administration uses SSM."
  vpc_id      = aws_vpc.server.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "jikchin-server"
    Project = "jikchin"
  }
}

resource "aws_instance" "server" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = var.server_instance_type
  subnet_id                   = aws_subnet.server.id
  vpc_security_group_ids      = [aws_security_group.server.id]
  iam_instance_profile        = aws_iam_instance_profile.server.name
  associate_public_ip_address = true

  # A newer public AMI must not replace the existing server on an unrelated apply.
  lifecycle {
    ignore_changes = [ami]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.server_root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name    = "jikchin-server"
    Project = "jikchin"
  }
}

resource "aws_eip" "server" {
  domain   = "vpc"
  instance = aws_instance.server.id

  depends_on = [aws_internet_gateway.server]

  tags = {
    Name    = "jikchin-server"
    Project = "jikchin"
  }
}
