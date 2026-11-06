output "vpn_tunnel1_address" {
  value = module.vpn.tunnel1_address
}

output "vpn_tunnel2_address" {
  value = module.vpn.tunnel2_address
}

output "vpn_tunnel1_inside" {
  value = module.vpn.tunnel1_inside
}

output "vpn_tunnel2_inside" {
  value = module.vpn.tunnel2_inside
}

output "monitoring_instance_id" {
  value = module.monitoring.instance_id
}

output "soar_alerts_topic_arn" {
  value = module.soar.alerts_topic_arn
}
