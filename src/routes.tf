data "aws_route_tables" "requester" {
  provider = aws.requester
  vpc_id   = local.requester_vpc_id
}

data "aws_route_tables" "accepter" {
  count    = local.create_accepter ? 1 : 0
  provider = aws.accepter
  vpc_id   = local.accepter_vpc_id
}

resource "aws_route" "requester" {
  for_each = toset(data.aws_route_tables.requester.ids)
  provider = aws.requester

  route_table_id            = each.key
  destination_cidr_block    = local.accepter_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.requester.id
}

resource "aws_route" "accepter" {
  for_each = local.create_accepter ? toset(data.aws_route_tables.accepter.0.ids) : toset([])
  provider = aws.accepter

  route_table_id            = each.key
  destination_cidr_block    = local.requester_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter.0.id
}
