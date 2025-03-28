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

##Specific IAM Permissions (Updated 28/03/2025)
It appears there has been several changes to IAM that make these permissions more granular. 

Carefully note the google reference [here](https://cloud.google.com/kubernetes-engine/docs/tutorials/stateful-workloads/postgresql#autopilot) contains significant inaccuracies and typos, for example <mark>role/artifactregistry.Admin</mark> should be prefixed by <mark>roles/</mark> not role/ and secondly is actually named <mark>artifactregistry.repoAdmin</mark> not artifactregistry.repo</mark> as of 28/03/2025. It seems that the Google Clouds SDK own documentation repository is floating unworkable example templates which are maintained by nobody, or it is just not big priority for them. 

Of course if they performed unit tests on their documentation and it's referenced templates such issues could be caught. It seems though - google doesn't really care about accurate and trouble-free documentation for their products. This seems to be because of the rate the software changes.

bash```
# Creating the necessary IAM bindings;
[root@localhost 3-predictx-postgresdb]# gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:adam@<email>" --role=roles/storage.objectViewer

[root@localhost 3-predictx-postgresdb]# gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:adam@<email>" --role=roles/logging.logWriter

[root@localhost 3-predictx-postgresdb]# gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:adam@<email>" --role=roles/artifactregistry.reader

[root@localhost 3-predictx-postgresdb]# gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:adam@<email>" --role=roles/artifactregistry.writer

[root@localhost 3-predictx-postgresdb]# gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<emali>" --role=roles/artifactregistry.repoAdmin

[root@localhost 3-predictx-postgresdb]# gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<mail>" --role=roles/container.clusterAdmin

[root@localhost 3-predictx-postgresdb]# gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/serviceusage.serviceUsageAdmin

[root@localhost 3-predictx-postgresdb]# gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/iam.serviceAccountAdmin
```bash



