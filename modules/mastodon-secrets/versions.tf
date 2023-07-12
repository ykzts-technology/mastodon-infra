terraform {
  required_version = "1.5.2"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}
