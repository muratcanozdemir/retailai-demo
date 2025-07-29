variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "sonarqube_acm_cert_arn" {
  type        = string
  description = "ACM cert for SonarQube internal ALB"
}

variable "alb_name" {
  type = string
}

variable "listener_port" {
  type    = number
  default = 443
} # SonarQube default

variable "health_check_path" {
  type    = string
  default = "/api/system/health"
}

variable "alb_protocol" {
  type    = string
  default = "HTTPS"
} # Use HTTPS with TLS for real prod (cert mgmt required)

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/8"] # Or restrict to jump/VPN subnets as needed
  description = "CIDRs allowed to access ALB"
}

variable "access_logs_bucket" {
  type        = string
  default     = "sq_access_logs"
  description = "Cenral LB access logs bucket"
}