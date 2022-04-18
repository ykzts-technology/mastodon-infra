terraform {
  required_version = "1.1.8"

  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.17.0"
    }
  }
}
