variable "db_instance_name" {
  type = string
}

variable "domain" {
  type = string
}

variable "dns_zone_name" {
  type = string
}

variable "ip_address_name" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  default = "asia-northeast1"
  type    = string
}
