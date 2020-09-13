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

# Install ingress nginx load balancer and external-dns

provider "helm" {
  version = "~> 1.2.4"
  kubernetes {
    load_config_file       = false
    host                   = digitalocean_kubernetes_cluster.cluster.endpoint
    token                  = digitalocean_kubernetes_cluster.cluster.kube_config[0].token
    cluster_ca_certificate = base64decode(
      digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate
    )
  }
}

resource "helm_release" "ingress_nginx" {
  repository       = "https://kubernetes.github.io/ingress-nginx"
  name             = "ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.publishService.enabled"
    value = "true"
  }
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  chart      = "stable/external-dns"

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "provider"
    value = "digitalocean"
  }

  set {
    name  = "interval"
    value = "1m"
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "digitalocean.apiToken"
    value = var.environment.token
  }
}

resource "helm_release" "cert_manager" {
  depends_on       = [ helm_release.ingress_nginx ]
  repository       = "https://charts.jetstack.io"
  name             = "cert-manager"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  version          = "v1.0.1"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "helm_release" "prometheus_operator" {
  repository       = "https://kubernetes-charts.storage.googleapis.com"
  name             = "prometheus-operator"
  chart            = "prometheus-operator"
  namespace        = "monitoring"
  create_namespace = true
}

resource "helm_release" "public_ingresses" {
  depends_on = [ helm_release.cert_manager ]
  name             = "public-ingresses"
  chart            = "./.terraform/modules/dev/environment/charts/public-ingresses"

  set {
    name  = "email"
    value = var.environment.email
  }

  set {
    name  = "hosts.grafana"
    value = format("grafana.%s.%s", var.environment.name, var.environment.domain) 
  }

  set {
    name  = "hosts.prometheus"
    value = format("prometheus.%s.%s", var.environment.name, var.environment.domain) 
  }
}

