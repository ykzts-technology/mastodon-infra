module "address-fe" {
  source  = "terraform-google-modules/address/google"
  version = "4.1.0"

  address_type = "EXTERNAL"
  global       = true
  ip_version   = "IPV4"
  names        = ["${local.default_name}-ip"]
  project_id   = var.project_id
  region       = var.region
}

module "dns-public-zone" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "6.1.0"

  dnssec_config = {
    kind          = "dns#managedZoneDnsSecConfig"
    non_existence = "nsec3"
    state         = "on"
  }
  domain     = "${var.domain}."
  name       = local.default_name
  project_id = var.project_id
  recordsets = [
    {
      name    = ""
      records = module.address-fe.addresses
      ttl     = 7200
      type    = "A"
    },
    {
      name    = ""
      records = ["10 . alpn=\"h3,h2\""]
      ttl     = 7200
      type    = "HTTPS"
    },
    {
      name    = "www"
      records = ["edge.redirect.pizza."]
      ttl     = 3600
      type    = "CNAME"
    },
    {
      name    = "files"
      records = module.address-fe.addresses
      ttl     = 7200
      type    = "A"
    },
    {
      name    = "files"
      records = ["10 ${var.domain}. alpn=\"h3,h2\""]
      ttl     = 7200
      type    = "HTTPS"
    },
    {
      name    = ""
      records = ["0 issue \"pki.goog\"", "0 issue \"sectigo.com\"", "0 issue \"letsencrypt.org\""]
      ttl     = 7200
      type    = "CAA"
    },
    # GitHub
    {
      name    = "_github-challenge-ykzts-technology-organization"
      records = ["a0fb7df9f0"]
      ttl     = 3600
      type    = "TXT"
    },
    # SendGrid
    {
      name    = "em7827"
      records = ["u26458027.wl028.sendgrid.net."]
      ttl     = 3600
      type    = "CNAME"
    },
    {
      name    = "s1._domainkey"
      records = ["s1.domainkey.u26458027.wl028.sendgrid.net."]
      ttl     = 3600
      type    = "CNAME"
    },
    {
      name    = "s2._domainkey"
      records = ["s2.domainkey.u26458027.wl028.sendgrid.net."]
      ttl     = 3600
      type    = "CNAME"
    },
    # Resend
    {
      name    = "send"
      records = ["10 feedback-smtp.ap-northeast-1.amazonses.com."]
      ttl     = 3600
      type    = "MX"
    },
    {
      name    = "send"
      records = ["v=spf1 include:amazonses.com ~all"]
      ttl     = 3600
      type    = "TXT"
    },
    {
      name    = "resend._domainkey"
      records = ["p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCuoKvci5vFBB22v1jKg+BwiRE8rfvcABg/jLucX/nVhI4wnmN+DJOG/P8Yfp3EQlsMEjhK6PsXOipm0wIc2KLvcHTESaCkbwBzBb3r8DiW3FQvPBkPCzYQtiFFWRWYWLq4G+YZ/imA0clFBJMuUTJi2M7uzFND8j6mCymTqB2ZUwIDAQAB"]
      ttl     = 3600
      type    = "TXT"
    },
    {
      name    = "_dmarc"
      records = ["\"v=DMARC1;\" \"p=reject;\" \"rua=mailto:dmarc_agg@vali.email\""]
      ttl     = 3600
      type    = "TXT"
    },
  ]
  type = "public"
}
