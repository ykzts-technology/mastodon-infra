terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
  }
}
