terraform {
  required_version = "1.4.2"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.19.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.0"
    }
  }
}
