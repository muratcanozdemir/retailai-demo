variable "cluster_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "private_subnet_ids" {
  type = list(string)
}

# ALB target group for service registration
variable "alb_target_group_arn" {
  type = string
}
variable "alb_security_group_id" {
  type = string
}

# EFS for persistent storage (plugins, data, etc)
variable "efs_id" {
  type = string
}
variable "efs_access_point_arn" {
  type = string
}

# RDS (database connection)
variable "db_endpoint" {
  type = string
}
variable "db_name" {
  type = string
}
variable "db_user" {
  type = string
}
variable "db_secret_arn" {
  type = string
}
variable "db_iam_auth" {
  type = bool
}
variable "rds_security_group_id" {
  type = string
}

# SonarQube image/tag
variable "image" {
  type = string
}
variable "container_port" {
  type    = number
  default = 9000
}
variable "cpu" {
  type    = number
  default = 4096
}
variable "memory" {
  type    = number
  default = 8192
}
variable "desired_count" {
  type    = number
  default = 1
}

variable "extra_env" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}