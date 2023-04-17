terraform {
  required_version = "1.4.4"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.62.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.61.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.19.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}
