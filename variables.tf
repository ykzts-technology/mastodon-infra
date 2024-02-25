variable "deepl_api_key" {
  type = string
}

variable "domain" {
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

variable "grafana_api_token" {
  type = string
}

variable "grafana_datasource_uids" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  default = "asia-northeast1"
  type    = string
}

variable "smtp_password" {
  type = string
}

variable "vapid_private_key" {
  type = string
}

variable "vapid_public_key" {
  type = string
}
