module "network" {
  source = "./modules/network"
}

module "data" {
  source                 = "./modules/data"
  internal_vpc_id        = module.network.internal_vpc_id
  data_subnet_ids        = module.network.data_subnet_ids
  monitoring_subnet_cidr = module.network.monitoring_subnet_cidr
  web_sg_id              = module.web.web_sg_id
  zone_id                = module.dns.zone_id
}


module "monitoring" {
  source                = "./modules/monitoring"
  internal_vpc_id       = module.network.internal_vpc_id
  monitoring_subnet_id  = module.network.monitoring_subnet_id
  zone_id               = module.dns.zone_id
  soar_alerts_topic_arn = module.soar.alerts_topic_arn
}


module "soar" {
  source          = "./modules/soar"
  alert_email     = var.alert_email
  internal_vpc_id = module.network.internal_vpc_id
  soar_subnet_ids = module.network.soar_subnet_ids
  pfsense_api_key = var.pfsense_api_key
}


module "vpn" {
  source             = "./modules/vpn"
  tgw_id             = module.network.tgw_id
  tgw_route_table_id = module.network.tgw_route_table_id
  onprem_public_ip   = var.onprem_public_ip
  onprem_cidrs       = var.onprem_cidrs
  tunnel1_psk        = var.vpn_tunnel1_psk
  tunnel2_psk        = var.vpn_tunnel2_psk
}


module "web" {
  source                  = "./modules/web"
  dmz_vpc_id              = module.network.dmz_vpc_id
  dmz_public_subnet_ids   = module.network.dmz_public_subnet_ids
  dmz_public_subnet_cidrs = module.network.dmz_public_subnet_cidrs
  internal_vpc_id         = module.network.internal_vpc_id
  web_subnet_ids          = module.network.web_subnet_ids
  web_subnet_cidrs        = module.network.web_subnet_cidrs
}

module "dns" {
  source = "./modules/dns"
  vpc_id = module.network.internal_vpc_id
}