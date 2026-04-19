terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.1.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
  }
}
