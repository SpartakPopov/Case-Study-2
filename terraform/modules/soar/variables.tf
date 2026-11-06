variable "alert_email" {
  type = string
}

variable "allowlist" {
  description = "IPs/CIDRs the SOAR must never block"
  type        = list(string)
  default = [
    "192.168.10.0/24",
    "192.168.40.0/24",
    "192.168.30.10/32",
    "10.0.0.0/16",
  ]
}

variable "block_hours" {
  description = "How long an incident (and later the block) stays open"
  type        = number
  default     = 24
}


variable "internal_vpc_id" {
  description = "VPC the SOAR Lambda runs in"
  type        = string
}

variable "soar_subnet_ids" {
  description = "SOAR subnets (10.0.3.0/27, 10.0.3.32/27)"
  type        = list(string)
}

variable "pfsense_api_key" {
  description = "REST API key for pfSense R2"
  type        = string
  sensitive   = true
}

variable "pfsense_url" {
  description = "R2 REST API, reached over the VPN"
  type        = string
  default     = "https://192.168.10.2"
}

variable "block_alias" {
  description = "pfSense alias the block rules use"
  type        = string
  default     = "SOAR_BLOCK"
}
