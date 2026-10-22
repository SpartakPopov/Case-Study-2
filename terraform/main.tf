module "network" {
  source = "./modules/network"
}

module "data" {
  source = "./modules/data"
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
  source = "./modules/web"
}

module "dns" {
  source = "./modules/dns"
  vpc_id = module.network.internal_vpc_id
}