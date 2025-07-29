data "aws_iam_policy_document" "execution_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${var.cluster_name}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.execution_assume.json
  tags               = { Name = "${var.cluster_name}-ecs-execution" }
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# You may attach additional managed policies if you pull from private ECR, SSM, or want to write to extra logs.

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_inline" {
  statement {
    sid       = "AllowGetDBSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }

  statement {
    sid     = "AllowRDSIAMAuth"
    actions = ["rds-db:connect"]
    resources = [
      "arn:aws:rds-db:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.rds_cluster_resource_id}/${var.sonarqube_db_user}"
    ]
  }

  statement {
    sid = "AllowEFSClientMount"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]
    resources = [var.efs_access_point_arn]
  }
}

resource "aws_iam_role" "task" {
  name               = "${var.cluster_name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  tags               = { Name = "${var.cluster_name}-ecs-task" }
}

resource "aws_iam_role_policy" "task_inline" {
  name   = "${var.cluster_name}-ecs-task-inline"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_inline.json
}
