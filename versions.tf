terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.22.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.22.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
  }
}
