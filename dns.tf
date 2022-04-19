module "address-fe" {
  source  = "terraform-google-modules/address/google"
  version = "3.1.1"

  address_type = "EXTERNAL"
  global       = true
  ip_version   = "IPV4"
  names        = ["${var.name}-ip"]
  project_id   = var.project_id
  region       = var.region
}

module "dns-public-zone" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "4.1.0"

  dnssec_config = {
    kind          = "dns#managedZoneDnsSecConfig"
    non_existence = "nsec3"
    state         = "on"
  }
  domain     = "${var.domain}."
  name       = var.name
  project_id = var.project_id
  recordsets = [
    {
      name    = ""
      records = module.address-fe.addresses
      ttl     = 7200
      type    = "A"
    },
    {
      name    = "www"
      records = module.address-fe.addresses
      ttl     = 7200
      type    = "A"
    },
    {
      name    = "files"
      records = module.address-fe.addresses
      ttl     = 7200
      type    = "A"
    },
    {
      name    = ""
      records = ["0 issue \"pki.goog\""]
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
    {
      name    = "_dmarc"
      records = ["v=DMARC1; p=reject"]
      ttl     = 3600
      type    = "TXT"
    },
  ]
  type = "public"
}
