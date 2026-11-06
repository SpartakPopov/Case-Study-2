variable "onprem_public_ip" {
  description = "Home router public IP that pfSense connects from"
  type        = string
}

variable "onprem_cidrs" {
  description = "On-prem VLANs"
  type        = list(string)
  default     = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24", "192.168.40.0/24"]
}

variable "vpn_tunnel1_psk" {
  type      = string
  sensitive = true
}

variable "vpn_tunnel2_psk" {
  type      = string
  sensitive = true
}

variable "alert_email" {
  description = "alert receiving email"
  type        = string
}

variable "pfsense_api_key" {
  description = "REST API key for pfSense R2 (SOAR blocking)"
  type        = string
  sensitive   = true
}
