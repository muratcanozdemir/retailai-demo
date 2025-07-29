variable "vpc_id" {
  type = string
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "db_name" {
  type = string
}
variable "instance_class" {
  type    = string
  default = "db.r6g.large"
}
variable "engine_version" {
  type    = string
  default = "15.5"
}
variable "backup_retention_period" {
  type    = number
  default = 7
}
variable "iam_auth_enabled" {
  type    = bool
  default = false
}

variable "db_master_username" {
  type    = string
  default = "admin"
}
variable "rotate_password" {
  type    = bool
  default = true
}
variable "rotation_days" {
  type    = number
  default = 30
}

variable "kms_key_id" {
  type        = string
  description = "CMK KMS given to us"
}