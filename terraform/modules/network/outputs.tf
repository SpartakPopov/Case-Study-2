// values other modules need to place resources in the network

output "dmz_vpc_id" {
  value = aws_vpc.vpc-dmz.id
}

output "dmz_vpc_cidr" {
  value = aws_vpc.vpc-dmz.cidr_block
}

output "dmz_public_subnet_ids" {
  value = [aws_subnet.dmz_public_a.id, aws_subnet.dmz_public_b.id]
}

output "internal_vpc_id" {
  value = aws_vpc.internal_vpc.id
}

output "internal_vpc_cidr" {
  value = aws_vpc.internal_vpc.cidr_block
}

output "web_subnet_ids" {
  value = [aws_subnet.web_a.id, aws_subnet.web_b.id]
}

output "monitoring_subnet_id" {
  value = aws_subnet.monitoring.id
}

output "data_subnet_ids" {
  value = [aws_subnet.data_a.id, aws_subnet.data_b.id]
}

output "dns_subnet_ids" {
  value = [aws_subnet.dns_a.id, aws_subnet.dns_b.id]
}

output "soar_subnet_ids" {
  value = [aws_subnet.soar_a.id, aws_subnet.soar_b.id]
}


output "tgw_id" {
  value = aws_ec2_transit_gateway.tgw.id
}

output "tgw_route_table_id" {
  value = aws_ec2_transit_gateway.tgw.association_default_route_table_id
}
