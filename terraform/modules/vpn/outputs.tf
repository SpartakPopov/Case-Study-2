// values needed to configure pfSense

output "tunnel1_address" {
  value = aws_vpn_connection.onprem.tunnel1_address
}

output "tunnel2_address" {
  value = aws_vpn_connection.onprem.tunnel2_address
}

output "tunnel1_inside" {
  value = "pfSense ${aws_vpn_connection.onprem.tunnel1_cgw_inside_address} <-> AWS ${aws_vpn_connection.onprem.tunnel1_vgw_inside_address}"
}

output "tunnel2_inside" {
  value = "pfSense ${aws_vpn_connection.onprem.tunnel2_cgw_inside_address} <-> AWS ${aws_vpn_connection.onprem.tunnel2_vgw_inside_address}"
}
