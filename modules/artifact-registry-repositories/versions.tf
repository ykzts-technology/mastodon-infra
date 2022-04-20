terraform {
  required_version = "1.1.9"

  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.18.0"
    }
  }
}
