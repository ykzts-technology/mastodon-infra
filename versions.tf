terraform {
  required_version = "1.3.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.53.1"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.53.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.18.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}
