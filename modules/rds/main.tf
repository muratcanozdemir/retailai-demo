resource "aws_security_group" "rds" {
  name        = "${var.db_name}-rds-sg"
  vpc_id      = var.vpc_id
  description = "Allow Postgres from ECS tasks"
  egress {
    from_port   = 443
    to_port     = 443
    description = "Some description"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.db_name}-rds-sg" }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.db_name}-rds-subnet"
  subnet_ids = var.private_subnet_ids
}

# Use Secrets Manager for password if not passed in (recommended)
resource "random_password" "db" {
  length  = 24
  special = true
}

resource "aws_secretsmanager_secret" "db" {
  name        = "${var.db_name}-db-credentials"
  kms_key_id  = var.kms_key_id
  description = "Aurora credentials for SonarQube"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_master_username
    password = random_password.db.result
  })
}

resource "aws_rds_cluster" "this" {
  cluster_identifier      = "${var.db_name}-aurora"
  engine                  = "aurora-postgresql"
  engine_version          = var.engine_version
  master_username         = var.db_master_username
  master_password         = random_password.db.result
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  backup_retention_period = var.backup_retention_period
  storage_encrypted       = true
  skip_final_snapshot     = false
  apply_immediately       = false

  iam_database_authentication_enabled = var.iam_auth_enabled

  enabled_cloudwatch_logs_exports = ["postgresql", "audit"]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name

  tags = {
    Name = "${var.db_name}-aurora-cluster"
  }
}

resource "aws_rds_cluster_instance" "this" {
  count                = 2
  identifier           = "${var.db_name}-aurora-instance-${count.index + 1}"
  cluster_identifier   = aws_rds_cluster.this.id
  instance_class       = var.instance_class
  engine               = aws_rds_cluster.this.engine
  engine_version       = aws_rds_cluster.this.engine_version
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.this.name
  tags = {
    Name = "${var.db_name}-aurora-instance"
  }
}

resource "aws_secretsmanager_rotation" "lambda" {
  rotation_lambda_name = "${var.db_name}-rds-rotation"
  hosted_rotation_lambda {
    rotation_type          = "PostgreSQLSingleUser"
    vpc_subnet_ids         = var.private_subnet_ids
    vpc_security_group_ids = [aws_security_group.rds.id]
  }
}

resource "aws_secretsmanager_secret_rotation" "db" {
  count               = var.rotate_password ? 1 : 0
  secret_id           = aws_secretsmanager_secret.db.id
  rotation_lambda_arn = aws_secretsmanager_rotation.lambda.arn
  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}
