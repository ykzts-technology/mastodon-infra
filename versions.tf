terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.1.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "7.1.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}
