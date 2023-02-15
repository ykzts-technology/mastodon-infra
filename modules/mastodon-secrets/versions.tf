terraform {
  required_version = "1.3.7"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.18.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}
