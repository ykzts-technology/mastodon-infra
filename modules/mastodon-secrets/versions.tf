terraform {
  required_version = "1.2.8"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.13.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.3"
    }
  }
}
