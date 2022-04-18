variable "names" {
  type = list(string)
}

variable "project" {
  type = string
}

variable "region" {
  default = "asia-northeast1"
  type    = string
}
