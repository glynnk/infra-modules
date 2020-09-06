# domain.tf
# Provision the domain and records

resource "digitalocean_domain" "domain" {
  name       = var.root.domain
}


