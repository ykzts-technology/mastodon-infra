terraform {
  required_version = "1.4.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.61.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.60.2"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.19.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}
