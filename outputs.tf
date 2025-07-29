# ALB
output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "DNS name of the internal ALB"
}
output "alb_zone_id" {
  value       = module.alb.alb_zone_id
  description = "Zone ID for the ALB (useful for Route53 aliasing)"
}

# ECS
output "ecs_service_arn" {
  value       = module.ecs.ecs_service_arn
  description = "ARN of the SonarQube ECS service"
}
output "ecs_cluster_id" {
  value       = module.ecs.ecs_cluster_id
  description = "ECS cluster ID for SonarQube"
}
output "ecs_task_role_arn" {
  value       = module.ecs.ecs_task_role_arn
  description = "IAM role for ECS tasks (used for DB/Secrets access)"
}

# RDS
output "rds_endpoint" {
  value       = module.rds.cluster_endpoint
  description = "Primary endpoint of the RDS Aurora cluster"
}
output "rds_reader_endpoint" {
  value       = module.rds.reader_endpoint
  description = "Read-only endpoint for the RDS Aurora cluster"
}
output "rds_db_secret_arn" {
  value       = module.rds.db_secret_arn
  description = "Secrets Manager ARN for DB credentials"
}
output "rds_security_group_id" {
  value       = module.rds.security_group_id
  description = "Security group for RDS cluster"
}

# EFS + DataSync
output "efs_id" {
  value       = module.efs_datasync.efs_id
  description = "EFS file system ID"
}
output "efs_access_point_arn" {
  value       = module.efs_datasync.efs_access_point_arn
  description = "ARN of the SonarQube EFS access point"
}
output "efs_security_group_id" {
  value       = module.efs_datasync.efs_security_group_id
  description = "SG for EFS"
}
output "datasync_task_arn" {
  value       = module.efs_datasync.datasync_task_arn
  description = "ARN of the S3→EFS DataSync task"
}
output "datasync_security_group_id" {
  value       = module.efs_datasync.datasync_security_group_id
  description = "SG for DataSync agent/task"
}

# DNS
output "sonarqube_fqdn" {
  value       = module.dns.fqdn
  description = "Fully qualified internal DNS name for SonarQube"
}
