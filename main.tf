module "efs" {
  source             = "./modules/efs-datasync"
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  kms_key_id         = var.kms_key_id
}

module "rds" {
  source             = "./modules/rds"
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids

  db_name            = "sonarqube"
  db_master_username = "admin"
  # No password needed—module generates/rotates it

  instance_class = "db.t3.medium" # or as required
  engine_version = "15.5"         # or as required

  iam_auth_enabled = false # toggle if you want IAM auth
  rotate_password  = true  # enable rotation
  rotation_days    = 30    # rotation interval

  backup_retention_period = 7 # as needed
  kms_key_id              = var.kms_key_id
}

# For ECS, you wire these outputs:
locals {
  db_endpoint      = module.rds.cluster_endpoint
  db_name          = module.rds.db_name
  db_user          = module.rds.db_master_username
  db_secret_arn    = module.rds.db_secret_arn
  iam_auth_enabled = module.rds.iam_auth_enabled
  db_sg_id         = module.rds.security_group_id
}

module "alb" {
  source              = "./modules/alb"
  vpc_id              = var.vpc_id
  private_subnet_ids  = var.private_subnet_ids
  alb_name            = "sonarqube-internal"
  listener_port       = 443
  alb_protocol        = "HTTPS"
  certificate_arn     = var.sonarqube_acm_cert_arn
  allowed_cidr_blocks = ["10.20.0.0/16"] # Or wherever your expected sonarscanners live             # Internal net
  health_check_path   = "/api/system/health"
}

module "ecs" {
  source                = "./modules/ecs"
  cluster_name          = "sonarqube"
  vpc_id                = var.vpc_id
  private_subnet_ids    = var.private_subnet_ids
  alb_target_group_arn  = module.alb.target_group_arn
  alb_security_group_id = module.alb.alb_security_group_id
  efs_id                = module.efs_datasync.efs_id
  efs_access_point_arn  = module.efs_datasync.efs_access_point_arn
  db_endpoint           = module.rds.cluster_endpoint
  db_name               = module.rds.db_name
  db_user               = module.rds.db_master_username
  db_secret_arn         = module.rds.db_secret_arn
  db_iam_auth           = module.rds.iam_auth_enabled
  rds_security_group_id = module.rds.security_group_id
  image                 = "sonarqube:9.9-enterprise"
  extra_env = [
    { name = "SONARQUBE_LICENSE", value = var.sonarqube_license }
    # other env as needed
  ]
}


module "dns" {
  source       = "./modules/dns"
  zone_name    = "internal.company.com"
  record_name  = "sonarqube.internal.company.com"
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
  vpc_id       = var.vpc_id
}


# Allow ECS tasks to access EFS NFS
resource "aws_security_group_rule" "efs_from_ecs" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = module.efs.efs_security_group_id
  source_security_group_id = module.ecs.ecs_security_group_id
  description              = "Allow NFS from ECS"
}

# Allow DataSync to access EFS NFS
resource "aws_security_group_rule" "efs_from_datasync" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = module.efs.efs_security_group_id
  source_security_group_id = module.datasync.datasync_security_group_id
  description              = "Allow NFS from DataSync"
}
