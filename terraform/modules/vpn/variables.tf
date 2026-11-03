variable "tgw_id" {
  description = "Transit Gateway the VPN attaches to"
  type        = string
}

variable "tgw_route_table_id" {
  description = "TGW route table that gets the on-prem routes"
  type        = string
}

variable "onprem_public_ip" {
  description = "Public IP pfSense connects from (home router WAN IP)"
  type        = string
}

variable "onprem_cidrs" {
  description = "On-prem networks reachable over the VPN"
  type        = list(string)
}

variable "tunnel1_psk" {
  description = "Pre-shared key for tunnel 1"
  type        = string
  sensitive   = true // variable to stop terraform from printing the keys in plan and apply
}

variable "tunnel2_psk" {
  description = "Pre-shared key for tunnel 2"
  type        = string
  sensitive   = true
}
