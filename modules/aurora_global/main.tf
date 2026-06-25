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

# resource "aws_rds_global_cluster" "this" {
#   global_cluster_identifier = "${var.name_prefix}-global-aurora"
#   engine                    = var.engine
#   engine_version            = var.engine_version
#   database_name             = var.database_name
#   deletion_protection       = true
#   storage_encrypted         = true
# }

resource "aws_db_instance" "primary" {
  provider                = aws.primary
  identifier              = "${var.name_prefix}-rds-primary"
  engine                  = var.engine
  engine_version          = var.engine_version
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = var.master_username
  password                = var.master_password
  db_subnet_group_name    = aws_db_subnet_group.primary.name
  vpc_security_group_ids  = [var.primary_aurora_sg_id]
  storage_encrypted       = true
  skip_final_snapshot     = false
  backup_retention_period = 1
  apply_immediately       = true
  monitoring_interval     = 60
  monitoring_role_arn     = aws_iam_role.rds_monitoring.arn
  parameter_group_name    = var.parameter_group_name
  publicly_accessible     = false
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-rds-primary" })
}

resource "aws_db_instance" "secondary" {
  provider                = aws.secondary
  identifier              = "${var.name_prefix}-rds-secondary"
  engine                  = var.engine
  engine_version          = var.engine_version
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = var.master_username
  password                = var.master_password
  db_subnet_group_name    = aws_db_subnet_group.secondary.name
  vpc_security_group_ids  = [var.secondary_aurora_sg_id]
  storage_encrypted       = true
  skip_final_snapshot     = false
  backup_retention_period = 1
  apply_immediately       = true
  monitoring_interval     = 60
  monitoring_role_arn     = aws_iam_role.rds_monitoring_secondary.arn
  parameter_group_name    = var.parameter_group_name
  publicly_accessible     = false
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-rds-secondary" })
}

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
