variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "efs_name" {
  type    = string
  default = "sonarqube-efs"
}

variable "efs_performance_mode" {
  type    = string
  default = "generalPurpose"
}

variable "efs_throughput_mode" {
  type    = string
  default = "bursting"
}

variable "sonarqube_uid" {
  type    = number
  default = 1000
}

variable "sonarqube_gid" {
  type    = number
  default = 1000
}

# DataSync config
variable "s3_bucket_arn" {
  type = string
}
variable "s3_subdirectory" {
  type    = string
  default = ""
}
variable "datasync_subnet_id" {
  type        = string
  description = "A private subnet ID with S3/EFS access for DataSync ENI"
}

variable "kms_key_id" {
  type        = string
  description = "CMK KMS given to us"
}