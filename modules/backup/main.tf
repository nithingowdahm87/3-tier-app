resource "aws_kms_key" "backup" {
  description             = "KMS key for AWS Backup vault - ${var.name_prefix}"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-backup-kms" })
}

resource "aws_kms_alias" "backup" {
  name          = "alias/${var.name_prefix}-backup"
  target_key_id = aws_kms_key.backup.key_id
}

resource "aws_iam_role" "backup" {
  name = "${var.name_prefix}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_vault" "this" {
  name        = "${var.name_prefix}-backup-vault"
  kms_key_arn = aws_kms_key.backup.arn
  tags        = merge(var.tags, { Name = "${var.name_prefix}-backup-vault" })
}

resource "aws_backup_plan" "this" {
  name = "${var.name_prefix}-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.this.name
    schedule          = "cron(0 3 * * ? *)"
    lifecycle {
      delete_after = 7
    }
  }

  rule {
    rule_name         = "weekly-backup"
    target_vault_name = aws_backup_vault.this.name
    schedule          = "cron(0 5 ? * 1 *)"
    lifecycle {
      delete_after = 30
    }
  }

  tags = var.tags
}

resource "aws_backup_selection" "dbs" {
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${var.name_prefix}-db-selection"
  plan_id      = aws_backup_plan.this.id
  resources    = var.resource_arns
}
