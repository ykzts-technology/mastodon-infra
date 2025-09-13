terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.49.3"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.49.3"
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
