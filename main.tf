locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ─── ALB Access Logs S3 Bucket ──────────────────────────────────────────────────────────

module "logging" {
  source    = "./modules/logging"
  providers = { aws = aws.primary }

  bucket_name        = "${var.project_name}-${var.environment}-alb-logs"
  log_retention_days = 90
  tags               = local.common_tags
}

# ─── EC2 Key Pair ─────────────────────────────────────────────────────────────────

module "keypair" {
  source    = "./modules/keypair"
  providers = { aws = aws.primary }

  key_name    = "${var.project_name}-${var.environment}-key"
  environment = var.environment
  tags        = local.common_tags
}

# ─── Aurora Password Secret ─────────────────────────────────────────────────────────
# The secret RESOURCE is managed here. Seed the value after first apply:
#   aws secretsmanager put-secret-value \
#     --secret-id /${var.environment}/aurora/master_password \
#     --secret-string '{"password": "YourStrongPassword123!"}'

module "aurora_secret" {
  source    = "./modules/secrets"
  providers = { aws = aws.primary }

  secret_name = "/${var.environment}/aurora/master_password"
  description = "Aurora MySQL master password for ${var.project_name} ${var.environment}"
  tags        = local.common_tags
}

# Fetch the secret value (must be seeded before apply or use -target ordering)
data "aws_secretsmanager_secret_version" "aurora" {
  provider   = aws.primary
  secret_id  = module.aurora_secret.secret_name
  depends_on = [module.aurora_secret]
}

locals {
  db_password = jsondecode(data.aws_secretsmanager_secret_version.aurora.secret_string)["password"]
}

# ─── Primary Network ──────────────────────────────────────────────────────────

module "network_primary" {
  source    = "./modules/network"
  providers = { aws = aws.primary }

  name_prefix = "${var.project_name}-${var.environment}-primary"
  vpc_cidr    = var.primary_vpc_cidr
  az_count    = var.az_count
  tags        = local.common_tags
}

module "network_secondary" {
  source    = "./modules/network"
  providers = { aws = aws.secondary }

  name_prefix = "${var.project_name}-${var.environment}-secondary"
  vpc_cidr    = var.secondary_vpc_cidr
  az_count    = var.az_count
  tags        = local.common_tags
}

# ─── Security Groups ──────────────────────────────────────────────────────────

module "security_primary" {
  source    = "./modules/security"
  providers = { aws = aws.primary }

  name_prefix          = "${var.project_name}-${var.environment}-primary"
  vpc_id               = module.network_primary.vpc_id
  bastion_allowed_cidr = var.bastion_allowed_cidr
  tags                 = local.common_tags
}

module "security_secondary" {
  source    = "./modules/security"
  providers = { aws = aws.secondary }

  name_prefix          = "${var.project_name}-${var.environment}-secondary"
  vpc_id               = module.network_secondary.vpc_id
  bastion_allowed_cidr = var.bastion_allowed_cidr
  tags                 = local.common_tags
}

# ─── Load Balancers ───────────────────────────────────────────────────────────

module "alb_primary" {
  source    = "./modules/alb"
  providers = { aws = aws.primary }

  name_prefix         = "${var.project_name}-${var.environment}-primary"
  vpc_id              = module.network_primary.vpc_id
  public_subnet_ids   = module.network_primary.public_subnet_ids
  private_subnet_ids  = module.network_primary.private_subnet_ids
  alb_sg_id           = module.security_primary.alb_sg_id
  internal_alb_sg_id  = module.security_primary.internal_alb_sg_id
  acm_certificate_arn = module.dns_cert.certificate_arn
  alb_logs_bucket     = module.logging.bucket_name
  tags                = local.common_tags
}

module "nlb_primary" {
  source    = "./modules/nlb"
  providers = { aws = aws.primary }

  name_prefix       = "${var.project_name}-${var.environment}-primary"
  vpc_id            = module.network_primary.vpc_id
  public_subnet_ids = module.network_primary.public_subnet_ids
  alb_arn           = module.alb_primary.external_alb_arn
  tags              = local.common_tags
}

# ─── DNS + ACM Certificate ──────────────────────────────────────────────────────────
# NOTE: The ALB module depends on dns_cert for the certificate ARN.
# Use -target=module.dns_cert on first apply if the cert doesn't exist yet.

module "dns_cert" {
  source    = "./modules/dns_cert"
  providers = { aws = aws.primary }

  domain_name            = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  hosted_zone_id         = var.hosted_zone_id
  nlb_dns_name           = module.nlb_primary.nlb_dns_name
  nlb_zone_id            = module.nlb_primary.nlb_zone_id
  tags                   = local.common_tags
}

# ─── Bastion (HA ASG across public subnets) ───────────────────────────────────

module "bastion_primary" {
  source    = "./modules/bastion"
  providers = { aws = aws.primary }

  name_prefix   = "${var.project_name}-${var.environment}-primary"
  subnet_ids    = module.network_primary.public_subnet_ids
  bastion_sg_id = module.security_primary.bastion_sg_id
  key_name      = module.keypair.key_name
  instance_type = var.bastion_instance_type
  tags          = local.common_tags
}

# ─── Compute (Web + App ASGs) ─────────────────────────────────────────────────

module "web_asg_primary" {
  source    = "./modules/compute"
  providers = { aws = aws.primary }

  name_prefix             = "${var.project_name}-${var.environment}-primary"
  role                    = "web"
  instance_type           = var.web_instance_type
  fallback_instance_type  = var.web_fallback_instance_type
  key_name                = module.keypair.key_name
  security_group_ids      = [module.security_primary.web_sg_id]
  subnet_ids              = module.network_primary.private_subnet_ids
  target_group_arns       = [module.alb_primary.web_target_group_arn]
  min_size                = var.web_min_size
  max_size                = var.web_max_size
  desired_capacity        = var.web_desired_capacity
  on_demand_base_capacity = var.on_demand_base_capacity
  user_data               = var.web_user_data
  secret_path_prefix      = "/${var.environment}"
  tags                    = local.common_tags
}

module "app_asg_primary" {
  source    = "./modules/compute"
  providers = { aws = aws.primary }

  name_prefix             = "${var.project_name}-${var.environment}-primary"
  role                    = "app"
  instance_type           = var.app_instance_type
  fallback_instance_type  = var.app_fallback_instance_type
  key_name                = module.keypair.key_name
  security_group_ids      = [module.security_primary.app_sg_id]
  subnet_ids              = module.network_primary.private_subnet_ids
  target_group_arns       = [module.alb_primary.app_target_group_arn]
  min_size                = var.app_min_size
  max_size                = var.app_max_size
  desired_capacity        = var.app_desired_capacity
  on_demand_base_capacity = var.on_demand_base_capacity
  user_data               = var.app_user_data
  secret_path_prefix      = "/${var.environment}"
  tags                    = local.common_tags
}

# ─── Database (Aurora Global) ─────────────────────────────────────────────────

module "aurora" {
  source = "./modules/aurora_global"
  providers = {
    aws.primary   = aws.primary
    aws.secondary = aws.secondary
  }

  name_prefix             = "${var.project_name}-${var.environment}"
  primary_db_subnet_ids   = module.network_primary.db_subnet_ids
  secondary_db_subnet_ids = module.network_secondary.db_subnet_ids
  primary_aurora_sg_id    = module.security_primary.aurora_sg_id
  secondary_aurora_sg_id  = module.security_secondary.aurora_sg_id
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = local.db_password
  tags                    = local.common_tags
}

# ─── DynamoDB Global Table ────────────────────────────────────────────────────

module "dynamodb" {
  source    = "./modules/dynamodb_global"
  providers = { aws = aws.primary }

  table_name     = "${var.project_name}-${var.environment}-sessions"
  hash_key       = "sessionId"
  replica_region = var.secondary_region
  tags           = local.common_tags
}

# ─── AWS Backup ───────────────────────────────────────────────────────────────

module "backup_primary" {
  source    = "./modules/backup"
  providers = { aws = aws.primary }

  name_prefix   = "${var.project_name}-${var.environment}-primary"
  resource_arns = [module.aurora.primary_cluster_arn]
  tags          = local.common_tags
}

# ─── VPC Peering ──────────────────────────────────────────────────────────────

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
  requester_route_table_ids = module.network_primary.private_route_table_ids
  peer_route_table_ids      = module.network_secondary.private_route_table_ids
  requester_cidr           = var.primary_vpc_cidr
  peer_cidr                = var.secondary_vpc_cidr
  tags                     = local.common_tags
}

# ─── ASG CPU Scaling Policies ─────────────────────────────────────────────────

resource "aws_autoscaling_policy" "web_cpu" {
  provider               = aws.primary
  name                   = "${var.project_name}-${var.environment}-primary-web-cpu-tracking"
  autoscaling_group_name = module.web_asg_primary.asg_name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

resource "aws_autoscaling_policy" "app_cpu" {
  provider               = aws.primary
  name                   = "${var.project_name}-${var.environment}-primary-app-cpu-tracking"
  autoscaling_group_name = module.app_asg_primary.asg_name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}
