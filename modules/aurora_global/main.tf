resource "aws_db_subnet_group" "primary" {
  provider   = aws.primary
  name       = "${var.name_prefix}-aurora-primary-subnet-group"
  subnet_ids = var.primary_db_subnet_ids
  tags       = merge(var.tags, { Name = "${var.name_prefix}-aurora-primary-subnet-group" })
}

resource "aws_db_subnet_group" "secondary" {
  provider   = aws.secondary
  name       = "${var.name_prefix}-aurora-secondary-subnet-group"
  subnet_ids = var.secondary_db_subnet_ids
  tags       = merge(var.tags, { Name = "${var.name_prefix}-aurora-secondary-subnet-group" })
}

resource "aws_rds_global_cluster" "this" {
  global_cluster_identifier = "${var.name_prefix}-global-aurora"
  engine                    = var.engine
  engine_version            = var.engine_version
  database_name             = var.database_name
  deletion_protection       = true
  storage_encrypted         = true
}

resource "aws_rds_cluster" "primary" {
  provider                  = aws.primary
  cluster_identifier        = "${var.name_prefix}-aurora-primary"
  engine                    = var.engine
  engine_mode               = "provisioned"
  engine_version            = var.engine_version
  global_cluster_identifier = aws_rds_global_cluster.this.id
  database_name             = var.database_name
  master_username           = var.master_username
  master_password           = var.master_password
  db_subnet_group_name      = aws_db_subnet_group.primary.name
  vpc_security_group_ids    = [var.primary_aurora_sg_id]
  backup_retention_period   = 7
  preferred_backup_window   = "02:00-03:00"
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name_prefix}-aurora-primary-final-snapshot"
  storage_encrypted         = true
  apply_immediately         = true
  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 4
  }
}

resource "aws_rds_cluster_instance" "primary" {
  provider                     = aws.primary
  identifier                   = "${var.name_prefix}-aurora-primary-instance-1"
  cluster_identifier           = aws_rds_cluster.primary.id
  instance_class               = "db.serverless"
  engine                       = aws_rds_cluster.primary.engine
  engine_version               = aws_rds_cluster.primary.engine_version
  db_subnet_group_name         = aws_db_subnet_group.primary.name
  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn
}

# IAM role for enhanced RDS monitoring
resource "aws_iam_role" "rds_monitoring" {
  provider = aws.primary
  name     = "${var.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  provider   = aws.primary
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# IAM role for enhanced monitoring on secondary
resource "aws_iam_role" "rds_monitoring_secondary" {
  provider = aws.secondary
  name     = "${var.name_prefix}-rds-monitoring-role-secondary"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_secondary" {
  provider   = aws.secondary
  role       = aws_iam_role.rds_monitoring_secondary.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_rds_cluster" "secondary" {
  provider                  = aws.secondary
  cluster_identifier        = "${var.name_prefix}-aurora-secondary"
  engine                    = var.engine
  engine_mode               = "provisioned"
  engine_version            = var.engine_version
  global_cluster_identifier = aws_rds_global_cluster.this.id
  db_subnet_group_name      = aws_db_subnet_group.secondary.name
  vpc_security_group_ids    = [var.secondary_aurora_sg_id]
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name_prefix}-aurora-secondary-final-snapshot"
  storage_encrypted         = true
  apply_immediately         = true
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 4
  }
}

resource "aws_rds_cluster_instance" "secondary" {
  provider                     = aws.secondary
  identifier                   = "${var.name_prefix}-aurora-secondary-instance-1"
  cluster_identifier           = aws_rds_cluster.secondary.id
  instance_class               = "db.serverless"
  engine                       = aws_rds_cluster.secondary.engine
  engine_version               = aws_rds_cluster.secondary.engine_version
  db_subnet_group_name         = aws_db_subnet_group.secondary.name
  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring_secondary.arn
}
