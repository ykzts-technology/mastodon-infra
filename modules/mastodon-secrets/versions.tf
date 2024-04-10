terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.28.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}
