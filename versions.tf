terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.22.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "5.22.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}
