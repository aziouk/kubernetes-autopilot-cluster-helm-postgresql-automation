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
  version = "< 5.0"  # This will use any version below v5.0
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  host                   = data.google_container_cluster.gke_cluster.endpoint
  cluster_ca_certificate = base64decode(data.google_container_cluster.gke_cluster.master_auth[0].cluster_ca_certificate)
  load_config_file       = false
}


# Use the default client config to get credentials for the GKE cluster
#data "google_client_config" "default" {}

# Get the credentials for the GKE cluster
data "google_container_cluster" "gke_cluster" {
  name     = "postgresql-postgresql-ha-postgresql"  # Your GKE cluster name
  location = var.region
}


# Expose the existing PostgreSQL StatefulSet as a LoadBalancer service
resource "kubernetes_service" "postgres_service" {
  metadata {
    name = "postgres-service"
  }

  spec {
    selector = {
      "app.kubernetes.io/component" = "postgresql"  # Match the label for your StatefulSet pods
      "app.kubernetes.io/instance"  = "postgresql"
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/name"      = "postgresql-ha"
      "app.kubernetes.io/version"   = "16.0.0"  # Adjust if necessary
      "role"                        = "data"  # Adjust if necessary
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
