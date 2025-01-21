terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.17.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}
