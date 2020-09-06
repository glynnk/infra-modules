# cluster.tf
# Provision the Kubernetes cluster

resource "digitalocean_kubernetes_cluster" "cluster" {
  name         = format("%s-cluster", var.environment.name)
  region       = var.environment.region
  auto_upgrade = var.environment.cluster.auto_upgrade
  version      = var.environment.cluster.kubernetes_version
  vpc_uuid     = digitalocean_vpc.vpc.id

  tags = [format("%s-cluster", var.environment.name)]

  # This default node pool is mandatory
  node_pool {
    name       = "default-pool"
    size       = "s-1vcpu-2gb"
    auto_scale = false
    node_count = var.environment.cluster.default_node_pool_size
    tags       = [
      format("%s-cluster", var.environment.name),
      format("%s-default-pool", var.environment.name),
      format("%s-kube-node", var.environment.name),
      "kube-node"
    ]

    labels = {
      service  = "default"
      priority = "high"
    }
  }
}

# Another node pool for applications
resource "digitalocean_kubernetes_node_pool" "cluster_node_pool" {
  cluster_id = digitalocean_kubernetes_cluster.cluster.id
  name = format("%s-node-pool", var.environment.name)
  size = "s-2vcpu-2gb"

  tags = [
    format("%s-cluster", var.environment.name),
    format("%s-app-pool", var.environment.name),
    format("%s-kube-node", var.environment.name),
    "kube-node"
  ]

  # autoscaling
  auto_scale = true
  min_nodes  = var.environment.cluster.app_node_pool_size_min
  max_nodes  = var.environment.cluster.app_node_pool_size_max

  labels = {
    service  = "apps"
    priority = "high"
  }
}

