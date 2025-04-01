terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Region of the source cluster"
  type        = string
}

variable "dr_region" {
  description = "Disaster recovery target region"
  type        = string
}

variable "source_cluster" {
  description = "Name of the source PostgreSQL cluster"
  type        = string
}

variable "target_cluster" {
  description = "Name of the target PostgreSQL cluster"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for backup and restore plans"
  type        = string
}

resource "google_gke_backup_backup_plan" "backup_plan" {
  name     = "${var.name_prefix}-bkp-plan-01"
  location = var.dr_region
  cluster  = "projects/${var.project_id}/locations/${var.region}/clusters/${var.source_cluster}"

  retention_policy {
    backup_delete_lock_days = 0
    backup_retain_days      = 7
  }

  backup_schedule {
    cron_schedule = "0 3 * * *" # Runs daily at 3 AM
  }

  backup_config {
    include_secrets      = true
    include_volume_data  = true
    selected_namespaces  = ["postgresql"]
  }
}

resource "google_gke_backup_backup" "manual_backup" {
  name          = "bkp-${google_gke_backup_backup_plan.backup_plan.name}"
  location      = var.dr_region
  backup_plan   = google_gke_backup_backup_plan.backup_plan.id
  wait_for_completion = true
}

resource "google_gke_backup_restore_plan" "restore_plan" {
  name     = "${var.name_prefix}-rest-plan-01"
  location = var.dr_region
  backup_plan = google_gke_backup_backup_plan.backup_plan.id
  cluster = "projects/${var.project_id}/locations/${var.dr_region}/clusters/${var.target_cluster}"

  cluster_resource_conflict_policy = "USE_EXISTING_VERSION"
  namespaced_resource_restore_mode = "DELETE_AND_RESTORE"
  volume_data_restore_policy       = "RESTORE_VOLUME_DATA_FROM_BACKUP"
}

resource "google_gke_backup_restore" "restore" {
  name          = "rest-${google_gke_backup_restore_plan.restore_plan.name}"
  location      = var.dr_region
  restore_plan  = google_gke_backup_restore_plan.restore_plan.id
  backup        = google_gke_backup_backup.manual_backup.id
  wait_for_completion = true
}
