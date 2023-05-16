terraform {
  required_version = "1.4.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.64.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.65.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}
