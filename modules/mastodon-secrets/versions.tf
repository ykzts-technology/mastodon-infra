terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.25.2"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}
