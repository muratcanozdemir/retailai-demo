output "cluster_endpoint" {
  value = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  value = aws_rds_cluster.this.reader_endpoint
}

output "db_name" {
  value = var.db_name
}

output "db_master_username" {
  value = var.db_master_username
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "iam_auth_enabled" {
  value = var.iam_auth_enabled
}

output "security_group_id" {
  value = aws_security_group.rds.id
}
