locals {
  create_accepter = var.accepter != null ? true : false

  # same_account = data.aws_arn.requester_vpc.account == data.aws_arn.accepter_vpc.account
  # same_region  = data.aws_arn.requester_vpc.region == data.aws_arn.accepter_vpc.region

  requester_vpc_id   = element(split("/", var.requester.data.infrastructure.arn), 1)
  requester_vpc_cidr = var.requester.data.infrastructure.cidr

  accepter_vpc_cidr    = try(var.accepter.data.infrastructure.cidr, var.accepter_vpc_cidr)
  accepter_vpc_id      = element(split("/", data.aws_arn.accepter_vpc.resource), 1)
  accepter_vpc_region  = data.aws_arn.accepter_vpc.region
  accepter_vpc_account = data.aws_arn.accepter_vpc.account
}

data "aws_arn" "requester_vpc" {
  arn = var.requester.data.infrastructure.arn
}
data "aws_arn" "accepter_vpc" {
  arn = try(var.accepter.data.infrastructure.arn, var.accepter_vpc_arn)
}

resource "aws_vpc_peering_connection" "requester" {
  provider      = aws.requester
  vpc_id        = local.requester_vpc_id
  peer_vpc_id   = local.accepter_vpc_id
  peer_owner_id = local.accepter_vpc_account
  peer_region   = local.accepter_vpc_region
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "accepter" {
  count                     = local.create_accepter ? 1 : 0
  provider                  = aws.accepter
  vpc_peering_connection_id = aws_vpc_peering_connection.requester.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

resource "aws_vpc_peering_connection_options" "requester" {
  count                     = local.create_accepter ? 1 : 0
  provider                  = aws.requester
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter.0.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "accepter" {
  count                     = local.create_accepter ? 1 : 0
  provider                  = aws.accepter
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter.0.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}
