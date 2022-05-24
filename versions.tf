terraform {
  required_version = "1.2.1"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.22.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.22.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.11.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.3"
    }
  }
}
