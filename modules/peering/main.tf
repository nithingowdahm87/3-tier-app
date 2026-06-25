terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws, aws.peer]
    }
  }
}

resource "aws_vpc_peering_connection" "this" {
  peer_owner_id = var.peer_owner_id
  peer_vpc_id   = var.peer_vpc_id
  vpc_id        = var.vpc_id
  peer_region   = var.peer_region
  auto_accept   = false

  tags = merge(var.tags, { Name = "${var.name_prefix}-peering" })
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = aws.peer
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-peering-accepter" })
}

# Add peering route to ALL requester private route tables (one per AZ)
resource "aws_route" "requester_private" {
  count = length(var.primary_route_table_ids)

  route_table_id            = var.primary_route_table_ids[count.index]
  destination_cidr_block    = var.secondary_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

# Add peering route to ALL peer private route tables (one per AZ)
resource "aws_route" "accepter_private" {
  provider = aws.peer
  count    = length(var.secondary_route_table_ids)

  route_table_id            = var.secondary_route_table_ids[count.index]
  destination_cidr_block    = var.primary_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}
