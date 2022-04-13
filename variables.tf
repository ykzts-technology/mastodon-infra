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

variable "redis_hostname" {
  type = string
}

variable "redis_password" {
  type = string
}

variable "redis_port" {
  type = string
}

variable "region" {
  default = "asia-northeast1"
  type    = string
}

variable "smtp_password" {
  type = string
}

variable "storage_bucket_name" {
  type = string
}

variable "vapid_private_key" {
  type = string
}

variable "vapid_public_key" {
  type = string
}
