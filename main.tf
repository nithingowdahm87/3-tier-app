locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner_tag
    CostCenter  = var.cost_center_tag
  }
  enable_unsupported_services = false
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

# ─── ALB Access Logs S3 Bucket ────────────────────────────────────────────────

module "logging" {
  source    = "./modules/logging"
  providers = { aws = aws.primary }

  bucket_name        = "${var.project_name}-${var.environment}-alb-logs-${var.aws_account_id}"
  log_retention_days = 90
  tags               = local.common_tags
}

module "logging_secondary" {
  source    = "./modules/logging"
  providers = { aws = aws.secondary }

  bucket_name        = "${var.project_name}-${var.environment}-alb-logs-secondary-${var.aws_account_id}"
  log_retention_days = 90
  tags               = local.common_tags
}

# ─── EC2 Key Pair ─────────────────────────────────────────────────────────────

module "keypair" {
  source    = "./modules/keypair"
  providers = { aws = aws.primary }

  name_prefix = "${var.project_name}-${var.environment}"
  tags        = local.common_tags
}

module "keypair_secondary" {
  source    = "./modules/keypair"
  providers = { aws = aws.secondary }

  name_prefix = "${var.project_name}-${var.environment}-secondary"
  tags        = local.common_tags
}

# ─── Secrets: Aurora Password ─────────────────────────────────────────────────

module "aurora_secret" {
  source    = "./modules/secrets"
  providers = { aws = aws.primary }

  secret_name = "/${var.project_name}-${var.environment}/aurora/master_password"
  description = "Aurora MySQL master password for ${var.project_name} ${var.environment}"
  tags        = local.common_tags
}

resource "aws_secretsmanager_secret_version" "aurora" {
  provider      = aws.primary
  secret_id     = module.aurora_secret.secret_name
  secret_string = jsonencode({ password = "ChangeMePassword123!" })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

locals {
  db_password = jsondecode(aws_secretsmanager_secret_version.aurora.secret_string)["password"]
}

# ─── Secrets: Redis AUTH Token ────────────────────────────────────────────────

module "redis_secret" {
  source    = "./modules/secrets"
  providers = { aws = aws.primary }

  secret_name = "/${var.project_name}-${var.environment}/redis/auth_token"
  description = "ElastiCache Redis AUTH token for ${var.project_name} ${var.environment}"
  tags        = local.common_tags
}

resource "aws_secretsmanager_secret_version" "redis" {
  provider      = aws.primary
  secret_id     = module.redis_secret.secret_name
  secret_string = jsonencode({ token = "ChangeMeToken123!" })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

locals {
  redis_auth_token = jsondecode(aws_secretsmanager_secret_version.redis.secret_string)["token"]
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

# ─── VPC Endpoints ───────────────────────────────────────────────────────────

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

module "vpc_endpoints_secondary" {
  source    = "./modules/vpc_endpoints"
  providers = { aws = aws.secondary }

  name_prefix        = "${var.project_name}-${var.environment}-secondary"
  vpc_id             = module.network_secondary.vpc_id
  private_subnet_ids = module.network_secondary.private_subnet_ids
  route_table_ids    = module.network_secondary.private_route_table_ids
  app_sg_id          = module.security_secondary.app_sg_id
  region             = var.secondary_region
  tags               = local.common_tags
}

# ─── Bastion ──────────────────────────────────────────────────────────────────

module "bastion_primary" {
  count     = var.bastion_enabled ? 1 : 0
  source    = "./modules/bastion"
  providers = { aws = aws.primary }

  name_prefix   = "${var.project_name}-${var.environment}-primary"
  vpc_id        = module.network_primary.vpc_id
  subnet_id     = module.network_primary.public_subnet_ids[0]
  bastion_sg_id = module.security_primary.bastion_sg_id
  key_name      = module.keypair.key_name
  tags          = local.common_tags
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
# module "nlb_primary" {
#   source    = "./modules/nlb"
#   providers = { aws = aws.primary }
# 
#   name_prefix       = "${var.project_name}-${var.environment}-primary"
#   vpc_id            = module.network_primary.vpc_id
#   public_subnet_ids = module.network_primary.public_subnet_ids
#   alb_arn           = module.alb_primary.external_alb_arn
#   tags              = local.common_tags
# 
#   depends_on = [module.alb_primary]
# }
# 
# module "nlb_secondary" {
#   source    = "./modules/nlb"
#   providers = { aws = aws.secondary }
# 
#   name_prefix       = "${var.project_name}-${var.environment}-secondary"
#   vpc_id            = module.network_secondary.vpc_id
#   public_subnet_ids = module.network_secondary.public_subnet_ids
#   alb_arn           = module.alb_secondary.external_alb_arn
#   tags              = local.common_tags
# 
#   depends_on = [module.alb_secondary]
# }

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
  alb_logs_bucket     = module.logging_secondary.bucket_name
  tags                = local.common_tags
}

# ─── DNS + ACM Certificate ────────────────────────────────────────────────────

module "dns_cert" {
  source    = "./modules/dns_cert"
  providers = { aws = aws.primary }

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  zone_id                   = var.hosted_zone_id
  tags                      = local.common_tags
}

module "dns_cert_secondary" {
  source    = "./modules/dns_cert"
  providers = { aws = aws.secondary }

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  zone_id                   = var.hosted_zone_id
  tags                      = local.common_tags
}

# ─── Compute (Web + App ASGs) ─────────────────────────────────────────────────

module "web_asg_primary" {
  source    = "./modules/compute"
  providers = { aws = aws.primary }

  name_prefix        = "${var.project_name}-${var.environment}-primary"
  instance_type      = var.web_instance_type
  key_name           = module.keypair.key_name
  security_group_ids = [module.security_primary.web_sg_id]
  subnet_ids         = module.network_primary.private_subnet_ids
  target_group_arns  = [module.alb_primary.web_target_group_arn]
  min_size           = var.web_min_size
  max_size           = var.web_max_size
  desired_capacity   = var.web_desired_capacity
  user_data          = var.web_user_data
  tags               = local.common_tags
}

module "app_asg_primary" {
  source    = "./modules/compute"
  providers = { aws = aws.primary }

  name_prefix        = "${var.project_name}-${var.environment}-primary"
  instance_type      = var.app_instance_type
  key_name           = module.keypair.key_name
  security_group_ids = [module.security_primary.app_sg_id]
  subnet_ids         = module.network_primary.private_subnet_ids
  target_group_arns  = [module.alb_primary.app_target_group_arn]
  min_size           = var.app_min_size
  max_size           = var.app_max_size
  desired_capacity   = var.app_desired_capacity
  user_data          = var.app_user_data
  tags               = local.common_tags
}

module "web_asg_secondary" {
  source    = "./modules/compute"
  providers = { aws = aws.secondary }

  name_prefix        = "${var.project_name}-${var.environment}-secondary"
  instance_type      = var.web_instance_type
  key_name           = module.keypair_secondary.key_name
  security_group_ids = [module.security_secondary.web_sg_id]
  subnet_ids         = module.network_secondary.private_subnet_ids
  target_group_arns  = [module.alb_secondary.web_target_group_arn]
  min_size           = var.web_min_size
  max_size           = var.web_max_size
  desired_capacity   = var.web_desired_capacity
  user_data          = var.web_user_data
  tags               = local.common_tags
}

module "app_asg_secondary" {
  source    = "./modules/compute"
  providers = { aws = aws.secondary }

  name_prefix        = "${var.project_name}-${var.environment}-secondary"
  instance_type      = var.app_instance_type
  key_name           = module.keypair_secondary.key_name
  security_group_ids = [module.security_secondary.app_sg_id]
  subnet_ids         = module.network_secondary.private_subnet_ids
  target_group_arns  = [module.alb_secondary.app_target_group_arn]
  min_size           = var.app_min_size
  max_size           = var.app_max_size
  desired_capacity   = var.app_desired_capacity
  user_data          = var.app_user_data
  tags               = local.common_tags
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
  parameter_group_name    = var.parameter_group_name
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
  redis_auth_token = local.redis_auth_token
  tags             = local.common_tags
}

# ─── DynamoDB Global Table ────────────────────────────────────────────────────

module "dynamodb" {
  source    = "./modules/dynamodb_global"
  providers = { aws = aws.primary }

  name_prefix     = "${var.project_name}-${var.environment}-sessions"
  hash_key        = "sessionId"
  replica_regions = [var.secondary_region]
  tags            = local.common_tags
}

# ─── AWS Backup ───────────────────────────────────────────────────────────────

module "backup_primary" {
  source    = "./modules/backup"
  providers = { aws = aws.primary }

  name_prefix = "${var.project_name}-${var.environment}-primary"
  resource_arns = [
    module.aurora.primary_db_instance_id,
    module.dynamodb.table_arn,
  ]
  tags = local.common_tags
}

module "backup_secondary" {
  source    = "./modules/backup"
  providers = { aws = aws.secondary }

  name_prefix   = "${var.project_name}-${var.environment}-secondary"
  resource_arns = [module.aurora.secondary_db_instance_id]
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
  peer_region               = var.secondary_region
  primary_cidr              = var.primary_vpc_cidr
  secondary_cidr            = var.secondary_vpc_cidr
  primary_route_table_ids   = module.network_primary.private_route_table_ids
  secondary_route_table_ids = module.network_secondary.private_route_table_ids
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
  count  = local.enable_unsupported_services ? 1 : 0
  source = "./modules/guardduty"
  providers = {
    aws.primary   = aws.primary
    aws.secondary = aws.secondary
  }

  name_prefix          = "${var.project_name}-${var.environment}"
  alerts_sns_topic_arn = module.alerting.sns_topic_arn
  tags                 = local.common_tags
}

# ─── Security Hub (both regions) ──────────────────────────────────────────────

module "security_hub" {
  count     = local.enable_unsupported_services ? 1 : 0
  source    = "./modules/security_hub"
  providers = { aws = aws.primary }

  name_prefix = "${var.project_name}-${var.environment}"
  tags        = local.common_tags
}

module "security_hub_secondary" {
  count     = local.enable_unsupported_services ? 1 : 0
  source    = "./modules/security_hub"
  providers = { aws = aws.secondary }

  name_prefix = "${var.project_name}-${var.environment}"
  tags        = local.common_tags
}

# ─── AWS Config (both regions) ────────────────────────────────────────────────

module "config_rules" {
  source    = "./modules/config_rules"
  providers = { aws = aws.primary }

  name_prefix    = "${var.project_name}-${var.environment}"
  bucket_name    = "${var.config_bucket_name}-primary"
  aws_account_id = var.aws_account_id
  tags           = local.common_tags
}

module "config_rules_secondary" {
  source    = "./modules/config_rules"
  providers = { aws = aws.secondary }

  name_prefix    = "${var.project_name}-${var.environment}"
  bucket_name    = "${var.config_bucket_name}-secondary"
  aws_account_id = var.aws_account_id
  tags           = local.common_tags
}

# ─── Compliance Config Rules (extended rule set) ──────────────────────────────

module "compliance" {
  source    = "./modules/compliance"
  providers = { aws = aws.primary }

  name_prefix   = "${var.project_name}-${var.environment}"
  recorder_id   = module.config_rules.recorder_id
  config_bucket = "${var.config_bucket_name}-primary"
  tags          = local.common_tags
}

module "compliance_secondary" {
  source    = "./modules/compliance"
  providers = { aws = aws.secondary }

  name_prefix   = "${var.project_name}-${var.environment}"
  recorder_id   = module.config_rules_secondary.recorder_id
  config_bucket = "${var.config_bucket_name}-secondary"
  tags          = local.common_tags
}

# ─── Observability ───────────────────────────────────────────────────────────

module "observability" {
  source    = "./modules/observability"
  providers = { aws = aws.primary }

  name_prefix         = "${var.project_name}-${var.environment}"
  logs_bucket_name    = var.logs_bucket_name
  alb_arn_suffix      = module.alb_primary.external_alb_arn_suffix
  web_asg_name        = module.web_asg_primary.asg_name
  app_asg_name        = module.app_asg_primary.asg_name
  db_instance_id      = module.aurora.primary_db_instance_id
  dynamodb_table_name = module.dynamodb.table_name
  waf_acl_name        = ""
  region              = var.primary_region
  tags                = local.common_tags
}

module "observability_secondary" {
  source    = "./modules/observability"
  providers = { aws = aws.secondary }

  name_prefix         = "${var.project_name}-${var.environment}-secondary"
  logs_bucket_name    = "${var.logs_bucket_name}-secondary"
  alb_arn_suffix      = module.alb_secondary.external_alb_arn_suffix
  web_asg_name        = module.web_asg_secondary.asg_name
  app_asg_name        = module.app_asg_secondary.asg_name
  db_instance_id      = module.aurora.secondary_db_instance_id
  dynamodb_table_name = module.dynamodb.table_name
  waf_acl_name        = ""
  region              = var.secondary_region
  tags                = local.common_tags
}

# ─── Platform Alarms ─────────────────────────────────────────────────────────

module "alarms_platform" {
  source    = "./modules/alarms_platform"
  providers = { aws = aws.primary }

  name_prefix                       = "${var.project_name}-${var.environment}"
  sns_topic_arn                     = module.alerting.sns_topic_arn
  nat_gateway_ids                   = module.network_primary.nat_gateway_ids
  health_check_id                   = var.route53_health_check_id
  rotation_lambda_name              = var.secrets_rotation_lambda_name
  nat_connection_threshold          = var.nat_connection_threshold
  nat_packet_drop_threshold         = var.nat_packet_drop_threshold
  kms_throttle_threshold            = var.kms_throttle_threshold
  secretsmanager_throttle_threshold = var.secretsmanager_throttle_threshold
  acm_expiry_days_threshold         = var.acm_expiry_days_threshold
  tags                              = local.common_tags
}

# ─── Alerting ─────────────────────────────────────────────────────────────────

module "alerting" {
  source    = "./modules/alerting"
  providers = { aws = aws.primary }

  name_prefix                   = "${var.project_name}-${var.environment}"
  alert_email                   = var.alert_email
  alb_arn_suffix                = module.alb_primary.external_alb_arn_suffix
  web_target_group_arn_suffix   = module.alb_primary.web_target_group_arn_suffix
  alb_5xx_threshold             = var.alb_5xx_threshold
  web_min_healthy_hosts         = var.web_min_size
  db_instance_id                = module.aurora.primary_db_instance_id
  rds_max_connections_threshold = var.rds_max_connections_threshold
  dynamodb_table_name           = module.dynamodb.table_name
  web_asg_name                  = module.web_asg_primary.asg_name
  app_asg_name                  = module.app_asg_primary.asg_name
  tags                          = local.common_tags
}

# ─── WAF ──────────────────────────────────────────────────────────────────────

module "waf" {
  source    = "./modules/waf"
  providers = { aws = aws.primary }

  name_prefix             = "${var.project_name}-${var.environment}-primary"
  alb_arn                 = module.alb_primary.external_alb_arn
  nlb_arn                 = ""
  waf_log_destination_arn = module.observability.firehose_arn
  tags                    = local.common_tags
}

module "waf_secondary" {
  source    = "./modules/waf"
  providers = { aws = aws.secondary }

  name_prefix             = "${var.project_name}-${var.environment}-secondary"
  alb_arn                 = module.alb_secondary.external_alb_arn
  nlb_arn                 = ""
  waf_log_destination_arn = module.observability_secondary.firehose_arn
  tags                    = local.common_tags
}

# ─── CloudFront CDN + S3 Static Assets ───────────────────────────────────────

module "cdn" {
  source = "./modules/cdn"
  providers = {
    aws.primary   = aws.primary
    aws.us_east_1 = aws.us_east_1
  }

  name_prefix            = "${var.project_name}-${var.environment}"
  alb_dns_name           = module.alb_primary.external_alb_dns_name
  acm_certificate_arn    = var.cloudfront_acm_certificate_arn
  waf_acl_arn            = ""
  cloudfront_logs_bucket = "${module.logging.bucket_name}.s3.amazonaws.com"
  tags                   = local.common_tags
}

# ─── Global Accelerator ───────────────────────────────────────────────────────

module "globalaccelerator" {
  count     = local.enable_unsupported_services ? 1 : 0
  source    = "./modules/globalaccelerator"
  providers = { aws = aws.primary }

  name_prefix       = "${var.project_name}-${var.environment}"
  primary_region    = var.primary_region
  secondary_region  = var.secondary_region
  nlb_primary_arn   = module.alb_primary.external_alb_arn
  nlb_secondary_arn = module.alb_secondary.external_alb_arn
  tags              = local.common_tags
}


# ─── FIS Chaos Engineering ────────────────────────────────────────────────────

module "fis" {
  count     = local.enable_unsupported_services ? 1 : 0
  source    = "./modules/fis"
  providers = { aws = aws.primary }

  name_prefix             = "${var.project_name}-${var.environment}"
  environment             = var.environment
  healthy_hosts_alarm_arn = module.alerting.sns_topic_arn
  aurora_cluster_arn      = module.aurora.primary_db_instance_id
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

resource "aws_autoscaling_policy" "web_cpu_secondary" {
  provider               = aws.secondary
  name                   = "${var.project_name}-${var.environment}-secondary-web-cpu-tracking"
  autoscaling_group_name = module.web_asg_secondary.asg_name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

resource "aws_autoscaling_policy" "app_cpu_secondary" {
  provider               = aws.secondary
  name                   = "${var.project_name}-${var.environment}-secondary-app-cpu-tracking"
  autoscaling_group_name = module.app_asg_secondary.asg_name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

# ─── Route53 Failover Health Check and Records ────────────────────────────────

resource "aws_route53_health_check" "primary" {
  count             = var.hosted_zone_id != "" && var.hosted_zone_id != "Z1234567890ABC" ? 1 : 0
  provider          = aws.primary
  fqdn              = module.alb_primary.external_alb_dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(local.common_tags, { Name = "${var.domain_name}-primary-health-check" })
}

resource "aws_route53_record" "app_primary" {
  count          = var.hosted_zone_id != "" && var.hosted_zone_id != "Z1234567890ABC" ? 1 : 0
  provider       = aws.primary
  zone_id        = var.hosted_zone_id
  name           = var.domain_name
  type           = "A"
  set_identifier = "primary"

  failover_routing_policy { type = "PRIMARY" }
  health_check_id = aws_route53_health_check.primary[0].id

  alias {
    name                   = module.alb_primary.external_alb_dns_name
    zone_id                = module.alb_primary.external_alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "app_secondary" {
  count          = var.hosted_zone_id != "" && var.hosted_zone_id != "Z1234567890ABC" ? 1 : 0
  provider       = aws.primary
  zone_id        = var.hosted_zone_id
  name           = var.domain_name
  type           = "A"
  set_identifier = "secondary"

  failover_routing_policy { type = "SECONDARY" }

  alias {
    name                   = module.alb_secondary.external_alb_dns_name
    zone_id                = module.alb_secondary.external_alb_zone_id
    evaluate_target_health = true
  }
}

