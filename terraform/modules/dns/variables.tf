variable "vpc_id" {
  description = "The VPC ID where the DNS private zone will be visible in"
  type        = string

}

variable "private_zone_name" {
  description = "The name of the private hosted zone to create"
  type        = string
  default     = "innovatech.internal"
}