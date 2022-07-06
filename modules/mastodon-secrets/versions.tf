terraform {
  required_version = "1.2.4"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.3"
    }
  }
}
