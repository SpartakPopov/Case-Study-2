resource "aws_route_table" "dmz_private_rt" { // table for TGW subnets
  vpc_id = aws_vpc.vpc-dmz.id
  tags   = { Name = "vpc-dmz-private-rt" }
}

resource "aws_route" "dmz_private_default" {
  route_table_id         = aws_route_table.dmz_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.innovatech_nat.id
}

resource "aws_route_table_association" "tgw_subnet_a" {
  subnet_id      = aws_subnet.transit_gateway_subnet_a.id
  route_table_id = aws_route_table.dmz_private_rt.id
}

resource "aws_route_table_association" "tgw_subnet_b" {
  subnet_id      = aws_subnet.transit_gateway_subnet_b.id
  route_table_id = aws_route_table.dmz_private_rt.id
}


resource "aws_route" "dmz_to_internal" {
  route_table_id         = aws_route_table.dmz_public_a_rt.id
  destination_cidr_block = aws_vpc.internal_vpc.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.dmz_attachment]
}


resource "aws_route_table" "dmz_public_a_rt" { // the two public subnets and the nat to the internet
  vpc_id = aws_vpc.vpc-dmz.id
  tags = {
    Name = "innovatech-dmz-public-rt"
  }
}

resource "aws_route" "dmz_default" {
  route_table_id         = aws_route_table.dmz_public_a_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.innovatech_igw.id
}

resource "aws_route_table_association" "dmz_public_assoc" {
  subnet_id      = aws_subnet.dmz_public_a.id
  route_table_id = aws_route_table.dmz_public_a_rt.id
}

resource "aws_route_table_association" "dmz_public_b_assoc" {
  subnet_id      = aws_subnet.dmz_public_b.id
  route_table_id = aws_route_table.dmz_public_a_rt.id
}

resource "aws_route_table_association" "nat_assoc" {
  subnet_id      = aws_subnet.nat.id
  route_table_id = aws_route_table.dmz_public_a_rt.id
}



resource "aws_route" "internal_default" { // everything internal goes through the tgw
  route_table_id         = aws_vpc.internal_vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.internal_vpc_attachment]
}


resource "aws_ec2_transit_gateway_route" "default_to_dmz" { // tgw internet bound traffic to DMZ
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dmz_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw.association_default_route_table_id
}