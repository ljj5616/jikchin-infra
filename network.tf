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

# RDS subnet groups require subnets in at least two availability zones.
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "database_second" {
  vpc_id                  = aws_vpc.server.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = [for az in data.aws_availability_zones.available.names : az if az != aws_subnet.server.availability_zone][0]
  map_public_ip_on_launch = false

  tags = {
    Name    = "jikchin-database-public-second"
    Project = "jikchin"
  }
}

resource "aws_route_table_association" "database_second" {
  subnet_id      = aws_subnet.database_second.id
  route_table_id = aws_route_table.server.id
}

