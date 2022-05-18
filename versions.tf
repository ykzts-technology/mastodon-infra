terraform {
  required_version = "1.1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.21.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.21.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.11.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.2.0"
    }
  }
}
