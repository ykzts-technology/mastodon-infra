terraform {
  required_version = ">= 0.15.5"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.10.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.2"
    }
  }
}
