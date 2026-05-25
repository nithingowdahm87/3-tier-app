locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ─── Primary Region ───────────────────────────────────────────────────────────

module "network_primary" {
  source = "./modules/network"
  providers = { aws = aws.primary }

  name_prefix = "${var.project_name}-${var.environment}-primary"
  vpc_cidr    = var.primary_vpc_cidr
  az_count    = var.az_count
  tags        = local.common_tags
}

module "network_secondary" {
  source = "./modules/network"
  providers = { aws = aws.secondary }

  name_prefix = "${var.project_name}-${var.environment}-secondary"
  vpc_cidr    = var.secondary_vpc_cidr
  az_count    = var.az_count
  tags        = local.common_tags
}

module "security_primary" {
  source = "./modules/security"
  providers = { aws = aws.primary }

  name_prefix          = "${var.project_name}-${var.environment}-primary"
  vpc_id               = module.network_primary.vpc_id
  bastion_allowed_cidr = var.bastion_allowed_cidr
  tags                 = local.common_tags
}

module "security_secondary" {
  source = "./modules/security"
  providers = { aws = aws.secondary }

  name_prefix          = "${var.project_name}-${var.environment}-secondary"
  vpc_id               = module.network_secondary.vpc_id
  bastion_allowed_cidr = var.bastion_allowed_cidr
  tags                 = local.common_tags
}

module "alb_primary" {
  source = "./modules/alb"
  providers = { aws = aws.primary }

  name_prefix          = "${var.project_name}-${var.environment}-primary"
  vpc_id               = module.network_primary.vpc_id
  public_subnet_ids    = module.network_primary.public_subnet_ids
  private_subnet_ids   = module.network_primary.private_subnet_ids
  alb_sg_id            = module.security_primary.alb_sg_id
  internal_alb_sg_id   = module.security_primary.internal_alb_sg_id
  acm_certificate_arn  = var.primary_acm_certificate_arn
  tags                 = local.common_tags
}

module "nlb_primary" {
  source = "./modules/nlb"
  providers = { aws = aws.primary }

  name_prefix       = "${var.project_name}-${var.environment}-primary"
  vpc_id            = module.network_primary.vpc_id
  public_subnet_ids = module.network_primary.public_subnet_ids
  alb_arn           = module.alb_primary.external_alb_arn
  tags              = local.common_tags
}

module "bastion_primary" {
  source = "./modules/bastion"
  providers = { aws = aws.primary }

  name_prefix      = "${var.project_name}-${var.environment}-primary"
  public_subnet_id = module.network_primary.public_subnet_ids[0]
  bastion_sg_id    = module.security_primary.bastion_sg_id
  key_name         = var.key_name
  instance_type    = var.bastion_instance_type
  tags             = local.common_tags
}

module "web_asg_primary" {
  source = "./modules/compute"
  providers = { aws = aws.primary }

  name_prefix           = "${var.project_name}-${var.environment}-primary"
  role                  = "web"
  instance_type         = var.web_instance_type
  fallback_instance_type = var.web_fallback_instance_type
  key_name              = var.key_name
  security_group_ids    = [module.security_primary.web_sg_id]
  subnet_ids            = module.network_primary.private_subnet_ids
  target_group_arns     = [module.alb_primary.web_target_group_arn]
  min_size              = var.web_min_size
  max_size              = var.web_max_size
  desired_capacity      = var.web_desired_capacity
  on_demand_base_capacity = var.on_demand_base_capacity
  user_data             = var.web_user_data
  tags                  = local.common_tags
}

module "app_asg_primary" {
  source = "./modules/compute"
  providers = { aws = aws.primary }

  name_prefix           = "${var.project_name}-${var.environment}-primary"
  role                  = "app"
  instance_type         = var.app_instance_type
  fallback_instance_type = var.app_fallback_instance_type
  key_name              = var.key_name
  security_group_ids    = [module.security_primary.app_sg_id]
  subnet_ids            = module.network_primary.private_subnet_ids
  target_group_arns     = [module.alb_primary.app_target_group_arn]
  min_size              = var.app_min_size
  max_size              = var.app_max_size
  desired_capacity      = var.app_desired_capacity
  on_demand_base_capacity = var.on_demand_base_capacity
  user_data             = var.app_user_data
  tags                  = local.common_tags
}

module "aurora" {
  source = "./modules/aurora_global"
  providers = {
    aws.primary   = aws.primary
    aws.secondary = aws.secondary
  }

  name_prefix              = "${var.project_name}-${var.environment}"
  primary_db_subnet_ids    = module.network_primary.db_subnet_ids
  secondary_db_subnet_ids  = module.network_secondary.db_subnet_ids
  primary_aurora_sg_id     = module.security_primary.aurora_sg_id
  secondary_aurora_sg_id   = module.security_secondary.aurora_sg_id
  database_name            = var.db_name
  master_username          = var.db_username
  master_password          = var.db_password
  tags                     = local.common_tags
}

module "dynamodb" {
  source = "./modules/dynamodb_global"
  providers = { aws = aws.primary }

  table_name     = "${var.project_name}-${var.environment}-sessions"
  hash_key       = "sessionId"
  replica_region = var.secondary_region
  tags           = local.common_tags
}

module "backup_primary" {
  source = "./modules/backup"
  providers = { aws = aws.primary }

  name_prefix  = "${var.project_name}-${var.environment}-primary"
  resource_arns = [module.aurora.primary_cluster_endpoint != "" ? "arn:aws:rds:${var.primary_region}:*:cluster:${var.project_name}-${var.environment}-aurora-primary" : ""]
  tags         = local.common_tags
}

module "vpc_peering" {
  source = "./modules/peering"
  providers = {
    aws      = aws.primary
    aws.peer = aws.secondary
  }

  name_prefix              = "${var.project_name}-${var.environment}"
  vpc_id                   = module.network_primary.vpc_id
  peer_vpc_id              = module.network_secondary.vpc_id
  peer_owner_id            = var.aws_account_id
  peer_region              = var.secondary_region
  requester_route_table_id = module.network_primary.private_route_table_id
  peer_route_table_id      = module.network_secondary.private_route_table_id
  requester_cidr           = var.primary_vpc_cidr
  peer_cidr                = var.secondary_vpc_cidr
  tags                     = local.common_tags
}
