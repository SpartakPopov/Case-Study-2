variable "internal_vpc_id" {
  description = "The VPC where the DB is"
  type        = string
}

variable "data_subnet_ids" {
  description = "The subnets where the DB is"
  type        = list(string)
}

variable "web_sg_id" {
  description = "SG of the web servers allowed to connect"
  type        = string
}

variable "monitoring_subnet_cidr" {
  description = "Monitoring subnet allowed to connect"
  type        = string
}

variable "zone_id" {
  description = "Private hosted zone for the db name"
  type        = string
}

variable "instance_class" {
  description = "Database instance size"
  type        = string
  default     = "db.t3.micro"
}

variable "multi_az" {
  description = "Running a SYNC standby db instance in another AZ"
  type        = bool
  default     = false
}