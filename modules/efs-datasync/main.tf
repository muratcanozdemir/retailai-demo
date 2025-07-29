# Security group for EFS (NFS)
resource "aws_security_group" "efs" {
  name        = "${var.efs_name}-efs-sg"
  vpc_id      = var.vpc_id
  description = "Allow NFS from ECS tasks and DataSync"
  # Only allow inbound from our other managed SGs (ECS, DataSync)
  ingress {
    description = "NFS from ECS/DataSync"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]
    # For now, allow from all private subnets. For stricter, wire up referencing ECS SG, see below.
    security_groups = [aws_security_group.datasync.arn, aws_security_group.efs.arn]
  }
  egress {
    from_port   = 443
    to_port     = 443
    description = "Some description"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.efs_name}-efs-sg" }
}

resource "aws_security_group" "datasync" {
  # checkov:skip=CKV2_AWS_5: Datasync will create this and attach to ENI once the job starts
  name        = "${var.efs_name}-datasync-sg"
  vpc_id      = var.vpc_id
  description = "Allow DataSync to EFS"
  egress {
    from_port   = 443
    to_port     = 443
    description = "Some description"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Update EFS SG ingress to allow from DataSync SG
resource "aws_security_group_rule" "efs_from_datasync" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs.id
  source_security_group_id = aws_security_group.datasync.id
  description              = "Allow NFS from DataSync"
}

resource "aws_efs_file_system" "this" {
  creation_token   = var.efs_name
  performance_mode = var.efs_performance_mode
  throughput_mode  = var.efs_throughput_mode
  encrypted        = true
  kms_key_id       = var.kms_key_id
  tags = {
    Name = var.efs_name
  }
}

resource "aws_efs_mount_target" "this" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "sonarqube" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    gid = var.sonarqube_gid
    uid = var.sonarqube_uid
  }

  root_directory {
    path = "/sonarqube"
    creation_info {
      owner_gid   = var.sonarqube_gid
      owner_uid   = var.sonarqube_uid
      permissions = "0755"
    }
  }
}

# DataSync location (EFS)
resource "aws_datasync_location_efs" "this" {
  ec2_config {
    security_group_arns = [aws_security_group.datasync.arn]
    subnet_arn          = "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/${var.private_subnet_ids[0]}"
  }
  efs_file_system_arn = aws_efs_file_system.this.arn
  access_point_arn    = aws_efs_access_point.sonarqube.arn
}

resource "aws_datasync_location_s3" "this" {
  s3_bucket_arn = var.s3_bucket_arn
  subdirectory  = var.s3_subdirectory
  # Use default DataSync IAM role or pass in as variable if using custom
}

resource "aws_datasync_task" "s3_to_efs_plugins" {
  source_location_arn      = aws_datasync_location_s3.this.arn
  destination_location_arn = aws_datasync_location_efs.this.arn
  name                     = "${var.efs_name}-plugin-sync"
  options {
    overwrite_mode = "ALWAYS"
    # tune as needed
  }
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
