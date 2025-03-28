# 🚀 Deploy PostgreSQL on GKE with Terraform  

This package provides instructions for creating a multi zone redundant stateful implementation of postgresql thru Helm
using Google Cloud GKE Vertically Autoscaling Cluster, it uses the reference samples and best practice steps provided by google cloud docs See [Here](https://github.com/aziouk/kubernetes-engine-samples) for more and a link to the original GoogleCloudPlatform repo.

The scripts here will allow you to perform step-by-step for **Google Kubernetes Engine (GKE) cluster** and a **PostgreSQL database** using **Terraform & Helm**.  




## 📌 Prerequisites  

### ✅ Required Software  
Ensure you have the following installed:  

| Dependency         | Purpose                                          | Install Command |
|-------------------|------------------------------------------------|----------------|
| **Terraform** (≥ 1.0) | Infrastructure as Code (IaC) tool to provision GKE | `brew install terraform` (Mac) / [Download](https://developer.hashicorp.com/terraform/downloads) |
| **Google Cloud SDK** | CLI tool to manage Google Cloud resources | `brew install --cask google-cloud-sdk` (Mac) / [Install Guide](https://cloud.google.com/sdk/docs/install) |
| **kubectl** | CLI for managing Kubernetes clusters | `gcloud components install kubectl` |
| **Helm (≥ v3)** | Package manager for Kubernetes (needed for PostgreSQL deployment) | `brew install helm` / [Install Guide](https://helm.sh/docs/intro/install/) |
| **jq** | JSON parser (for debugging outputs) | `brew install jq` |
| **gsutil** | CLI tool to manage Google Cloud Storage (if using GCS for secrets) | `gcloud components install gsutil` |

---

### ✅ Enable Required Google Cloud APIs  
Run the following command to enable required APIs:  
```bash
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  iam.googleapis.com \
  secretmanager.googleapis.com  # If using Google Secret Manager
```bash

## ⚡ Quick Start  

### **1️⃣ Installation/Setup & Usage **  

```bash
git clone https://github.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation
cd kubernetes-autopilot-cluster-helm-postgresql-automation/gke-stateful-postgres
```bash

## ✅ Required IAM Permissions  

The following IAM permissions are required to deploy the GKE cluster and PostgreSQL database:

```yaml
roles/iam.serviceAccountUser
roles/container.admin
roles/compute.networkAdmin
roles/storage.admin
roles/cloudsql.admin
roles/resourcemanager.projectIamAdmin
roles/viewer
```yaml




