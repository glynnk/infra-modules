# registry.tf
# Create the container registry
resource "digitalocean_container_registry" "registry" {
  name = var.root.registry_name
}

