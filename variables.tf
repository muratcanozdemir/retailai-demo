variable "aws_region" {
  type        = string
  description = "AWS region for all resources"
  default     = "eu-central-1"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where all resources are provisioned"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for ECS, ALB, EFS, RDS, etc."
}

variable "sonarqube_acm_cert_arn" {
  type        = string
  description = "ACM certificate ARN for ALB"
}

variable "plugins_bucket_arn" {
  type        = string
  description = "S3 bucket ARN for SonarQube plugins"
}

variable "kms_key_id" {
  type        = string
  description = "CMK KMS given to us"
}
# Add any other global variables you reference at the top level or need in multiple modules
