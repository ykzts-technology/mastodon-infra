resource "random_id" "secret_key_base" {
  byte_length = 64
}

resource "random_id" "otp_secret" {
  byte_length = 64
}

resource "kubernetes_secret" "mastodon" {
  data = {
    AWS_ACCESS_KEY_ID      = var.storage_access_key
    AWS_SECRET_ACCESS_KEY  = var.storage_secret_key
    DB_HOST                = var.db_hostname
    DB_PASS                = var.db_password
    DB_PORT                = var.db_port
    DB_USER                = var.db_username
    ES_ENABLED             = "true"
    ES_HOST                = var.es_hostname
    ES_PASS                = var.es_password
    ES_PORT                = var.es_port
    ES_USER                = var.es_username
    DEEPL_API_KEY          = var.deepl_api_key
    OTP_SECRET             = random_id.otp_secret.hex
    REDIS_HOST             = var.redis_hostname
    REDIS_PASSWORD         = var.redis_password
    REDIS_PORT             = var.redis_port
    S3_BUCKET              = var.storage_bucket
    S3_ENABLED             = "true"
    S3_ENDPOINT            = var.storage_endpoint
    S3_HOSTNAME            = var.storage_hostname
    S3_PROTOCOL            = "https"
    S3_REGION              = var.storage_region
    S3_MULTIPART_THRESHOLD = "52428800"
    S3_SIGNATURE_VERSION   = "v4"
    SECRET_KEY_BASE        = random_id.secret_key_base.hex
    SMTP_FROM_ADDRESS      = "Mastodon <notifications@ykzts.technology>"
    SMTP_LOGIN             = "apikey"
    SMTP_PASSWORD          = var.smtp_password
    SMTP_PORT              = "2525"
    SMTP_SERVER            = "smtp.sendgrid.net"
    VAPID_PRIVATE_KEY      = var.vapid_private_key
    VAPID_PUBLIC_KEY       = var.vapid_public_key
  }

  metadata {
    name = "mastodon"
  }
}


// deprecated

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

resource "kubernetes_secret" "deepl_credentials" {
  data = {
    api-key = var.deepl_api_key
  }

  metadata {
    name = "deepl-credentials"
  }
}
