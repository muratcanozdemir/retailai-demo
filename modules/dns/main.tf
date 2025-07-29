# If your landing zone manages the hosted zone, use a data source:
# data "aws_route53_zone" "internal" {
#   name         = var.zone_name
#   private_zone = true
#   vpc_id       = var.vpc_id
# }

# Else, create a hosted zone here:
resource "aws_route53_zone" "this" {
  name = var.zone_name
  vpc {
    vpc_id = var.vpc_id
  }
}

# Use the right zone_id (from data or resource)
locals {
  zone_id = try(data.aws_route53_zone.internal.zone_id, aws_route53_zone.this.zone_id)
}

resource "aws_route53_record" "sonarqube" {
  zone_id = local.zone_id
  name    = var.record_name
  type    = "A"
  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
  ttl = 60
}
