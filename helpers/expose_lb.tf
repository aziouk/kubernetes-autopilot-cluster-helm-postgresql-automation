# Exposing private GKE cluster to a public IP routable

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"  # Use a version below 5.0
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"  # Use a compatible version for Kubernetes provider
    }
  }
}

# Google Cloud provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_container_cluster" "gke_cluster" {
  name     = "cluster-db1"
  location = var.region
}


# Kubernetes provider configuration using gcloud credentials
provider "kubernetes" {
  # Default config will automatically use the gcloud credentials set up
  # No need to explicitly set 'load_config_file', it'll use your default kubeconfig context
}
resource "kubernetes_service" "postgres_service" {
  metadata {
    name = "postgres-service"
  }

  spec {
    selector = {
      "app.kubernetes.io/instance" = "postgresql"  # Make sure this matches your StatefulSet's labels
    }

    port {
      port        = 5432
      target_port = 5432
    }

    type = "LoadBalancer"
  }
}

# Output the project_id to confirm it was set correctly
output "project_id" {
  value = var.project_id
}
