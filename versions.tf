terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.31.1"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.31.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}
