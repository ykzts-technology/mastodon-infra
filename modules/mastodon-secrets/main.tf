resource "random_id" "secret_key_base" {
  byte_length = 64
}

resource "random_id" "otp_secret" {
  byte_length = 64
}

resource "kubernetes_secret" "mastodon" {
  data = {
    ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY   = var.active_record_encryption_key_derivation_salt
    ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT = var.active_record_encryption_deterministic_key
    ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY         = var.active_record_encryption_primary_key
    AWS_ACCESS_KEY_ID                            = var.storage_access_key
    AWS_SECRET_ACCESS_KEY                        = var.storage_secret_key
    DB_HOST                                      = var.db_hostname
    DB_PASS                                      = var.db_password
    DB_PORT                                      = var.db_port
    DB_USER                                      = var.db_username
    ES_ENABLED                                   = "true"
    ES_HOST                                      = var.es_hostname
    ES_PASS                                      = var.es_password
    ES_PORT                                      = var.es_port
    ES_USER                                      = var.es_username
    DEEPL_API_KEY                                = var.deepl_api_key
    OTP_SECRET                                   = random_id.otp_secret.hex
    REDIS_HOST                                   = var.redis_hostname
    REDIS_PASSWORD                               = var.redis_password
    REDIS_PORT                                   = var.redis_port
    S3_BUCKET                                    = var.storage_bucket
    S3_ENABLED                                   = "true"
    S3_ENDPOINT                                  = var.storage_endpoint
    S3_HOSTNAME                                  = var.storage_hostname
    S3_PROTOCOL                                  = "https"
    S3_REGION                                    = var.storage_region
    S3_MULTIPART_THRESHOLD                       = "52428800"
    S3_SIGNATURE_VERSION                         = "v4"
    SECRET_KEY_BASE                              = random_id.secret_key_base.hex
    SMTP_LOGIN                                   = "apikey"
    SMTP_PASSWORD                                = var.smtp_password
    SMTP_PORT                                    = "2525"
    SMTP_SERVER                                  = "smtp.sendgrid.net"
    VAPID_PRIVATE_KEY                            = var.vapid_private_key
    VAPID_PUBLIC_KEY                             = var.vapid_public_key
  }

  metadata {
    name = "mastodon"
  }
}
