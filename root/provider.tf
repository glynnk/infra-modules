# main.tf
# Configure the DigitalOcean Provider
# terraform init

terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "1.22.2"
    }
  }
}
