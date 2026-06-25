locals {
  table_name = var.table_name != "" ? var.table_name : var.name_prefix
}

resource "aws_dynamodb_table" "this" {
  name             = local.table_name
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = var.hash_key
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = var.hash_key
    type = "S"
  }

  dynamic "attribute" {
    for_each = var.range_key != null ? [1] : []
    content {
      name = var.range_key
      type = "S"
    }
  }

  range_key = var.range_key

  # TTL: app writes Unix epoch timestamp to expiresAt; DynamoDB auto-deletes expired items
  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  deletion_protection_enabled = false

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region_name            = replica.value
      point_in_time_recovery = true
      kms_key_arn            = var.replica_kms_key_arn
    }
  }

  tags = merge(var.tags, { Name = local.table_name })
}

# ─── DynamoDB Auto Scaling ────────────────────────────────────────────────────
# PAY_PER_REQUEST handles burst automatically, but explicit auto-scaling
# policies give you cost visibility and t