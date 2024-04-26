variable "active_record_encryption_key_derivation_salt" {
  type = string
}

variable "active_record_encryption_deterministic_key" {
  type = string
}

variable "active_record_encryption_primary_key" {
  type = string
}

variable "deepl_api_key" {
  type = string
}

variable "db_hostname" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_port" {
  default = "5432"
  type    = string
}

variable "db_username" {
  type = string
}

variable "es_hostname" {
  type = string
}

variable "es_password" {
  type = string
}

variable "es_port" {
  type = string
}

variable "es_username" {
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

variable "smtp_password" {
  type = string
}

variable "storage_access_key" {
  type = string
}

variable "storage_bucket" {
  type = string
}

variable "storage_endpoint" {
  type = string
}

variable "storage_hostname" {
  type = string
}

variable "storage_region" {
  type = string
}

variable "storage_secret_key" {
  type = string
}

variable "vapid_private_key" {
  type = string
}

variable "vapid_public_key" {
  type = string
}
