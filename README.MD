# 🚀 Deploy PostgreSQL on GKE with Terraform 

## What this is
This package provides instructions and automation for implementing multi region, redundant, stateful Google Cloud GKE Cluster with Helm Charts (postgresql in this example), including deploy examples with and without autopilot, with Disaster Recover and without Diaster Recovery backup.
This github repo collection uses the reference samples and best practice steps provided by google cloud. See [Here](https://github.com/aziouk/kubernetes-engine-samples) for the forked subrepo we are maintaining, and a link to the original [GoogleCloudPlatform samples repo](https://github.com/GoogleCloudPlatform/kubernetes-engine-samples). For ease of access Google Cloud's kubernetes-engine-samples is forked and implemented into this repos as the subrepo [kubernetes-engine-samples folder](https://github.com/aziouk/kubernetes-engine-samples/tree/58e9d6995a22be4a1f776b3361e53884caa2d53e). For our purposes we are interested in gke-stateful-postgres configurations, which the unaltered google cloud referenced is refered to in the surepo kubernetes-engine-samples. 

Future versions of this repository will implement only kubernetes-engine-samples subrepo, i.e. will not provide the convenient gke-stateful-postgres in the root of this repository. This will be to ensure/allow others commit their template changes to all repos reusing the subrepo fork of the google cloud build references mentioned above, this ensures other repos using the subrepo automation will always commit to the subrepo to the benefit of any other repos using the subrepo includes. This seemed to make most sense from a maintenace perspective, as it seems at least on first glance reconcilation loops can create some very resistant applications, ease of maintenance, legibility, code recycling and ease of revisioning seem like priorities to reduce unnecessary complexity or obfuscation of the build process. It seems, at least to me, utlising subrepos is uniquely suitable and important in managing consistent templates accross a large infrastructure.

This resource aims to facilitate applying and destroying **Google Kubernetes Engine (GKE) cluster** and a **Helm charts** in the two components listed below. 

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
| **docker** | Local version of docker required to be installed and running | `yum install docker` |

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
The Helm installer provided (helm_deploy_postgres.sh) will automate the docker image pull and installation to the GKE Cluster using the setenv project variables, and is integrated with the google cloud tool. The additional requirement is a local docker installation is required, even though your pushing to remote, you need it on the controlling machine to communicate with the instances in gcloud. I had some issues with imagepulls but it seems its because I am over the quota of my free account after looking into it.

However a summary of the tasks it performs are included below for your reference. 


```bash
chmod +x helm_deploy_postgres.sh
./helm_deploy_postgres.sh
```

## Summary

There are two main components at present, the first piece of the automation is <mark> Google Cloud GKE Cluster terraform build component</mark> and the second the <mark>kube-credentials-handler-docker-image-deploy-chart</mark> installer component (helm_deploy_postgres.sh), which carries out the necessary tasks to install charts. It is possible to integrate both processes into one terraform installer file if desired, however it may be also potentially useful to build cluster components seperately from the image-docker automation, since their tasks are mutually exclusive, this way code can be more easily recycled for further utility benefit. That way the first component of GKE cluster automation could be used, adapted, templated for implementation of all (or most) clusters, and the helm installer component could be easily adapted for re-use with any other charts for GKE Cluster. This approach seemed like the most time efficient approach as of yet, without unnecessarily reinventing wheel or causing arbitrary restrictions with the implementation of the two components.

## Comments

I do not have a lot of experience with Terraform and Helm Devops on GCP, and this my first adventure in it, but the scripts split up this way should be helpful for anyone wanting to understand, build or experiment with google GKE Clusters with and without autopilot, with and without DR, and with postgressql or any other chart. The 2 components therefore allow this script to be forked and could install theoretically any chart onto a GKE cluster for which a chart-docker-repo exists for kubernetes. Although I am less familiar with this approach the kubernetes-docker approach seems very streamlined and is uniquely useful for price optimized stateful approach to cloud app implementations. Certainly I see there is a lot to learn about GCP Kubernetes containerised abilities compared with my previous experience mainly in dedicated and openstack cloud.

## Common Errors

Unfortunately because my account has several quota limits with the number of times I can spin up and down automation. I reached the limit of my quota pretty fast. Here are common errors that you will see, that are *not* a result of the automation failing, but potential barriers from untainted builds with the terraform/helm automation included. This seems especially relevant to the ha scaling quota specifically. See below for common issues;

* Pod is blocking scale down because it doesn't have enough pod disruption budget (PDB) 
* Pod is blocking scale down because its controller can't be found. 
* Can't scale up because node auto-provisioning can't provision a node pool for the pod if it would exceed resource limits. 
* Can't scale up because node auto-provisioning can't provision a node pool for a pod with failing predicates 
* Can't scale up a node pool because of a failing scheduling predicate 
* Can't scale up due to exceeded quota 

