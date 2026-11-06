variable "internal_vpc_id" {
  description = "VPC the monitoring server runs in"
  type        = string
}

variable "monitoring_subnet_id" {
  description = "Monitoring subnet (10.0.2.128/26)"
  type        = string
}

variable "zone_id" {
  description = "Private hosted zone for the loki/grafana names"
  type        = string
}

variable "private_ip" {
  description = "Fixed IP so the on-prem collector config never changes"
  type        = string
  default     = "10.0.2.140"
}

variable "instance_type" {
  description = "Loki + Grafana fit in 2 GB so go to t3.medium when Prometheus is added"
  type        = string
  default     = "t3.medium"
}

variable "collector_cidr" {
  description = "On-prem Alloy collector that pushes logs over the VPN"
  type        = string
  default     = "192.168.40.10/32"
}

variable "admin_cidr" {
  description = "Admin PC on the TRANSIT net that opens Grafana over the VPN"
  type        = string
  default     = "192.168.10.10/32"
}

variable "soar_alerts_topic_arn" {
  description = "SNS topic Grafana publishes SOAR alerts to"
  type        = string
}