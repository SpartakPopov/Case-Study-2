resource "aws_ec2_transit_gateway" "tgw" {
  description = "Innovatech Transit Gateway"
  tags = {
    Name = "innovatech-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "dmz_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc-dmz.id
  subnet_ids = [
    aws_subnet.transit_gateway_subnet_a.id,
    aws_subnet.transit_gateway_subnet_b.id
  ]
  tags = {
    Name = "dmz-attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "internal_vpc_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.internal_vpc.id
  subnet_ids = [
    aws_subnet.transit_gateway_internal_a.id,
    aws_subnet.transit_gateway_internal_b.id
  ]
  tags = {
    Name = "internal-attachment"
  }
}