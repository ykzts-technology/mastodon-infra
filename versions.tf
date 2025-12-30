terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.50.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.50.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}
