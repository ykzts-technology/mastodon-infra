terraform {
  required_version = "1.5.4"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.79.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.79.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}
