output "ecs_cluster_id" {
  value = aws_ecs_cluster.this.id
}
output "ecs_service_id" {
  value = aws_ecs_service.sonarqube.id
}
output "ecs_service_arn" {
  value = aws_ecs_service.sonarqube.arn
}
output "ecs_task_role_arn" {
  value = aws_iam_role.task.arn
}
output "security_group_id" {
  value = aws_security_group.ecs.id
}
