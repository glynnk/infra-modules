# main.tf

#terraform {
#  required_providers {
#    digitalocean = {
#      source = "digitalocean/digitalocean"
#      version = "1.22.2"
#      token = var.environment.token
#    }
#  }
#}
provider "digitalocean" {
  token = var.environment.token
}
