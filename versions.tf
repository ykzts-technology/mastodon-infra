terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.14.1"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.14.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}
