resource "random_id" "secret_key_base" {
  byte_length = 64
}

resource "random_id" "otp_secret" {
  byte_length = 64
}

resource "kubernetes_secret" "mastodon_credentials" {
  data = {
    otp-secret        = random_id.otp_secret.hex
    secret-key-base   = random_id.secret_key_base.hex
    vapid-private-key = var.vapid_private_key
    vapid-public-key  = var.vapid_public_key
  }

  metadata {
    name = "mastodon-credentials"
  }
}

resource "kubernetes_secret" "cloudsql_db_credentials" {
  data = {
    hostname = var.db_hostname
    password = var.db_password
    port     = var.db_port
    username = var.db_username
  }

  metadata {
    name = "cloudsql-db-credentials"
  }
}

resource "kubernetes_secret" "redislabs_credentials" {
  data = {
    hostname = var.redis_hostname
    password = var.redis_password
    port     = var.redis_port
  }

  metadata {
    name = "redislabs-credentials"
  }
}

resource "kubernetes_secret" "sendgrid_smtp_credentials" {
  data = {
    password = var.smtp_password
  }

  metadata {
    name = "sendgrid-smtp-credentials"
  }
}

resource "kubernetes_secret" "cloudstorage_credentials" {
  data = {
    access-key = var.storage_access_key
    secret-key = var.storage_secret_key
  }

  metadata {
    name = "cloudstorage-credentials"
  }
}
