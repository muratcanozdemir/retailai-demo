variable "zone_name" {
  type        = string
  description = "Private DNS zone name, e.g. internal.company.com"
}

variable "record_name" {
  type        = string
  description = "Record to create (e.g. sonarqube.internal.company.com)"
}

variable "alb_dns_name" {
  type        = string
  description = "ALB DNS name output"
}

variable "alb_zone_id" {
  type        = string
  description = "ALB Zone ID output"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for associating private hosted zone"
}
