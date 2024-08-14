terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}
