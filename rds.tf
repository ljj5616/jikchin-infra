resource "aws_security_group" "database" {
  name        = "jikchin-mysql"
  description = "MySQL access for Jikchin and external MySQL clients."
  vpc_id      = aws_vpc.server.id

  ingress {
    description = "MySQL from IPv4 clients"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.database_allowed_ipv4_cidrs
  }

  tags = {
    Name    = "jikchin-mysql"
    Project = "jikchin"
  }
}

resource "aws_db_subnet_group" "database" {
  name       = "jikchin-mysql"
  subnet_ids = [aws_subnet.server.id, aws_subnet.database_second.id]

  tags = {
    Name    = "jikchin-mysql"
    Project = "jikchin"
  }
}

resource "aws_db_instance" "database" {
  identifier                  = "jikchin-mysql"
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = var.database_instance_class
  allocated_storage           = 20
  storage_type                = "gp3"
  storage_encrypted           = true
  db_name                     = "jikchin"
  username                    = "jikchin_admin"
  manage_master_user_password = true
  port                        = 3306

  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = true
  multi_az               = false

  backup_retention_period   = 7
  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "jikchin-mysql-final"

  depends_on = [
    aws_route_table_association.server,
    aws_route_table_association.database_second,
  ]

  tags = {
    Name    = "jikchin-mysql"
    Project = "jikchin"
  }
}
