terraform {
  required_version = "1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.37.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.38.0"
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
