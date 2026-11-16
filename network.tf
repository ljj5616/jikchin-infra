resource "aws_vpc" "server" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "jikchin-server"
    Project = "jikchin"
  }
}

resource "aws_subnet" "server" {
  vpc_id                  = aws_vpc.server.id
  cidr_block              = "10.20.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name    = "jikchin-server-public"
    Project = "jikchin"
  }
}

resource "aws_internet_gateway" "server" {
  vpc_id = aws_vpc.server.id

  tags = {
    Name    = "jikchin-server"
    Project = "jikchin"
  }
}

resource "aws_route_table" "server" {
  vpc_id = aws_vpc.server.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.server.id
  }

  tags = {
    Name    = "jikchin-server-public"
    Project = "jikchin"
  }
}

resource "aws_route_table_association" "server" {
  subnet_id      = aws_subnet.server.id
  route_table_id = aws_route_table.server.id
}

