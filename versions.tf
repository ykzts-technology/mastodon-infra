terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.21.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "7.21.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
  }
}
