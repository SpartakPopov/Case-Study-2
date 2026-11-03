resource "aws_customer_gateway" "pfsense" {
  bgp_asn    = 65000
  ip_address = var.onprem_public_ip
  type       = "ipsec.1"

  tags = {
    Name = "innovatech-onprem-cgw"
  }
}

resource "aws_vpn_connection" "onprem" {
  customer_gateway_id = aws_customer_gateway.pfsense.id
  transit_gateway_id  = var.tgw_id
  type                = "ipsec.1"
  static_routes_only  = true

  // tunnel 1 AWS endpoint 
  tunnel1_inside_cidr                  = "169.254.10.0/30"
  tunnel1_preshared_key                = var.tunnel1_psk
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]

  // tunnel 2 PfSense endpoint
  tunnel2_inside_cidr                  = "169.254.11.0/30"
  tunnel2_preshared_key                = var.tunnel2_psk
  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14]


  tags = {
    Name = "innovatech-onprem-vpn"
  }
}

resource "aws_ec2_transit_gateway_route" "onprem" {
  for_each                       = toset(var.onprem_cidrs)
  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = aws_vpn_connection.onprem.transit_gateway_attachment_id
  transit_gateway_route_table_id = var.tgw_route_table_id

}