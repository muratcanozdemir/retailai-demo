output "efs_id" {
  value = aws_efs_file_system.this.id
}
output "efs_access_point_arn" {
  value = aws_efs_access_point.sonarqube.arn
}
output "efs_security_group_id" {
  value = aws_security_group.efs.id
}
output "datasync_security_group_id" {
  value = aws_security_group.datasync.id
}
output "datasync_task_arn" {
  value = aws_datasync_task.s3_to_efs_plugins.arn
}
