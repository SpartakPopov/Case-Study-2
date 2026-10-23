variable "dmz_vpc_id" {
  description = "The VPC ID of the DMZ VPC"
  type        = string
}

variable "dmz_public_subnet_ids" {
  description = "Public subnets for the ALB, one per AZ"
  type        = list(string)
}

variable "web_subnet_cidrs" {
  description = "Web tier subnets the ALB forwards traffic to"
  type        = list(string)
}

variable "internal_vpc_id" {
  description = "The VPC ID of the internal VPC"
  type        = string
}

variable "web_subnet_ids" {
  description = "Web subnets one per AZ"
  type        = list(string)
}


variable "dmz_public_subnet_cidrs" {
  description = "ALB subnets allowed to reach the web servers"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 size for the web servers"
  type        = string
  default     = "t3.micro"
}