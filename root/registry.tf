# registry.tf
# the container registry

resource "digitalocean_container_registry" "registry" {
  name = var.root.name
}

