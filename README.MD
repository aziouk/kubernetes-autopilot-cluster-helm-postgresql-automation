# 🚀 Deploy PostgreSQL on GKE with Terraform

## TLDR
This package provides instructions for creating a multi region redundant stateful implementation of postgresql thru Helm, with and without autopilot, with DR and without DR backup.
We are using Google Cloud GKE Vertically Autoscaling Cluster, it uses the reference samples and best practice steps provided by google cloud docs See [Here](https://github.com/aziouk/kubernetes-engine-samples) for more and a link to the original GoogleCloudPlatform samples repo.

The scripts carefully explained eblow will allow you to perform step-by-step terraform build and teardown of **Google Kubernetes Engine (GKE) cluster** and a **PostgreSQL database** using **Terraform & Helm**. 

##More Detail

There are two main components at present, the first piece of the automation is <mark> terraform</mark> and the second component is the helm installer script (helm_deploy_postgres), which carries out the necessary tasks to install charts. It could be possible to integrate both processes into one terraform installer file, however it may be useful to build clusters component seperately from the image-docker automation, since their tasks are mutually exclusive. That way the first component of GKE cluster automation could be used for implementation of all (or most) clusters, and the helm installer component could be easily adapted for re-use with any other charts in GKE Cluster, which is a more modular approach to the development process and flexibility/reuse of code. This seemed like the most time efficient approach as of yet. 

I do not have a lot of experience with Terraform and Helm Devops on GCP, and this my first adventure in it, but the scripts split up this way should be helpful for anyone wanting to understand, build or experiment with google GKE Clusters with and without autopilot, with and without DR, and with postgressql or any other chart. The 2 components therefore allow this script to be forked and could install theoretically any chart onto a GKE cluster for which a chart-docker-repo exists for kubernetes. Although I am less familiar with this approach the kubernetes-docker approach seems very streamlined and is uniquely useful for price optimized stateful approach to cloud app implementations. Certainly I see there is a lot to learn about GCP Kubernetes containerised abilities compared with my previous experience mainly in dedicated and openstack cloud.

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
``` 
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  iam.googleapis.com \
  secretmanager.googleapis.com  # If using Google Secret Manager
```

## ⚡ Quick Start

### **1️⃣ Installation/Setup & Usage **

```
git clone https://github.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation
cd kubernetes-autopilot-cluster-helm-postgresql-automation/gke-stateful-postgres
```

## ✅ Required IAM Permissions

The following IAM permissions are required to deploy the GKE cluster and PostgreSQL database:

```
roles/iam.serviceAccountUser
roles/container.admin
roles/compute.networkAdmin
roles/storage.admin
roles/cloudsql.admin
roles/resourcemanager.projectIamAdmin
roles/viewer
```

## Trouble with Googles Example Templates Failing (Updated 28/03/2025)
It appears there has been several changes and google has not updated their documentation. :(

Carefully noting the Google Cloud reference [here](https://cloud.google.com/kubernetes-engine/docs/tutorials/stateful-workloads/postgresql#autopilot) contains significant inaccuracies and typos, for example <mark>role/artifactregistry.Admin</mark> should be prefixed by <mark>roles/</mark> not role/ and secondly is actually named <mark>artifactregistry.repoAdmin</mark> not artifactregistry.repo</mark> as of 28/03/2025. It seems that the Google Clouds SDK own documentation repository is floating unworkable example templates which are not maintained by anyone, or it is just not a big priority for them.

If google unit tested their referenced templates against their own cloud account, like other cloud providers do, then such issues could be caught and prevented. I suppose there is something ironic about a stateful template failing to achieve a workable state from the documentation of the cloud provider that invented the product, but we should cocentrate on the changes below;
# Creating the necessary IAM bindings
Replacing <mail> with the desired service account user
``` 
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/storage.objectViewer
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/logging.logWriter
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/artifactregistry.reader
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/artifactregistry.writer
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/artifactregistry.repoAdmin
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/container.clusterAdmin
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/serviceusage.serviceUsageAdmin
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/iam.serviceAccountAdmin
```
# Install GKE Region Cluster with Autopilot (with DR) 
By using autopilot it is possible to build a multi region cluster with a redundant backup and nodes in seperate regions, as well as receive additional data for logging and analytics.
```
terraform -chdir=terraform/gke-autopilot init -var project_id=predictx-postgrescluster
terraform -chdir=terraform/gke-autopilot plan -var project_id=predictx-postgrescluster
terraform -chdir=terraform/gke-autopilot apply -var project_id=predictx-postgrescluster
```


# Install GKE Cluster without Autopilot (without DR)
```
terraform -chdir=terraform/gke-standard init
terraform -chdir=terraform/gke-standard plan -var project_id=$PROJECT_ID
terraform -chdir==terraform/gke-standard apply -var project_id=$PROJECT_ID

```
## Helm Installer for PostgreSQL
To apply postgresql images and prepare the GKE cluster for ha a convenient ./helm_deploy_postgres.sh script is provided. However a summary of the tasks it performs are included below for your reference. 

<mark>Simply run ./helm_deploy_postgres.sh and the below steps are automatically carried out.</mark>

```bash
chmod +x helm_deploy_postgres.sh
./helm_deploy_postgres.sh




```

