terraform {
  required_version = "1.5.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.73.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.73.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}
