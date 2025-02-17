terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "2.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"  # Ensure this points to your cluster
}

data "external" "grafana_password" {
  program = ["bash", "-c", "echo '{\"password\": \"'$(kubectl get secret --namespace monitoring grafana -o jsonpath='{.data.admin-password}' | base64 --decode)'\"}'"]
}

provider "grafana" {
  url  = "http://grafana.local"
  auth = "admin:${data.external.grafana_password.result.password}"
}
