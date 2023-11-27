terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.24.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}
