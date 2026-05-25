resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.hash_key

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

  deletion_protection_enabled = true

  replica {
    region_name            = var.replica_region
    point_in_time_recovery = true
    kms_key_arn            = var.replica_kms_key_arn
  }

  tags = merge(var.tags, { Name = var.table_name })
}

# ─── DynamoDB Auto Scaling ────────────────────────────────────────────────────
# PAY_PER_REQUEST handles burst automatically, but explicit auto-scaling
# policies give you cost visibility and t