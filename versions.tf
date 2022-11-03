terraform {
  required_version = "1.3.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.42.1"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.42.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.15.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}
