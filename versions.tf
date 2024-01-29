terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.14.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "5.14.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.25.2"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}
