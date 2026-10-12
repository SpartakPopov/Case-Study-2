module "network" {
  source = "./modules/network"
}

module "data" {
  source = "./modules/data"
}
module "dns" {
  source = "./modules/dns"
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
