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

resource "aws_route" "requester_private" {
  route_table_id            = var.requester_route_table_id
  destination_cidr_block    = var.peer_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "accepter_private" {
  provider                  = aws.peer
  route_table_id            = var.peer_route_table_id
  destination_cidr_block    = var.requester_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}
