terraform {
  required_version = "1.3.1"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.39.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.39.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.13.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}
