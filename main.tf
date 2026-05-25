locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ─── IAM Account Password Policy ─────────────────────────────────────────────

resource "aws_iam_account_password_policy" "strict" {
  provider                       = aws.primary
  minimum_password_length        = 14
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  hard_expiry                    = false
  max_password_age               = 90
  password_reuse_prevention      = 24
}

# ─── ALB Access Logs S3 Bucket ───────────────────────────────────────────────

module "logging" {
  source    = "./modules/logging"
  providers = { aws = aws.primary }

  bucket_name        = "${var.project_name}-${var.environment}-alb-logs"
  log_retention_days = 90
  tags               = local.common_tags
}

# ─── EC2 Key Pair ─────────────────────────────────────────────────────────────

module "keypair" {
  source    = "./modules/keypair"
  providers = { aws = aws.primary }

  key_name    = "${var.project_name}-${var.environment}-key"
  environment = var.environment
  tags        = local.common_tags
}

# ─── Aurora Password Secret ───────────────────────────────────────────────────
# Seed after first apply:
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
  vpc_cidr             = var.primary_vpc_cidr
  bastion_allowed_cidr = var.bastion_allowed_cidr
  tags                 = local.common_tags
}

module "security_secondary" {
  source    = "./modules/security"
  providers = { aws = aws.secondary }

  name_prefix          = "${var.project_name}-${var.environment}-secondary"
  vpc_id               = module.network_secondary.vpc_id
  vpc_cidr             = var.secondary_vpc_cidr
  bastion_allowed_cidr = var.bastion_allowed_cidr
  tags                 = local.common_tags
}

# ─── VPC Endpoints (private subnet traffic never hits internet) ───────────────

module "vpc_endpoints_primary" {
  source    = "./modules/vpc_endpoints"
  providers = { aws = aws.primary }

  name_prefix        = "${var.project_name}-${var.environment}-primary"
  vpc_id             = module.network_primary.vpc_id
  private_subnet_ids = module.network_primary.private_subnet_ids
  route_table_ids    = module.network_primary.private_route_table_ids
  app_sg_id          = module.security_primary.app_sg_id
  region             = var.primary_region
  tags               = local.common_tags
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

module "nlb_secondary" {
  source    = "./modules/nlb"
  providers = { aws = aws.secondary }

  name_prefix       = "${var.project_name}-${var.environment}-secondary"
  vpc_id            = module.network_secondary.vpc_id
  public_subnet_ids = module.network_secondary.public_subnet_ids
  alb_arn           = module.alb_secondary.external_alb_arn
  tags              = local.common_tags
}

module "alb_secondary" {
  source    = "./modules/alb"
  providers = { aws = aws.secondary }

  name_prefix         = "${var.project_name}-${var.environment}-secondary"
  vpc_id              = module.network_secondary.vpc_id
  public_subnet_ids   = module.network_secondary.public_subnet_ids
  private_subnet_ids  = module.network_secondary.private_subnet_ids
  alb_sg_id           = module.security_secondary.alb_sg_id
  internal_alb_sg_id  = module.security_secondary.internal_alb_sg_id
  acm_certificate_arn = module.dns_cert_secondary.certificate_arn
  alb_logs_bucket     = module.logging.bucket_name
  tags                = local.common_tags
}

module "dns_cert_secondary" {
  source    = "./modules/dns_cert"
  providers = { aws = aws.secondary }

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  hosted_zone_id            = var.hosted_zone_id
  nlb_dns_name              = module.nlb_secondary.nlb_dns_name
  nlb_zone_id               = module.nlb_secondary.nlb_zone_id
  secondary_nlb_dns_name    = module.nlb_primary.nlb_dns_name
  secondary_nlb_zone_id     = module.nlb_primary.nlb_zone_id
  tags                      = local.common_tags
}

# ─── DNS + ACM Certificate ────────────────────────────────────────────────────
# Use -target=module.dns_cert on first apply if cert doesn't exist yet.

module "dns_cert" {
  source    = "./modules/dns_cert"
  providers = { aws = aws.primary }

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  hosted_zone_id            = var.hosted_zone_id
  nlb_dns_name              = module.nlb_primary.nlb_dns_name
  nlb_zone_id               = module.nlb_primary.nlb_zone_id
  secondary_nlb_dns_name    = module.nlb_secondary.nlb_dns_name
  secondary_nlb_zone_id     = module.nlb_secondary.nlb_zone_id
  tags                      = local.common_tags
}

# ─── Bastion ──────────────────────────────────────────────────────────────────

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

# ─── ElastiCache Redis ────────────────────────────────────────────────────────

module "elasticache" {
  source    = "./modules/elasticache"
  providers = { aws = aws.primary }

  name_prefix      = "${var.project_name}-${var.environment}"
  environment      = var.environment
  subnet_ids       = module.network_primary.private_subnet_ids
  redis_sg_id      = module.security_primary.redis_sg_id
  node_type        = var.redis_node_type
  num_cache_nodes  = var.redis_num_nodes
  redis_auth_token = var.redis_auth_token
  log_group_name   = "/aws/elasticache/${var.project_name}-${var.environment}/redis"
  tags             = local.common_tags
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

  name_prefix               = "${var.project_name}-${var.environment}"
  vpc_id                    = module.network_primary.vpc_id
  peer_vpc_id               = module.network_secondary.vpc_id
  peer_owner_id             = var.aws_account_id
  peer_region               = var.secondary_region
  requester_route_table_ids = module.network_primary.private_route_table_ids
  peer_route_table_ids      = module.network_secondary.private_route_table_ids
  requester_cidr            = var.primary_vpc_cidr
  peer_cidr                 = var.secondary_vpc_cidr
  tags                      = local.common_tags
}

# ─── CloudTrail ───────────────────────────────────────────────────────────────

module "cloudtrail" {
  source    = "./modules/cloudtrail"
  providers = { aws = aws.primary }

  name_prefix    = "${var.project_name}-${var.environment}"
  bucket_name    = var.cloudtrail_bucket_name
  aws_account_id = var.aws_account_id
  tags           = local.common_tags
}

# ─── GuardDuty ────────────────────────────────────────────────────────────────

module "guardduty" {
  source = "./modules/guardduty"
  providers = {
    aws.primary   = aws.primary
    aws.secondary = aws.secondary
  }

  name_prefix          = "${var.project_name}-${var.environment}"
  alerts_sns_topic_arn = module.alerting.sns_topic_arn
  tags                 = local.common_tags
}

# ─── Security Hub ─────────────────────────────────────────────────────────────

module "security_hub" {
  source    = "./modules/security_hub"
  providers = { aws = aws.primary }

  name_prefix          = "${var.project_name}-${var.environment}"
  region               = var.primary_region
  alerts_sns_topic_arn = module.alerting.sns_topic_arn
  tags                 = local.common_tags
}

# ─── AWS Config ───────────────────────────────────────────────────────────────

module "config_rules" {
  source    = "./modules/config_rules"
  providers = { aws = aws.primary }

  name_prefix    = "${var.project_name}-${var.environment}"
  bucket_name    = var.config_bucket_name
  aws_account_id = var.aws_account_id
  tags           = local.common_tags
}

# ─── Observability (Dashboard + Firehose + Athena + X-Ray) ───────────────────

module "observability" {
  source    = "./modules/observability"
  providers = { aws = aws.primary }

  name_prefix        = "${var.project_name}-${var.environment}"
  logs_bucket_name   = var.logs_bucket_name
  alb_arn_suffix     = module.alb_primary.external_alb_arn_suffix
  web_asg_name       = module.web_asg_primary.asg_name
  app_asg_name       = module.app_asg_primary.asg_name
  aurora_cluster_id  = module.aurora.primary_cluster_id
  dynamodb_table_name = module.dynamodb.table_name
  waf_acl_name       = module.waf.web_acl_id
  region             = var.primary_region
  tags               = local.common_tags
}

# ─── Alerting (SNS + CloudWatch Alarms + ASG Notifications) ──────────────────

module "alerting" {
  source    = "./modules/alerting"
  providers = { aws = aws.primary }

  name_prefix                      = "${var.project_name}-${var.environment}"
  alert_email                      = var.alert_email
  alb_arn_suffix                   = module.alb_primary.external_alb_arn_suffix
  web_target_group_arn_suffix      = module.alb_primary.web_target_group_arn_suffix
  alb_5xx_threshold                = var.alb_5xx_threshold
  web_min_healthy_hosts            = var.web_min_size
  aurora_cluster_id                = module.aurora.primary_cluster_id
  aurora_max_connections_threshold = var.aurora_max_connections_threshold
  dynamodb_table_name              = module.dynamodb.table_name
  web_asg_name                     = module.web_asg_primary.asg_name
  app_asg_name                     = module.app_asg_primary.asg_name
  tags                             = local.common_tags
}

# ─── WAF + Shield Advanced ────────────────────────────────────────────────────

module "waf" {
  source    = "./modules/waf"
  providers = { aws = aws.primary }

  name_prefix             = "${var.project_name}-${var.environment}"
  alb_arn                 = module.alb_primary.external_alb_arn
  nlb_arn                 = module.nlb_primary.nlb_arn
  waf_log_destination_arn = module.observability.firehose_arn
  tags                    = local.common_tags
}

# ─── CloudFront CDN + S3 Static Assets ───────────────────────────────────────

module "cdn" {
  source = "./modules/cdn"
  providers = {
    aws.primary    = aws.primary
    aws.us_east_1  = aws.us_east_1
  }

  name_prefix            = "${var.project_name}-${var.environment}"
  bucket_name            = var.static_assets_bucket_name
  domain_name            = var.domain_name
  acm_certificate_arn    = var.cloudfront_acm_certificate_arn
  waf_web_acl_arn        = module.waf.web_acl_arn
  cloudfront_logs_bucket = "${module.logging.bucket_name}.s3.amazonaws.com"
  tags                   = local.common_tags
}

# ─── Global Accelerator ───────────────────────────────────────────────────────

module "globalaccelerator" {
  source    = "./modules/globalaccelerator"
  providers = { aws = aws.primary }

  name_prefix       = "${var.project_name}-${var.environment}"
  primary_region    = var.primary_region
  secondary_region  = var.secondary_region
  primary_nlb_arn   = module.nlb_primary.nlb_arn
  secondary_nlb_arn = module.nlb_secondary.nlb_arn
  logs_bucket_name  = module.observability.logs_bucket_name
  tags              = local.common_tags
}

# ─── FIS Chaos Engineering ────────────────────────────────────────────────────

module "fis" {
  source    = "./modules/fis"
  providers = { aws = aws.primary }

  name_prefix             = "${var.project_name}-${var.environment}"
  environment             = var.environment
  healthy_hosts_alarm_arn = module.alerting.sns_topic_arn
  aurora_cluster_arn      = module.aurora.primary_cluster_arn
  tags                    = local.common_tags
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
