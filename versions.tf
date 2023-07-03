terraform {
  required_version = "1.5.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.71.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.72.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.21.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}
