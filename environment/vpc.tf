resource "digitalocean_vpc" "vpc" {
  name     = var.environment.name
  region   = var.environment.region
}
