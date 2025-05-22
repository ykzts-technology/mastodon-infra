terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}
