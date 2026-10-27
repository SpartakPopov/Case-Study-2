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
  source = "./modules/monitoring"
}
module "soar" {
  source = "./modules/soar"
}
module "vpn" {
  source = "./modules/vpn"
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