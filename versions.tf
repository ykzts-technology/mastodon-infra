terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.42.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.43.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}
