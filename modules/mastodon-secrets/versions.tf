terraform {
  required_version = "1.2.2"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.11.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.3.0"
    }
  }
}
