# apps.tf
# Install basic apps to make cluster usable and be able to monitor it

provider "kubernetes" {
  version = "~> 1.12.0"
  host  = digitalocean_kubernetes_cluster.cluster.endpoint
  token = digitalocean_kubernetes_cluster.cluster.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate
  )
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "kubernetes_namespace" "ci" {
  metadata {
    name = "ci"
  }
}

provider "helm" {
  version = "~> 1.2.4"
  kubernetes {
    host  = digitalocean_kubernetes_cluster.cluster.endpoint
    token = digitalocean_kubernetes_cluster.cluster.kube_config[0].token
    cluster_ca_certificate = base64decode(
      digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate
    )
  }
}

resource "helm_release" "ingress_nginx" {
  repository = "https://kubernetes.github.io/ingress-nginx"
  name       = "ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  set {
    name  = "controller.publishService.enabled"
    value = "true"
  }
}

resource "helm_release" "prometheus_operator" {
  repository = "https://kubernetes-charts.storage.googleapis.com"
  name       = "prometheus-operator"
  chart      = "prometheus-operator"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
}

resource "kubernetes_ingress" "grafana" {
  metadata {
    name       = "grafana"
    namespace  = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = format("grafana.%s", var.environment.domain)
      http {
        path {
          backend {
            service_name = "prometheus-operator-grafana"
            service_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress" "prometheus" {
  metadata {
    name       = "prometheus"
    namespace  = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = format("prometheus.%s",var.environment.domain)
      http {
        path {
          backend {
            service_name = "prometheus-operator-prometheus"
            service_port = 9090
          }
        }
      }
    }
  }
}

