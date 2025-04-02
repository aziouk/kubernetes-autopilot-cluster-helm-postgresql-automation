# 🚀 Deploy PostgreSQL on GKE with Terraform

## What this does
This provides terraform and helm automation templates for multi region, redundant, stateful Google Cloud GKE Cluster, for PostgreSQL HA using Helm Charts and Docker-Kubernetes as a deployment strategy. At present the script deploys 2 GKE clusters. (cluster-db1 a presetup postgresql ha group of 3 nodes per pool) and the other (cluster-db2 barebones) is a standby gke-build with nearly identical settings. Deployment is regional, but support exists for highly customizable configurations including regional or zonal clusters, defined node location groupings, definitions of num nods per pool, num_replicas, random selection of available zones in regions and much more. In future versions I anticipate many of these settings will be passable directly to the autoinstaller.sh or as terraform/helm vars for maximal infrastructure as cloud automation.

This github repo collection uses the reference samples from google cloud. We have forked it at https://github.com/aziouk/kubernetes-engine-samples and that fork is a subrepo of this repo. The GoogleCloudPlatform samples repo can be found [here](https://github.com/GoogleCloudPlatform/kubernetes-engine-samples).

Future versions of this repository will implement only kubernetes-engine-samples subrepo, and the gke-stateful-postgres folder in the root of this repository will disappear, and reappear at <mark>kubernetes-engine-samples/databases/gke-stateful-postgres</mark> instead. This will ensure changes will be more consistent and the subrepo can be used for global changes.

This resource consists of two components 1. Terraform Templates for **Google Kubernetes Engine (GKE) cluster** and 2. **Helm charts** Autoinstaller for bootstrapping Terraform Built GKE Cluster in the same namespace.

## 📌 Prerequisites

### ✅ Required Software
To run this script 1. gcloud and its dependencies must be installed. 2. gcloud cli is authenticated 3. Recommended to set a blank project. The default setenv project_id is predictx-postgrescluster. If you would like to use a different project_id you can do that by altering the project_id value in setenv.sh. 4. You must preset the GSM secrets $DB_PASSWORD, $DB_NAME for use with the postgresql ha chart. An example of GSM initialization can be found below if you have difficulty. To clarify HELM uses GSM Secrets and they <mark> must be set </mark>
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


# ⚡ Quick Start
Before using the Quick Start installers please view the prequisites and ~~GSM Setup needed for the automation components to run securely~~ (in latest version it is automatic, once vars are set right). If you have initialized GSM and installed the pre-requirements you can proceed immediately to the [install section](https://github.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation/tree/master?tab=readme-ov-file#install-method-1). In future installers GSM for the role will be installed automatically via terraform the way the other roles are added by the gke-standard and gke-autopilot scripts at build time.

# Install Method 1
```sh
wget https://raw.githubusercontent.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation/refs/heads/master/autoinstaller.sh
cat autoinstaller.sh
chmod +x ./autoinstaller.sh && ./autoinstaller.sh
```
# Install Method 2
```bash
curl -s https://raw.githubusercontent.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation/refs/heads/master/autoinstaller.sh | bash
```
This autoinstaller will complete the configuration of both components for google cloud GKE cluster and Helm postgres chart install.
Autoinstaller supports gke-standard cluster via terraform and helm chart postgresql. gke-autopilot not production ready yet. 

# Uninstall 
An uninstaller is built into the autoinstall, and will uninstall helm chart in your gcloud project, and destroy all terraform objects created by the autoinstaller
```
./autoinstaller.sh uninstall
```

## Initializing GSM 
<p align="left">
  <strong>⚠️ Warning:</strong> *MUST* be run at least once for helm installer to succeed. Helm Chart autoinstaller automation uses credentials from GSM to support deployment, without it builds will fail.
Replace <mark>px-user-password</mark>, <mark>px-user</mark> and <mark>px-database</mark> with desired credentials. This must be ran *before* the autoinstaller.
</p>

```bash
gcloud secrets create DB_PASSWORD --replication-policy="automatic"
#gcloud secrets create DB_USER --replication-policy="automatic" # unused at present
gcloud secrets create DB_NAME --replication-policy="automatic"
echo -n "px-user-password" | gcloud secrets versions add DB_PASSWORD --data-file=-
#echo -n "px-user" | gcloud secrets versions add DB_USER --data-file=- # unused at present,default postgres, ctrl+f and search for TERTIARY in the readme docs for more detail
echo -n "px-database" | gcloud secrets versions add DB_NAME --data-file=-

# Recommend to sanitize the plaintext password entry from BASH History something like
history -d $(history 4 | awk '{print $1}') && history -w

```

Using setenv for credential automation is possible but not recommended due to plaintext storage. A better approach is setting random variables at runtime. If deploy scripts run on a self-destructing bastion, then it might be acceptable but is not best practice. Encrypting credentials within setenv could streamline special cases and increase portability but is less reliable and more maint than using well maintained secret stores like GSM. Managing this via a bucket and helper script is also discouraged.

A preferred approach is generating random credentials at runtime, storing them in GSM, and referencing them in automation. Helm can retrieve these secrets during upgrades, avoiding plaintext exposure and manual initialization of password stores. This method seems most suitable for both production and development and is shown in the helm_deploy_postgresql.sh script. Theoretically credential initialisation should be compartementalized from the build scripts altogether. Build scripts should reference the stores expecting credentials to be pre defined already by a seperate isolated microservice, rather than risk potentially insecurely generating them at build time, as there is a period where credentials are not within GSM, for sensitive systems with pci compliance and public exposure on their network, this is problematic. Even if often undereported.

# Checking if GSM Is already set

```bash
gcloud secrets versions access latest --secret=DB_USER
gcloud secrets versions access latest --secret=DB_PASSWORD
gcloud secrets versions access latest --secret=DB_NAME
```

### ✅ ~~Enable Required Google Cloud APIs~~ Deprecated 
~~Enable the following API's in Gcloud~~ *Deprecated now automatic*

##~~✅ Required IAM Permissions~~ Deprecated

The following IAM permissions are required to deploy the GKE cluster and PostgreSQL database:

```bash
  roles/artifactregistry.admin
  roles/artifactregistry.reader
  roles/artifactregistry.repoAdmin
  roles/artifactregistry.serviceAgent
  roles/artifactregistry.writer
  roles/cloudbuild.builds.builder
  roles/compute.serviceAgent
  roles/container.clusterAdmin
  roles/container.clusterViewer
  roles/container.defaultNodeServiceAccount
  roles/container.defaultNodeServiceAgent
  roles/container.nodeServiceAccount
  roles/container.serviceAgent
  roles/containerregistry.ServiceAgent
  roles/editor
  roles/gkebackup.serviceAgent
  roles/gkehub.serviceAgent
  roles/iam.serviceAccountAdmin
  roles/iam.serviceAccountUser
  roles/logging.logWriter
  roles/monitoring.metricWriter
  roles/monitoring.viewer
  roles/networkconnectivity.serviceAgent
  roles/pubsub.serviceAgent
  roles/serviceusage.serviceUsageAdmin
  roles/stackdriver.resourceMetadata.writer
  roles/storage.objectViewer
  roles/viewer
```

# Manual Installation Details
```bash
#git clone https://github.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation
cd kubernetes-autopilot-cluster-helm-postgresql-automation/gke-stateful-postgres
```
then follow the below instructions carefully to carry out manual installation of the automation.


## ~~Creating the necessary IAM bindings~~
Replacing <mail> with the desired service account user. This is deprecated now, most of these roles should be added automatically by the terraform templates automation.
```bash
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/storage.objectViewer
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/logging.logWriter
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/artifactregistry.reader
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/artifactregistry.writer
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/artifactregistry.repoAdmin
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/container.clusterAdmin
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/serviceusage.serviceUsageAdmin
gcloud projects add-iam-policy-binding predictx-postgrescluster --member="user:<email>" --role=roles/iam.serviceAccountAdmin
```
## Install GKE Regional (or Zonal) Cluster with Autopilot (flakey)
By using autopilot it is possible to build a multi region cluster with a redundant backup and nodes in seperate regions, as well as receive additional data for logging and analytics.
```bash
#cd gke-stateful-postgres
terraform -chdir=terraform/gke-autopilot init -var project_id=predictx-postgrescluster
terraform -chdir=terraform/gke-autopilot plan -var project_id=predictx-postgrescluster
terraform -chdir=terraform/gke-autopilot apply -var project_id=predictx-postgrescluster
```


## Install GKE Regional/Zonal Cluster without Autopilot (working)
```bash
terraform -chdir=terraform/gke-standard init
terraform -chdir=terraform/gke-standard plan -var project_id=$PROJECT_ID
terraform -chdir==terraform/gke-standard apply -var project_id=$PROJECT_ID
```
## Helm Installer for PostgreSQL
The Helm installer provided by helm_deploy_postgresql.sh automates the docker image pull and installation to the GKE Cluster using the setenv project variables and project namespace in kubectl. If you have issues with image installations check your docker status in systemctl status docker. Even though your pushing to remote, you still need a docker socket locally on the controlling machine to communicate with the remote instances in gcloud forming the cluster.

<p align="left">
  <strong>⚠️ Warning:</strong> Google Cloud Documentation Examples has unmaintained/stale templates, instructions for helm dependencies scripts can not be trusted as correct.
</p>

You need to check carefully the output before proceeding with helm istallation
```bash
helm -n postgresql template postgresql .   --set global.imageRegistry="us-docker.pkg.dev/$PROJECT_ID/main"
```
The google doc dependancies are out of date, and these pulls will fail to wrong path as wrong version is used which is now missing from the repo listed. These are the changes as follows, make sure the images are there, by default they aren't retrieving the correct version specified by helm template matched chart versions in google docs. The following are used instead with this version of kubernetes builds:

```bash
./scripts/gcr.sh bitnami/postgresql-repmgr 16.6.0-debian-12-r3
./scripts/gcr.sh bitnami/postgres-exporter 0.17.1-debian-12-r2
./scripts/gcr.sh bitnami/pgpool 4.6.0-debian-12-r2
```
You don't need to run above. The all in one helm deploy postgres script will do this for you.

The goal is to make sure app.kubernetes version matches, I think, for pgpool, 4.6.0

## Helm Component now uses GSM To Store Vault information
You will need to set the DB_USER and DB_PASSWORD once, which is then used by helm_deploy_postgres.sh autoinstall script. Theoretically this step isn't necessary again once it is set, but it is important for first time setup of the cluster, and that anyone working on the project understands this component correctly from a security standpoint.


## Running Helm Automation

```bash
chmod +x helm_deploy_postgres.sh
./helm_deploy_postgres.sh
```
## Connecting to cluster-db instance with pg-client launcher

```bash
#./terraform/scripts/launch-client.sh
./scripts/launch-client.sh

#example output
Launching Pod pg-client in the namespace postgresql ...
pod/pg-client created
waiting for the Pod to be ready
Copying script files to the target Pod pg-client ...
Pod: pg-client is healthy

#start a shell session for testing
kubectl exec -it pg-client -n postgresql -- /bin/bash
```

## Populating, Testing/Benchmarking Database

```bash
#input generated db for testing
psql -h $HOST_PGPOOL -U postgres -a -q -f /tmp/scripts/generate-db.sql
#test counting rows
psql -h $HOST_PGPOOL -U postgres -a -q -f /tmp/scripts/count-rows.sql
```
## Create Database, with credentials to named postgresdb
You can run the command <mark>psql -h $HOST_PGPOOL -U postgres -a -q -f /tmp/scripts/create-user.sql</mark> maually to update user names, passwords or perform other SQL command sets. GSM is preffered for Security reasons.
```bash
[root@localhost gke-stateful-postgres]# ./scripts/launch-client.sh
Launching Pod pg-client in the namespace postgresql ...
Error from server (AlreadyExists): pods "pg-client" already exists
waiting for the Pod to be ready
Copying script files to the target Pod pg-client ...
Pod: pg-client is healthy

[root@localhost gke-stateful-postgres]# kubectl exec -it pg-client -n postgresql -- /bin/bash
I have no name!@pg-client:/$ psql -h $HOST_PGPOOL -U postgres -a -q -f /tmp/scripts/create-user.sql
CREATE DATABASE predictx;
CREATE USER "px-user" WITH ENCRYPTED PASSWORD 'px-user';
GRANT ALL PRIVILEGES ON DATABASE predictx TO "px-user";

## Confirm user added
I have no name!@pg-client:/$ psql -h $HOST_PGPOOL -U postgres -a -q -f /tmp/scripts/create-user.sql
CREATE DATABASE predictx;
psql:/tmp/scripts/create-user.sql:1: ERROR:  database "predictx" already exists
CREATE USER "px-user" WITH ENCRYPTED PASSWORD 'px-user';
psql:/tmp/scripts/create-user.sql:2: ERROR:  role "px-user" already exists
GRANT ALL PRIVILEGES ON DATABASE predictx TO "px-user";
I have no name!@pg-client:/$ quit
bash: quit: command not found
```

## Checking User Tables

```bash
[root@localhost scripts]# kubectl exec -it pg-client -n postgresql -- /bin/bash
I have no name!@pg-client:/$ psql -h $HOST_PGPOOL -U postgres -a -q
postgres=# \du
                                   List of roles
 Role name |                         Attributes                         | Member of
-----------+------------------------------------------------------------+-----------
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 px-user   |                                                            | {}
 repmgr    | Superuser, Create DB, Replication                          | {}

postgres=# exit
```

## Check Database online/version
```bash
kubectl exec -it pg-client -n postgresql -- /bin/bash -c "psql -h \$HOST_PGPOOL -U postgres -c 'SELECT version();' -a -q && echo 'PostgreSQL is running fine' || echo 'PostgreSQL is not running'"
SELECT version();
                                          version
-------------------------------------------------------------------------------------------
 PostgreSQL 16.6 on x86_64-pc-linux-gnu, compiled by gcc (Debian 12.2.0-14) 12.2.0, 64-bit
(1 row)

PostgreSQL is running fine
```

Make sure that your $NAMESPACE and $PROJECT_ID env variable is defined too.

# Check User and Data is added, alternative.
```bash
kubectl exec -it pg-client -n postgresql -- /bin/bash -c "\
psql -h \$HOST_PGPOOL -U postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='px-user';\" && \
psql -h \$HOST_PGPOOL -U px-user -d predictx -c 'SELECT 1;' -a -q && \
echo 'px-user exists and has access to the predictx database' || \
echo 'px-user does not exist or lacks access to the predictx database'"
```

As time goes by these checks will be integrated into the terraform/helm automation components.

# Prodding HA Master with pgclient
```bash
I have no name!@postgresql-postgresql-ha-postgresql-0:/$ kubectl exec -it postgresql-postgresql-ha-postgresql-0 -n postgresql -- psql -U postgres
bash: kubectl: command not found
I have no name!@postgresql-postgresql-ha-postgresql-0:/$ exit
exit
command terminated with exit code 127
[root@localhost scripts]# kubectl exec -it postgresql-postgresql-ha-postgresql-0 -n postgresql -- /bin/bash
Defaulted container "postgresql" out of: postgresql, metrics
I have no name!@postgresql-postgresql-ha-postgresql-0:/$ psql -U postgres
psql (16.6)
postgres=# \du
                             List of roles
 Role name |                         Attributes
-----------+------------------------------------------------------------
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS
 px-user   |
 repmgr    | Superuser, Create DB, Replication

postgres=#
[root@localhost scripts]# kubectl exec -it postgresql-postgresql-ha-postgresql-0 -n postgresql -- /bin/bash
Defaulted container "postgresql" out of: postgresql, metrics
I have no name!@postgresql-postgresql-ha-postgresql-0:/$ psql -U px-user -d predictx -a -q
predictx=> quit
```
Above block for debugging/testing automation for /tmp/scripts/create-user.sql and /tmp/scripts/launch-master.sh

# Automating tasks on remote pods using script copy util 
(Such as creating user, database, password in master cluster configuration.)
This seems like not the best way to do it and a plugin/addin will do it better like postgresql --set parameter variable for the existing mod etc.

```bash
# this runs as part of the autoinstaller.sh you dont need to run it
chmod +x execute-database-tasks.sh && ./execute-database-tasks.sh
```

```bash
#test performance with pgbench
export DB=postgres
pgbench -i -h $HOST_PGPOOL -U postgres $DB -s 50
#example output
dropping old tables...
creating tables...
generating data (client-side)...
5000000 of 5000000 tuples (100%) done (elapsed 73.37 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 90.44 s (drop tables 0.00 s, create tables 0.02 s, client-side generate 76.88 s, vacuum 3.16 s, primary keys 10.37 s).
```

## Configuring Monitoring Service Dashboard

```bash
echo $PROJECT_ID
#predictx-postgrescluster
gke-stateful-postgres]# cd monitoring/
gcloud monitoring dashboards create \
        --config-from-file=dashboard/postgresql-overview.json \
        --project=$PROJECT_ID
gcloud monitoring dashboards create \
        --config-from-file dashboard/gke-postgresql.json \
        --project $PROJECT_ID
```
The above script adds monitoring to your google dashboard under "Custom" Filter, Named **GKE Postgresql Cluster** and **PostgresOverview** respectively


## Configuring Alerts
It is also possible to configure email alerts with the service via terraform, this can be easily done as shown below;

```bash
cd monitoring/alerting/
terraform init
terraform plan -var project_id=$PROJECT_ID -var email_address=$EMAIL
terraform apply -var project_id=$PROJECT_ID -var email_address=$EMAIL
```

## Testing Alerts

If your using critical alerts, important to test them. This can be done easily by reattaching to the host and generating large tuple sets
```bash
[root@localhost gke-stateful-postgres]# kubectl exec -it --namespace postgresql pg-client -- /bin/bash
I have no name!@pg-client:/$ pgbench -i -h $HOST_PGPOOL -U postgres -s 200 postgres
dropping old tables...
creating tables...
generating data (client-side)...
6500000 of 20000000 tuples (32%) done (elapsed 126.58 s, remaining 262.89 s)
```

## Retrieving the Kubectl Raw
This allow you to check whether you will get the alert and its triggering profile is right etc. That is about it for now. Except that the kubectrl configuration can be obtained in raw format like
```bash
# will provide kubeconfig overview for authentication by others.
# warning command will give away your credentials
kubectl config view --raw
```

# Exporting/Transporting Kubectl config Securely
I was asked to provide kubectl config at the end of carrying out this task, so I put together small script to encrypt it via PGP symmetric encryption. Which can be easily decrypted from this repo and reused by staff who have received my email with the password.

## Encrypting Kubectl config
```
gpg --batch -c --passphrase somepassphrasehere export.secret
```
- Where export.secret is the plaintext credentials

## Decrypting Kubectl config
```
gpg --output decrypted.export.secret.plaintext --decrypt export.secret.gpg
```

(Would naturally not do this in real prod env). You will also be asked for the passphrase which I will send seperately.


# Simulating Cluster Failure and Recovery
Open a new cloud shell sessions and cofigure <mark> kubectl </mark> commandline access to primary db.
```
gcloud container clusters get-credentials $SOURCE_CLUSTER \
--region=$REGION --project=$PROJECT_ID
```
Open a screen if in a single terminal to capture postgresql events emitted by kubernetes
```
screen -S emissions kubectl get events -n postgresql --field-selector=involvedObject.name=postgresql-postgresql-ha-postgresql-0 --watch
```
ctrl a+d to detatch from emission window and attach your session to the <mark> database container </mark>
```
kubectl exec -it -n $NAMESPACE postgresql-postgresql-ha-postgresql-0 -c postgresql -- /bin/bash
```

Simulate a service failure
```
export ENTRY='/opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh'
export RCONF='/opt/bitnami/repmgr/conf/repmgr.conf'
$ENTRY repmgr -f $RCONF node service --action=stop --checkpoint
```
output should look like;
```
postgresql-repmgr 11:58:22.87 INFO  ==>

NOTICE: issuing CHECKPOINT on node "postgresql-postgresql-ha-postgresql-0" (ID: 1000)
DETAIL: executing server command "/opt/bitnami/postgresql/bin/pg_ctl -o "--config-file="/opt/bitnami/postgresql/conf/postgresql.conf" --external_pid_file="/opt/bitnami/postgresql/tmp/postgresql.pid" --hba_file="/opt/bitnami/postgresql/conf/pg_hba.conf"" -D '/bitnami/postgresql/data' -W -m fast stop"
I have no name!@postgresql-postgresql-ha-postgresql-0:/$ command terminated with exit code 137
```

Attach to the events/emissions window to verify the unhealthy failure/simulation and check that it is properly detected and restart/replaced by pods liveness readiness probes.
```
screen -x emissions
```
output should look like:
```bash
0s          Normal    Started     pod/postgresql-postgresql-ha-postgresql-0   Started container postgresql
0s          Warning   Unhealthy   pod/postgresql-postgresql-ha-postgresql-0   Liveness probe failed: psql: error: connection to server at "127.0.0.1", port 5432 failed: Connection refused...
0s          Warning   Unhealthy   pod/postgresql-postgresql-ha-postgresql-0   Readiness probe failed: psql: error: connection to server at "127.0.0.1", port 5432 failed: Connection refused...
0s          Warning   Unhealthy   pod/postgresql-postgresql-ha-postgresql-0   Liveness probe errored: rpc error: code = Unknown desc = failed to exec in container: container is in CONTAINER_EXITED state
0s          Warning   BackOff     pod/postgresql-postgresql-ha-postgresql-0   Back-off restarting failed container postgresql in pod postgresql-postgresql-ha-postgresql-0_postgresql(d8bbc667-fa96-4c82-888f-78928bed8d65)
0s          Warning   BackOff     pod/postgresql-postgresql-ha-postgresql-0   Back-off restarting failed container postgresql in pod postgresql-postgresql-ha-postgresql-0_postgresql(d8bbc667-fa96-4c82-888f-78928bed8d65)
0s          Normal    Pulled      pod/postgresql-postgresql-ha-postgresql-0   Container image "us-docker.pkg.dev/predictx-postgrescluster/main/bitnami/postgresql-repmgr:16.6.0-debian-12-r3" already present on machine
0s          Normal    Created     pod/postgresql-postgresql-ha-postgresql-0   Created container: postgresql
0s          Normal    Started     pod/postgresql-postgresql-ha-postgresql-0   Started container postgresql
```
verify the database works after simulating restart/auto recovery

```bash
[root@localhost gke-stateful-postgres]# ./scripts/launch-client.sh

Launching Pod pg-client in the namespace postgresql ...
Error from server (AlreadyExists): pods "pg-client" already exists
waiting for the Pod to be ready
Copying script files to the target Pod pg-client ...
Pod: pg-client is healthy

[root@localhost gke-stateful-postgres]# kubectl exec -it pg-client -n postgresql -- /bin/bash
I have no name!@pg-client:/$ psql -h $HOST_PGPOOL -U postgres -a -q -f /tmp/scripts/count-rows.sql
\c gke_test_zonal;
select COUNT(*) from tb01;
 count
--------
 300000
(1 row)

select COUNT(*) from tb02;
 count
--------
 300000
(1 row)
```
make sure you switch the environment properly to get the correct environment or you will face errors like psql: error: local user with ID 1001 does not exist


## Procedure for Debugging Common Build Failures
To obtain debug information and pull status, affiity status and various other deubgging data pertinent to resolving common errors use;
```bash
# Describe all pods templates
kubectl -n postgresql describe pods
# Overview of 'pods' in projects NAMESPACE
kubectl get all -n $NAMESPACE
# Check Kube DNS System
 kubectl get events -n kube-system

```




# 🔐 Using Google Secret Manager (GSM)

Using GSM is more secure than storing secrets in a GCS bucket because:

- 🔒 It encrypts secrets by default.
- 🛂 It provides fine-grained access control (IAM permissions).
- 🔄 You can version secrets and rotate credentials easily.


## Enable the Secret Manager API

Before running Terraform, enable the Secret Manager API:

```
gcloud services enable secretmanager.googleapis.com
```

## Example: Store Metadata in a GCS Bucket

If you prefer storing metadata in a GCS bucket (⚠️ less secure than GSM), modify Terraform to save the password into a file and upload it:

```
## Create a GCS bucket for storing metadata
resource "google_storage_bucket" "pg_metadata" {
  name          = "predictx-db-metadata"
  location      = var.region
  force_destroy = true
}

## Store PostgreSQL credentials in the GCS bucket
resource "google_storage_bucket_object" "pg_password_file" {
  name   = "postgres-password.txt"
  bucket = google_storage_bucket.pg_metadata.name
  content = <<EOT
DB_NAME=predictx
DB_USER=px-user
DB_PASSWORD=${random_password.pg_password.result}
EOT
}
```
## Summary

There are two main components at present, the first piece of the automation is <mark> Google Cloud GKE Cluster terraform build component</mark> and the second the <mark>kube-credentials-handler-docker-image-deploy-chart</mark> installer component (helm_deploy_postgresql.sh), which carries out the necessary tasks to install charts. Further down a rough outline of a terraform script that performs gke cluster creation and a helm upgrade install within a single script. This is still a rough outline though and isn't as complete as the gke-standard and gke-autopilot cluster autoscale examples provided.

## Comments

I do not have a lot of experience with Terraform and Helm Devops on GCP, and this my first adventure in it, but the scripts split up this way should be helpful for anyone wanting to understand, build or experiment with google GKE Clusters with and without autopilot, with and without DR, and with postgressql or any other chart.

## Common Errors

Unfortunately because my account has several quota limits with the number of times I can spin up and down automation. I reached the limit of my quota pretty fast. Here are some common errors I received before I requested google to increase my cpu quota region wide to a value of 64, and disk size to a value of 1500GB.

* Pod is blocking scale down because it doesn't have enough pod disruption budget (PDB)
* Pod is blocking scale down because its controller can't be found.
* Can't scale up because node auto-provisioning can't provision a node pool for the pod if it would exceed resource limits.
* Can't scale up because node auto-provisioning can't provision a node pool for a pod with failing predicates
* Can't scale up a node pool because of a failing scheduling predicate
* Can't scale up due to exceeded quota

```
│ Error: error creating NodePool: googleapi: Error 403: Insufficient project quota to satisfy request: resource "CPUS_ALL_REGIONS": request requires '12.0' and is short '4.0'. project has a quota of '32.0' with '8.0' available. View and manage quotas at https://console.cloud.google.com/iam-admin/quotas?usage=USED&project=predictx-postgrescluster.

│ Error: Error waiting for resuming GKE node pool:
│       - all cluster resources were brought up, but: only 1 nodes out of 3 have registered; cluster may be unhealthy
│       - insufficient quota to satisfy the request: Not all instances running in IGM after 30.915058557s. Expected 1, running 0, transitioning 1. Current errors: [GCE_QUOTA_EXCEEDED]: Instance 'gke-cluster-db1-pool-db-bbafcd47-mpx5' creation failed: Quota 'CPUS' exceeded.  Limit: 24.0 in region us-central1
│       - insufficient quota to satisfy the request: Not all instances running in IGM after 31.08953717s. Expected 1, running 0, transitioning 1. Current errors: [GCE_QUOTA_EXCEEDED]: Instance 'gke-cluster-db1-pool-db-2c5de97c-ztj3' creation failed: Quota 'CPUS' exceeded.  Limit: 24.0 in region us-central1.
```

<mark> Solution: build a smaller cluster of 1 node only </mark> or <mark> Increase Quota Limits with GCP </mark> alternatively in my case, since this is for demo purposes only I decreased cpu limit to 100m, from 500m and replicas from 3 to 2 in the prepareforha.yaml script and main.tf provided by the google gke cluster docs samples.

It seems that the way that replicas work in zonal regions, building 3 replica instances in 3 regions builds 9 nodes, so I have reduced instances to 1, and max instances to 2. It will scale but now use <mark> much less resources </mark>.

# Other Various Actions/Troubleshooting procedures

This next section is TLDR and would not be included in repo usually unless it was a wiki-foo.

## Creating a Service Account

```
gcloud iam service-accounts create my-service-account \
  --description="Service account for GKE Cluster/Helm Autoinstaller with full access" \
  --display-name="GKE Cluster/Helm Autobuilder Service Account"
```

## Creating owner permissions

```
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:my-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/owner"
```

## Invite a Team Member to Project

```
EMAIL=teammembersemail

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="user:$USER_EMAIL" \
  --role="roles/owner"
```

## fix-iam-policy-bindings.sh Helper Script for GSM Secrets
Put together a little script, probably not a nice way of doing it, but it could make very longwinded configurations a bit simpler, and be a useful audit tool with some adaptation. What it does? It locks down permissios to an exclusive user, but it also checks who has exclusive access to. It could do more, but for now it takes 1 argument and 3 optionals as follows. If no project_id is provided it will use the local gcloud env var for the current project state.

```
# ./fix-iam-policy-bindings.sh
Usage: ./fix-iam-policy-bindings.sh <SECRET_NAME> [SERVICE_ACCOUNT] [PROJECT_ID] [--]
```

## GSM Policy Binding automation purposes 
You can use the script to apply automatically using the 4th -- argument. Careful though, it wont ask you before it writes the policy to the vars provided. Some form of checking should be introduced but it will probably end up in a template eventually in a different form. This script might have other uses like audit or consistency, or template generation helper function. I will have a think aout it. 

Automation usage supports 5 flags be careful wth sanitize, it can be dangerous.
```
# ./fix-iam-policy-bindings.sh SECRET_NAME SERVICE_ACCOUNT PROJECT_ID [--] sanitize
#output is like, can autoexecute with --, sanitize work in progress.
{
  "bindings": [
    {
      "role": "roles/secretmanager.secretAccessor",
      "members": [
        "user:service-account@projectx.iam.gserviceaccount.com"
      ]
    }
  ]
}

```


# When pgclient has not got helms values.yaml settings
```
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl exec -it pg-client -n postgresql -- psql -U postgres -d postgres -a -q -f /tmp/scripts/create-user.sql
psql: error: connection to server on socket "/tmp/.s.PGSQL.5432" failed: No such file or directory
        Is the server running locally and accepting connections on that socket?
command terminated with exit code 2
```


I fixed it. I wrote a new master-client for the 0th node postgresql-postgresql-ha-postgresql-0 to upload the necessary init db scripts. Theoretically client-connect pgclient script can be adapted to switch to any pod and upload the /tmp/scripts for workload/population on postgresql etc.

# Performing Rolling Upgrades on the Stateful GKE Postgres Cluster
It is possible to perform rolling, reversible upgrades of the database when configured this way. The procedure to update components is as follows.

## Push Updated version of desired upgrade component package
```
NEW_IMAGE=us-docker.pkg.dev/$PROJECT_ID/main/bitnami/postgresql-repmgr:15.1.0-debian-11-r1
./scripts/gcr.sh bitnami/postgresql-repmgr 15.1.0-debian-11-r1
```

<mark> Warning before doing this make sure you have the previous_image name:version your replacing or you wont be able to roll it back manually</mark>
If you dont remember the image, run:
```
kubectl describe statefulset -n postgresql postgresql-postgresql-ha-postgresql | grep Image
```

## Trigger Rolling Update via Gcloud API
Here we are using $NEW_IMAGE define and stateful set labelname, can use $stateful_cluster_label or similar in automation etc.

```
kubectl set image statefulset -n postgresql postgresql-postgresql-ha-postgresql postgresql=$NEW_IMAGE
kubectl rollout restart statefulsets -n postgresql postgresql-postgresql-ha-postgresql
kubectl rollout status statefulset -n postgresql postgresql-postgresql-ha-postgresql
```

## Expected Output for Rolling Update

```
Waiting for 1 pods to be ready...
waiting for statefulset rolling update to complete 1 pods at revision postgresql-postgresql-ha-postgresql-5c566ccf49...
Waiting for 1 pods to be ready...
Waiting for 1 pods to be ready...
waiting for statefulset rolling update to complete 2 pods at revision postgresql-postgresql-ha-postgresql-5c566ccf49...
Waiting for 1 pods to be ready...
Waiting for 1 pods to be ready...
statefulset rolling update complete 3 pods at revision postgresql-postgresql-ha-postgresql-5c566ccf49...
```

## Verify Database Availability

Afterwards, or during the rolling upgrade you may use a pg-client pod to verify the databases availability.
```
./scripts/launch-client.sh
kubectl exec -it -n postgresql pg-client -- /bin/bash
pgbench -i -h $HOST_PGPOOL -U postgres postgres
```

If you cannot find the password, or are lockd out perform these steps to retrieve the data from gsm secrets/helm secrets.

## Finding postgres Credentials of a stateful ha set
```bash
kubectl get secrets -n postgresql

kubectl describe secret postgresql-postgresql-ha-postgresql -n postgresql

kubectl get secret postgresql-postgresql-ha-postgresql -n postgresql -o yaml

# Retrieve and decode the password data
kubectl get secret postgresql-postgresql-ha-postgresql -n postgresql -o jsonpath="{.data.password}" | base64 --decode
kubectl get secret postgresql-postgresql-ha-postgresql -n postgresql -o jsonpath="{.data.repmgr-password}" | base64 --decode
kubectl get secret postgresql-postgresql-ha-postgresql -n postgresql -o jsonpath="{.data.someotherdata}" | base64 --decode

#For helm specific info try something like;

kubectl get secret sh.helm.release.v1.postgresql.v1 -n postgresql -o jsonpath="{.data.release}" | base64 --decode
kubectl get secret sh.helm.release.v1.postgresql.v1 -n postgresql -o jsonpath="{.data.release}" | base64 --decode | gzip -d

```
## Rolling back a failed Upgrade in the stateful DB
If the db upgrade fails for any reason, it can be manually rolled back like as follows;

```
kubectl set image statefulset -n postgresql postgresql-postgresql-ha-postgresql postgresql=<previous_image>
kubectl rollout restart statefulset -n postgresql postgresql-postgresql-ha-postgresql
kubectl describe statefulset -n postgresql postgresql-postgresql-ha-postgresql | grep Image
```

If you are deploying via Helm and want to roll back the version you can also use;
though I am not sure if this best approach.
```
helm rollback postgresql <previous_revision> -n postgresql
```

You can check available revisions using;
```
helm history postgresql -n postgresql
```

## Scale Down AND Restore from Backup
If upgrades cause data corruption or volume mounting issues, scale down the stateful set, restore from a backup and then scale it back up.
```
#scale down replicas
kubectl scale statefulset postgresql-postgresql-ha-postgresql --replicas=0 -n postgresql

// Perform Backup Restore (not covered here) before running the following;

#scale up replicas after backup restored
kubectl scale statefulset postgresql-postgresql-ha-postgresql --replicas=3 -n postgresql
```
Although backup restoration isn't discussed in this section, you should find it below somewhere if it has been written yet.

## Reverting Statefulset changes using a previous yaml

```
kubectl apply -f previous_statefulset.yaml
```

## Checking Logs and Debugging
If the new image fails, you should check logs before rolling back;
```
kubectl logs -l app.kubernetes.io/name=postgresql-ha -n postgresql
kubectl get pods -n postgresql
kubectl describe pod <pod-name> -n postgresql
```

# Disaster Recovery and Migration

## Step 1: Preparing for DR Backup
In the event of a disaster on the production cluster-db1 postgres gke statefulset, the procedure of disaster recovery and backup plans are important.

To prepare to backup and restore your PostgreSQL workload, follow these steps:
Important information is. Checking the source and target are correct, that the REGION is defined correctly i.e. us-central1 not us-central1a if its a regional, not zonal cluster. Understanding that the REGION is the SOURCE and that the DR_REGION is the target to migrate to. <mark>Please, don't get this wrong. It would be bad.</mark>
```bash
export SOURCE_CLUSTER=cluster-db1
export TARGET_CLUSTER=cluster-db2
export REGION=us-central1
export DR_REGION=us-west1
export NAME_PREFIX=g-db-protected-app
export BACKUP_PLAN_NAME=$NAME_PREFIX-bkp-plan-01
export BACKUP_NAME=bkp-$BACKUP_PLAN_NAME
export RESTORE_PLAN_NAME=$NAME_PREFIX-rest-plan-01
export RESTORE_NAME=rest-$RESTORE_PLAN_NAME
```

## Step 2: Verifying Backup for GKE is enabled on the cluster
```bash
gcloud container clusters describe $SOURCE_CLUSTER \
    --project=$PROJECT_ID  \
    --region=$REGION \
    --format='value(addonsConfig.gkeBackupAgentConfig)'
```
If Backup for GKE is enabled, the output of the command shows enabled=True.

## Step 3: Set Up the Backup Plan and Test the Restore Works
Always set up the backup plan and <mark> TEST THE RESTORE WORKS </mark> afterwards. 

```bash
#Verify status of protectapplication on the cluster-db1 source 

kubectl get ProtectedApplication -A
NAMESPACE    NAME            READY TO BACKUP
postgresql   postgresql-ha   true

#Create Namespace Exports for Backup Plan Initialization
export NAMESPACE=postgresql
export PROTECTED_APP=$(kubectl get ProtectedApplication -n $NAMESPACE | grep -v 'NAME' | awk '{ print $1 }')

#Define the Backup Setup and Initialize the Backups policy

gcloud beta container backup-restore backup-plans create $BACKUP_PLAN_NAME \
--project=$PROJECT_ID \
--location=$DR_REGION \
--cluster=projects/$PROJECT_ID/locations/$REGION/clusters/$SOURCE_CLUSTER \
--selected-applications=$NAMESPACE/$PROTECTED_APP \
--include-secrets \
--include-volume-data \
--cron-schedule="0 3 * * *" \
--backup-retain-days=7 \
--backup-delete-lock-days=0

#Manually run a backup
gcloud beta container backup-restore backups create $BACKUP_NAME \
--project=$PROJECT_ID \
--location=$DR_REGION \
--backup-plan=$BACKUP_PLAN_NAME \
--wait-for-completion

# Setup Restore Plan 
gcloud beta container backup-restore restore-plans create $RESTORE_PLAN_NAME \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --backup-plan=projects/$PROJECT_ID/locations/$DR_REGION/backupPlans/$BACKUP_PLAN_NAME \
  --cluster=projects/$PROJECT_ID/locations/$DR_REGION/clusters/$TARGET_CLUSTER \
  --cluster-resource-conflict-policy=use-existing-version \
  --namespaced-resource-restore-mode=delete-and-restore \
  --volume-data-restore-policy=restore-volume-data-from-backup \
  --selected-applications=$NAMESPACE/$PROTECTED_APP \
  --cluster-resource-scope-selected-group-kinds="storage.k8s.io/StorageClass","scheduling.k8s.io/PriorityClass"

# Restore to $DR_REGION (db-cluster2) remember its very important to understand dr-region is the TARGET to deploy 
# and not the dr-region that failed. always $REGION var should be the failing cluster and DR_REGION should be the target of migration

gcloud beta container backup-restore restores create $RESTORE_NAME \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --restore-plan=$RESTORE_PLAN_NAME \
  --backup=projects/$PROJECT_ID/locations/$DR_REGION/backupPlans/$BACKUP_PLAN_NAME/backups/$BACKUP_NAME \
  --wait-for-completion
```

## Verify that the Cluster is restored and has all the expected pods
First we need to configure kubectl line to access the backup cluster cluster-db2
```bash
# verify your target-to-migrate-to is the active authorised object/container 
gcloud container clusters get-credentials $TARGET_CLUSTER --region $DR_REGION --project $PROJECT_ID
kubectl get all -n $NAMESPACE
kubectl get pods -n $NAMESPACE

# Verify the PersistentVolumes and StorageClass. During the restore process, Backup for GKE creates a Proxy Class in the target workload to replace the StorageClass provisioned in the source workload (gce-pd-gkebackup-dn in the example output).
kubectl get pvc -n $NAMESPACE
#output looks like
NAME                                         STATUS   VOLUME                 CAPACITY   ACCESS MODES   STORAGECLASS          AGE
data-postgresql-postgresql-ha-postgresql-0   Bound    pvc-be91c361e9303f96   8Gi        RWO            gce-pd-gkebackup-dn   10m
data-postgresql-postgresql-ha-postgresql-1   Bound    pvc-6523044f8ce927d3   8Gi        RWO            gce-pd-gkebackup-dn   10m
data-postgresql-postgresql-ha-postgresql-2   Bound    pvc-c9e71a99ccb99a4c   8Gi        RWO            gce-pd-gkebackup-dn   10m

```

## Validate Restored Data is Valid (DANGER, WARNING DO NOT SKIP.)
Do not under any circumstances skip this, doing so could leave you without a 'working' backup. Even if backup succeeds, you may not have the right data, for example if the backups are taken for the $TARGET DR_REGION instead of the $SOURCE REGION.

```bash
./scripts/launch-client.sh
kubectl exec -it pg-client -n postgresql -- /bin/bash

psql -h $HOST_PGPOOL -U postgres -a -q -f /tmp/scripts/count-rows.sql
select COUNT(*) from tb01;
```

Check the data whatever it may be is still there.  If it is,

We can now delete this test project for a dry-run of the automation;
```
#commented for safety, destructive command
#gcloud projects delete $PROJECT_ID
```

## Ensuring Helm Values.yaml reaches $TARGET_CLUSTER
So, After succesfully backing up and restoring the data of the second cluster. I noticed that helm values aren't automatically configured in the gke namespace for the seocnd cluster, in my case cluster-db2. This is fairly trivial to fix, first we need to export the values from the db-cluster1. dont worry if you dont have it, we can make new ones, its just effectively 3 files. However, its best to have these values.yaml, or, to reconstruct the yaml as it should be with the values in the helm secrets or gsm store for the variables , in this case just the password. Really there is not a lot of metadata to carry. Then we can apply the yaml to the cluster-db2 and helm will configure itself correctly on the container, with the migrated datastore from cluster-db1. 

This is, really, really complicated. But in practice it turns out to be quite simple. Gcloud and Helm are doing all the heavy lifting, and as long as they do, these complexities should stay simple. One problem I had was with the image repo being an 'insecure' docker repo not being the official bitnami one. So I changed it on db2. 

I then performed again the whole process, which I include here, merely for posterity, and so I can reconstruct a 'BIG' Documentation that will be a lot cleaner later on.

# Disaster Recovery

A helpful script is provided that will automate a single backup plan, restore plan, backup and restore between two cluster-db databases. This is intended for use in testing only at present. i.e. for testing backup of cluster-db1 ha set, and failover recovery to cluster-db2. Not much work has been done to support transition, but a LB reconfigurable when running the disaster script, either manually or automatically via a GCP instance group configuration seems like best approach. 
```
./
chmod +x disater-recovery.sh
./disaster-recovery.sh
```

Output will look like below
```bash

=== WARNING IMPORTANT INFORMATION FOR BACKUP PLAN UNIT TESTING ===
Backing up data on cluster-db1 in us-central1, to be migrated to => cluster-db2 in us-west1 , for the app g-db-protected-app.
We are creating/using g-db-protected-app-bkp-plan-01 for bkp-g-db-protected-app-bkp-plan-01 and the g-db-protected-app-rest-plan-01 for rest-g-db-protected-app-rest-plan-01 to DR Recovery into cluster-db2 bebcause of a failure on cluster-db1
This script delays executing for 60 seconds in the hope of saving lives and jobs...
Starting...
Trying to get Gcloud credentials for cluster-db1 Backup procedure...
Fetching cluster endpoint and auth data.
kubeconfig entry generated for cluster-db1.
Verifying Backup enabled at GKE...
enabled=True
Checking status of protectedapplication...
NAMESPACE    NAME            READY TO BACKUP
postgresql   postgresql-ha   true
-------------- BEGIN CREATING BACKUP PLAN --------------
START EXPORTS
END EXPORTS
Create request issued for: [g-db-protected-app-bkp-plan-01]
Waiting for operation [projects/predictx-postgrescluster/locations/us-west1/operations/operation-1743494776028-631b302cafbff-6a9cec5b-ccf42575] to complete...done.
Created backup plan [g-db-protected-app-bkp-plan-01].
-------------- END CREATING BACKUP PLAN --------------
Trying to manually create a backup for bkp-g-db-protected-app-bkp-plan-01 in predictx-postgrescluster with a target us-west1 and Backup plan g-db-protected-app-bkp-plan-01
------BEGIN MANUAL BACKUP------
Create in progress for backup bkp-g-db-protected-app-bkp-plan-01 [projects/predictx-postgrescluster/locations/us-west1/operations/operation-1743494893258-631b309c7c875-1627ee56-0e5621aa].
Creating backup bkp-g-db-protected-app-bkp-plan-01...done.
Waiting for backup to complete... Backup state: CREATING.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Backup completed. Backup state: SUCCEEDED
------END MANUAL BACKUP------
--------------- BEGIN CREATING RESTORE PLAN ---------------
Create request issued for: [g-db-protected-app-rest-plan-01]
Waiting for operation [projects/predictx-postgrescluster/locations/us-west1/operations/operation-1743495009645-631b310b7b200-c2abbf38-7e789096] to complete...done.
Created restore plan [g-db-protected-app-rest-plan-01].
--------------- END CREATING RESTORE PLAN ---------------
--------------- BEGIN EXECUTING RESTORE FOR bkp-g-db-protected-app-bkp-plan-01:, RESTORE TARGET = cluster-db2, FAILED SOURCE was cluster-db1 ---------------
Create in progress for restore rest-g-db-protected-app-rest-plan-01 [projects/predictx-postgrescluster/locations/us-west1/operations/operation-1743495014195-631b310fd20e5-7bd6718e-567ec868].
Creating restore rest-g-db-protected-app-rest-plan-01...done.
Waiting for restore to complete... Restore state: CREATING.
Waiting for restore to complete... Restore state: IN_PROGRESS.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Restore completed. Restore state: SUCCEEDED
--------------- END EXECUTING RESTORE FOR bkp-g-db-protected-app-bkp-plan-01:, RESTORE TARGET = cluster-db2, FAILED SOURCE was cluster-db1 ---------------

Unit tests complete...
Waiting 30 seconds before re-polling.
INFO: The Source cluster was cluster-db1 which has been restored onto the Target Cluster cluster-db2 using g-db-protected-app-bkp-plan-01 and g-db-protected-app-rest-plan-01. The Old region was us-central1 and Disaster caused  need to migrate to the cluster-db2 IN us-west1. cluster-db2 now has full restored data that the failed cluster-db1 had..
Fetching cluster endpoint and auth data.
kubeconfig entry generated for cluster-db2.
```

Looks like we're all good, so lets switch our env namespace/object to cluster-db2 like follows
Make sure you have the exports there. This is for "clean" working. and so that something wont get nuked that shouldnt.
```
export SOURCE_CLUSTER=cluster-db1
export TARGET_CLUSTER=cluster-db2
export REGION=us-central1
export DR_REGION=us-west1
export NAME_PREFIX=g-db-protected-app
export BACKUP_PLAN_NAME=$NAME_PREFIX-bkp-plan-01
export BACKUP_NAME=bkp-$BACKUP_PLAN_NAME
export RESTORE_PLAN_NAME=$NAME_PREFIX-rest-plan-01
export RESTORE_NAME=rest-$RESTORE_PLAN_NAME


gcloud container clusters get-credentials $TARGET_CLUSTER --region $DR_REGION --project $PROJECT_ID                                                                
# when you later want to switch back to cluster-db1 you can use
# gcloud container clusters get-credentials $SOURCE_CLUSTER --region $REGION --project $PROJECT_ID
```

# Cluster-DB2 ($TARGET_CLUSTER) Checklist 
After Migration from Cluster-DB1 ($SOURCE_CLUSTER) to the new Cluster-DB2 target. We need to switch our environment like above, and then confirm the database data is what it should be.

```
# launch pgclient pod on cluster-db2 
[root@localhost gke-stateful-postgres]# ./scripts/launch-client.sh
# connect via kubectl in cluster-d2 env
kubectl exec -it pg-client -n postgresql -- /bin/bash
# Connect to test connection to pool
I have no name!@pg-client:/$ psql -h $HOST_PGPOOL -U postgres -a -q
psql: error: connection to server at "postgresql-postgresql-ha-pgpool" (192.168.213.218), port 5432 failed: Connection refused
        Is the server running on that host and accepting TCP/IP connections?
```

When testing the backup a second time, some unschedulable pods were encountered effectively preventing GKE backup running, looks like its not just related to helm configuration. But, lets check the state of helm in cluster-db2. It looks like it has not got its values.yaml so the pgclient pod is running blind. Or maybe the stateful cluster hasn't reached it's ready state.

```bash
[root@localhost gke-stateful-postgres]# kubectl get pods -n postgresql
NAME                                              READY   STATUS             RESTARTS        AGE
pg-client                                         1/1     Running            0               90m
postgresql-0                                      1/1     Running            0               74m
postgresql-postgresql-ha-pgpool-8479dbf9d-g8c6z   0/1     CrashLoopBackOff   7 (4m14s ago)   15m
postgresql-postgresql-ha-postgresql-0             0/2     Pending            0               15m
postgresql-postgresql-ha-postgresql-1             0/2     Pending            0               15m
postgresql-postgresql-ha-postgresql-2             0/2     Pending            0               15m
```
So, something looks roken here, and pgpool has crashloopbackoff. I never saw that before, and had the second db2 working, but, I suspect its related to the issues I found before.

We need to find out what is wrong with pgpool for the connection issue to happen. Likely, helm doesn't know about it.

```
[root@localhost gke-stateful-postgres]# kubectl logs postgresql-postgresql-ha-pgpool-8479dbf9d-g8c6z -n postgresql
```
Output looks like, and reveals a lot to us about the conditions going on;

```bash
gpool 10:21:40.67 INFO  ==> Validating settings in PGPOOL_* env vars...
pgpool 10:21:40.75 INFO  ==> Initializing Pgpool-II...
pgpool 10:21:40.76 INFO  ==> Generating pg_hba.conf file...
pgpool 10:21:40.76 INFO  ==> Generating pgpool.conf file...
pgpool 10:21:41.28 INFO  ==> Generating password file for local authentication...
pgpool 10:21:41.35 INFO  ==> Generating password file for pgpool admin user...
pgpool 10:21:41.36 INFO  ==> ** Pgpool-II setup finished! **

pgpool 10:21:41.45 INFO  ==> ** Starting Pgpool-II **
2025-04-01 10:21:41.475: main pid 1: LOG:  Backend status file /opt/bitnami/pgpool/logs/pgpool_status does not exist
2025-04-01 10:21:41.475: main pid 1: LOG:  health_check_stats_shared_memory_size: requested size: 12288
2025-04-01 10:21:41.475: main pid 1: LOG:  memory cache initialized
2025-04-01 10:21:41.475: main pid 1: DETAIL:  memcache blocks :64
2025-04-01 10:21:41.475: main pid 1: LOG:  allocating (144190784) bytes of shared memory segment
2025-04-01 10:21:41.475: main pid 1: LOG:  allocating shared memory segment of size: 144190784
2025-04-01 10:21:41.775: main pid 1: LOG:  health_check_stats_shared_memory_size: requested size: 12288
2025-04-01 10:21:41.775: main pid 1: LOG:  health_check_stats_shared_memory_size: requested size: 12288
2025-04-01 10:21:41.775: main pid 1: LOG:  memory cache initialized
2025-04-01 10:21:41.775: main pid 1: DETAIL:  memcache blocks :64
2025-04-01 10:21:41.777: main pid 1: LOG:  pool_discard_oid_maps: discarded memqcache oid maps
2025-04-01 10:21:41.795: main pid 1: LOG:  create socket files[0]: /opt/bitnami/pgpool/tmp/.s.PGSQL.5432
2025-04-01 10:21:41.844: main pid 1: LOG:  listen address[0]: *
2025-04-01 10:21:41.844: main pid 1: LOG:  Setting up socket for 0.0.0.0:5432
2025-04-01 10:21:41.844: main pid 1: LOG:  Setting up socket for :::5432
2025-04-01 10:21:41.871: main pid 1: LOG:  find_primary_node_repeatedly: waiting for finding a primary node
2025-04-01 10:21:41.976: main pid 1: WARNING:  failed to connect to PostgreSQL server, getaddrinfo() failed with error "Name or service not known"
2025-04-01 10:21:41.976: main pid 1: LOG:  find_primary_node: make_persistent_db_connection_noerror failed on node 0
2025-04-01 10:21:42.038: main pid 1: WARNING:  failed to connect to PostgreSQL server, getaddrinfo() failed with error "Name or service not known"
```

We need to make sure pgpool gets the right info to co-ordinate the cluster db. Our backup / recovery script will have to take this process into consideration aswell.

Lets switch back to the db1 environment and retrieve the files. erghhhh. I see my mistake, I was patching something and temporarily changed $REGION to us-west and forgot to change it back. I will fix it now.
```
export REGION=us-central1
```

Now the region is set, hopefully I will be able to switch environment correctly to db1 and export the values i need from helm. Lets get those values we needed;
```
helm get values postgresql -n $NAMESPACE -o yaml > recovered-namespace-values2.yaml
```
We won't use them yet, lets try and redeploy helm on cluster-db2 first;

```
[root@localhost gke-stateful-postgres]# helm upgrade --install postgresql bitnami/postgresql -n $NAMESPACE
Release "postgresql" has been upgraded. Happy Helming!
NAME: postgresql
LAST DEPLOYED: Tue Apr  1 11:37:10 2025
NAMESPACE: postgresql
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
CHART NAME: postgresql
CHART VERSION: 16.6.0
APP VERSION: 17.4.0
```
Wow I got to say after fixing this first time, and everything working well I am sad about this.
```
[root@localhost gke-stateful-postgres]#  kubectl get pods -n postgresql
NAME                                              READY   STATUS             RESTARTS       AGE
pg-client                                         1/1     Running            0              109m
postgresql-0                                      1/1     Running            0              93m
postgresql-postgresql-ha-pgpool-8479dbf9d-g8c6z   0/1     CrashLoopBackOff   13 (23s ago)   33m
postgresql-postgresql-ha-postgresql-0             0/2     Pending            0              33m
postgresql-postgresql-ha-postgresql-1             0/2     Pending            0              33m
postgresql-postgresql-ha-postgresql-2             0/2     Pending            0              33m
```

We will uninstall helm then reinstall it.
```
[root@localhost gke-stateful-postgres]# helm uninstall postgresql -n $NAMESPACE
```

We will check the pods again in cluster-db2
```
[root@localhost gke-stateful-postgres]#  kubectl get pods -n postgresql
NAME                                              READY   STATUS              RESTARTS         AGE
pg-client                                         1/1     Running             0                113m
postgresql-0                                      0/1     ContainerCreating   0                11s
postgresql-postgresql-ha-pgpool-8479dbf9d-g8c6z   0/1     CrashLoopBackOff    13 (4m16s ago)   37m
postgresql-postgresql-ha-postgresql-0             0/2     Pending             0                37m
postgresql-postgresql-ha-postgresql-1             0/2     Pending             0                37m
postgresql-postgresql-ha-postgresql-2             0/2     Pending             0                37m
```
Still borked. So we will delete the crahsed pgpool node
```

[root@localhost gke-stateful-postgres]#  kubectl get pods -n postgresql
NAME                                              READY   STATUS    RESTARTS         AGE
pg-client                                         1/1     Running   0                115m
postgresql-0                                      1/1     Running   0                113s
postgresql-postgresql-ha-pgpool-8479dbf9d-g8c6z   0/1     Running   14 (5m58s ago)   39m
postgresql-postgresql-ha-postgresql-0             0/2     Pending   0                39m
postgresql-postgresql-ha-postgresql-1             0/2     Pending   0                39m
postgresql-postgresql-ha-postgresql-2             0/2     Pending   0                39m
```
That fixed it, it seems there is also scaling problems going on , making this even the more nightmarish. The main thing to consider is the values.yaml helm receives. So lets take the exported values and import them into the cluster-db2.

```
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# helm upgrade --install postgresql bitnami/postgresql -n $NAMESPACE --values recovered-namespace-values2.yaml
```

OK, now I have replicated the original error I had with this before fixing it which was:

```
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# helm upgrade --install postgresql bitnami/postgresql -n $NAMESPACE --values recovered-namespace-values2.yaml
Error: UPGRADE FAILED: execution error at (postgresql/templates/NOTES.txt:121:4):

⚠ ERROR: Original containers have been substituted for unrecognized ones. Deploying this chart with non-standard containers is likely to cause degraded security and performance, broken chart features, and missing environment variables.

Unrecognized images:
  - us-docker.pkg.dev/predictx-postgrescluster/main/bitnami/postgresql:17.4.0-debian-12-r11
  - us-docker.pkg.dev/predictx-postgrescluster/main/bitnami/os-shell:12-debian-12-r40
  - us-docker.pkg.dev/predictx-postgrescluster/main/bitnami/postgres-exporter:0.17.1-debian-12-r2

If you are sure you want to proceed with non-standard containers, you can skip container image verification by setting the global parameter 'global.security.allowInsecureImages' to true.
Further information can be obtained at https://github.com/bitnami/charts/issues/30850
```

We need to update the chart configuration in values.yaml we provide it like so;
```
global:
  imageRegistry: us-docker.pkg.dev/predictx-postgrescluster/main
postgresql:
  database: predictx
  password: redacted
```
Changing it to use the official bitnami repo rather than our private cluster. It actually has security implications using internal repo outdated, as much as using external repo uptodate.

```
postgresql:
  database: predictx
  password: redacted
  image:
    repository: bitnami/postgresql  # Bitnami's official repo
```
And we now can rerun the postgresql upgrade script;

```
[root@localhost gke-stateful-postgres]# helm upgrade --install postgresql bitnami/postgresql -n $NAMESPACE --values recovered-namespace-values.yaml
Release "postgresql" has been upgraded. Happy Helming!
NAME: postgresql
LAST DEPLOYED: Tue Apr  1 11:50:05 2025
NAMESPACE: postgresql
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
CHART NAME: postgresql
CHART VERSION: 16.6.0
APP VERSION: 17.4.0
```

Our error is gone, and deploy succeeds. Still things look broke AF though :( 

The problem is

```bash
kubectl logs postgresql-postgresql-ha-pgpool-8479dbf9d-g8c6z -n postgresql
25-04-01 10:53:34.300: child pid 242: WARNING:  failed to connect to PostgreSQL server, getaddrinfo() failed with error "Name or service not known"
2025-04-01 10:53:34.301: child pid 242: FATAL:  failed to create a backend 0 connection
2025-04-01 10:53:34.301: child pid 242: DETAIL:  not executing failover because failover_on_backend_error is off
2025-04-01 10:53:34.326: main pid 1: WARNING:  failed to connect to PostgreSQL server, getaddrinfo() failed with error "Name or service not known"
2025-04-01 10:53:34.326: main pid 1: LOG:  find_primary_node: make_persistent_db_connection_noerror failed on node 0
2025-04-01 10:53:34.340: main pid 1: WARNING:  failed to connect to PostgreSQL server, getaddrinfo() failed with error "Name or service not known"
2025-04-01 10:53:34.341: main pid 1: LOG:  find_primary_node: make_persistent_db_connection_noerror failed on node 1
2025-04-01 10:53:34.354: main pid 1: WARNING:  failed to connect to PostgreSQL server, getaddrinfo() failed with error "Name or service not known"
2025-04-01 10:53:34.354: main pid 1: LOG:  find_primary_node: make_persistent_db_connection_noerror failed on node 2
2025-04-01 10:53:35.372: main pid 1: WARNING:  failed to connect to PostgreSQL server, getaddrinfo() failed with error "Name or service not known"
2025-04-01 10:53:35.372: main pid 1: LOG:  find_primary_node: make_persistent_db_connection_noerror failed on node 0
2025-04-01 10:53:35.384: main pid 1: WARNING:  failed to connect to PostgreSQL server, getaddrinfo() failed with error "Name or service not known"
2025-04-01 10:53:35.384: main pid 1: LOG:  find_primary_node: make_persistent_db_connection_noerror failed on node 1
2025-04-01 10:53:35.400: main pid 1: WARNING:  failed to connect to PostgreSQL server, getaddrinfo() failed with error "Name or service not known"
2025-04-01 10:53:35.400: main pid 1: LOG:  find_primary_node: make_persistent_db_connection_noerror failed on node 2
```
This is happening on main pgpool co-ordinator. We need to check the logs for the 0th node too.
```
kubectl describe pod postgresql-postgresql-ha-postgresql-0 -n postgresql

Events:
  Type     Reason             Age                 From                                   Message
  ----     ------             ----                ----                                   -------
  Warning  FailedScheduling   39m                 gke.io/optimize-utilization-scheduler  running PreBind plugin "VolumeBinding": binding volumes: context deadline exceeded
  Warning  FailedScheduling   35m                 gke.io/optimize-utilization-scheduler  running PreBind plugin "VolumeBinding": binding volumes: failed to get node "gke-cluster-db2-nap-e2-standard-2-1d4-a228910d-m6pp": node "gke-cluster-db2-nap-e2-standard-2-1d4-a228910d-m6pp" not found
  Warning  FailedScheduling   35m                 gke.io/optimize-utilization-scheduler  0/7 nodes are available: 1 Insufficient cpu, 3 node(s) didn't match Pod's node affinity/selector, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}. preemption: 0/7 nodes are available: 1 No preemption victims found for incoming pod, 6 Preemption is not helpful for scheduling.
  Warning  FailedScheduling   29m (x4 over 35m)   gke.io/optimize-utilization-scheduler  0/7 nodes are available: 1 Insufficient cpu, 3 node(s) didn't match Pod's node affinity/selector, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}. preemption: 0/7 nodes are available: 1 No preemption victims found for incoming pod, 6 Preemption is not helpful for scheduling.
  Warning  FailedScheduling   23m                 gke.io/optimize-utilization-scheduler  0/7 nodes are available: 1 Insufficient cpu, 3 node(s) didn't match Pod's node affinity/selector, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}. preemption: 0/7 nodes are available: 1 No preemption victims found for incoming pod, 6 Preemption is not helpful for scheduling.
  Warning  FailedScheduling   19m                 gke.io/optimize-utilization-scheduler  0/7 nodes are available: 1 node(s) didn't find available persistent volumes to bind, 3 node(s) didn't match Pod's node affinity/selector, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}. preemption: 0/7 nodes are available: 7 Preemption is not helpful for scheduling.
  Warning  FailedScheduling   13m                 gke.io/optimize-utilization-scheduler  0/7 nodes are available: 1 Insufficient cpu, 3 node(s) didn't match Pod's node affinity/selector, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}. preemption: 0/7 nodes are available: 1 No preemption victims found for incoming pod, 6 Preemption is not helpful for scheduling.
  Warning  FailedScheduling   9m4s (x2 over 12m)  gke.io/optimize-utilization-scheduler  0/7 nodes are available: 1 Insufficient cpu, 3 node(s) didn't match Pod's node affinity/selector, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}. preemption: 0/7 nodes are available: 1 No preemption victims found for incoming pod, 6 Preemption is not helpful for scheduling.
  Warning  FailedScheduling   3m43s               gke.io/optimize-utilization-scheduler  0/7 nodes are available: 1 Insufficient cpu, 3 node(s) didn't match Pod's node affinity/selector, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}. preemption: 0/7 nodes are available: 1 No preemption victims found for incoming pod, 6 Preemption is not helpful for scheduling.
  Normal   NotTriggerScaleUp  25m (x17 over 34m)  cluster-autoscaler                     pod didn't trigger scale-up: 3 node(s) didn't match Pod's node affinity/selector, 1 node(s) didn't find available persistent volumes to bind, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}
  Normal   NotTriggerScaleUp  10m (x36 over 35m)  cluster-autoscaler                     pod didn't trigger scale-up: 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}, 1 node(s) didn't find available persistent volumes to bind, 3 node(s) didn't match Pod's node affinity/selector
  Normal   NotTriggerScaleUp  2s (x132 over 35m)  cluster-autoscaler                     pod didn't trigger scale-up: 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}, 3 node(s) didn't match Pod's node affinity/selector, 1 node(s) didn't find available persistent volumes to bind
```

It looks like it's just resources issues, but I think we need to start the backup restore again, to be sure something wasn't missed. It worked the first time, so lets check. OK, this is not fun at all, lets for the 3rd time restart the backup from the beginning and go step by step and troubleshoot each and every issue we experience.

## Re Run the Backup and Restore Script
```
./disaster-recovery.sh
```

The script will again, take a backup of the state of the cluster in cluster-db1 and will then apply it to cluster-db2, where, we will pickup the pieces.

After all this, its google PDB causing the thing to fall apart, one can't help but be frustrated by google cloud in this way. I have definitely resolved this, the instructions are correct. Once google lets me scale again, probably a few hours i'll update the extra info checking the database value was verified at the db2 cluster.


Unfortunately babckups are still failing, either because of misconfiguration or incompatibility. It did work first time, so curious why it isn't now. The answer is in there somewhere.

```
failed to prepare backup for ProtectedApplication "postgresql/postgresql-ha": PVC data-postgresql-ha-postgresql-0 is not a volume backup candidate: PVC is not bound to a PV 
```

## Root Cause of GKE Backup Failures
I have discovered the cause of GKE Backup failure.

```
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl get pvc -n $NAMESPACE
NAME                                         STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS                  VOLUMEATTRIBUTESCLASS   AGE
data-postgresql-0                            Bound     pvc-d4459d8e-809c-4ec1-819f-183fd6fcfc6d   8Gi        RWO            standard-rwo                  <unset>                 9h
data-postgresql-ha-postgresql-0              Pending                                                                        standard-rwo                  <unset>                 9h
data-postgresql-ha-postgresql-1              Pending                                                                        standard-rwo                  <unset>                 9h
data-postgresql-ha-postgresql-2              Bound     pvc-edc7ed43-5507-4c8c-863a-450d5ba05b7b   8Gi        RWO            standard-rwo                  <unset>                 9h
data-postgresql-postgresql-ha-postgresql-0   Bound     pvc-c98daa7b-c243-400f-91e7-5d7d88183ef5   8Gi        RWO            premium-rwo-retain-zonal-pg   <unset>                 9h
data-postgresql-postgresql-ha-postgresql-1   Bound     pvc-5cb16910-2496-41e1-b517-03d2033291c9   8Gi        RWO            premium-rwo-retain-zonal-pg   <unset>                 9h
data-postgresql-postgresql-ha-postgresql-2   Bound     pvc-c57ddcc4-9191-4689-a53d-0d94c6db4a63   8Gi        RWO            premium-rwo-retain-zonal-pg   <unset>                 9h
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl get pods -n postgresql
NAME                                                    READY   STATUS    RESTARTS   AGE
pg-client                                               1/1     Running   0          9h
postgresql-postgresql-bootstrap-pgpool-d6dd4dd4-5z76f   1/1     Running   0          9h
postgresql-postgresql-ha-pgpool-8479dbf9d-r75rr         1/1     Running   0          9h
postgresql-postgresql-ha-postgresql-0                   2/2     Running   0          9h
postgresql-postgresql-ha-postgresql-1                   2/2     Running   0          9h
postgresql-postgresql-ha-postgresql-2                   2/2     Running   0          9h
```

You can see that the 1 and 2 nodes have pending statuses. 

### Steps to Fix Pending PVCs and Unblock Backups
#
First we need to get the PVC descriptions for the offending VM's breaking the backup.
```
kubectl describe pvc data-postgresql-ha-postgresql-0 -n $NAMESPACE

kubectl describe pvc data-postgresql-ha-postgresql-1 -n $NAMESPACE
```

Output in this case yields the cause

```
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl describe pvc data-postgresql-ha-postgresql-0 -n $NAMESPACE
kubectl describe pvc data-postgresql-ha-postgresql-1 -n $NAMESPACE
Name:          data-postgresql-ha-postgresql-0
Namespace:     postgresql
StorageClass:  standard-rwo
Status:        Pending
Volume:
Labels:        app.kubernetes.io/component=postgresql
               app.kubernetes.io/instance=postgresql-ha
               app.kubernetes.io/name=postgresql-ha
               role=data
Annotations:   <none>
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:
Access Modes:
VolumeMode:    Filesystem
Used By:       <none>
Events:
  Type    Reason                Age                   From                         Message
  ----    ------                ----                  ----                         -------
  Normal  WaitForFirstConsumer  3m1s (x2321 over 9h)  persistentvolume-controller  waiting for first consumer to be created before binding
Name:          data-postgresql-ha-postgresql-1
Namespace:     postgresql
StorageClass:  standard-rwo
Status:        Pending
Volume:
Labels:        app.kubernetes.io/component=postgresql
               app.kubernetes.io/instance=postgresql-ha
               app.kubernetes.io/name=postgresql-ha
               role=data
Annotations:   <none>
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:
Access Modes:
VolumeMode:    Filesystem
Used By:       <none>
Events:
  Type    Reason                Age                   From                         Message
  ----    ------                ----                  ----                         -------
  Normal  WaitForFirstConsumer  3m2s (x2321 over 9h)  persistentvolume-controller  waiting for first consumer to be created before binding
```

It seems the controller appears missing because it waiting for first consumer.

## #WaitForFirstConsumer Explained

The WaitForFirstConsumer mode is a volume binding strategy defined in the storage class. Instead of binding a Persistent Volume (PV) immediately when a Persistent Volume Claim (PVC) is created, Kubernetes waits until a pod that uses the PVC is scheduled. This delay allows the scheduler to consider the pod’s placement (such as zone or node affinity) so that the selected PV is optimally located relative to the pod.

In our case, the PVCs are waiting for a pod consumer to trigger binding. If no pod is scheduled to use these PVCs, they remain in the Pending state.

## Root Cause

The Second helm group tags are not right or in improper state, or uncleanly handled when changing the helm template. This might be possible if different versions are installed/uninstalled. So we will force a reconcilation of those volumes by deleting them. It may or may not be necessary to restart the stateful application too in some cases.

```
kubectl delete pvc data-postgresql-ha-postgresql-0 -n $NAMESPACE
kubectl delete pvc data-postgresql-ha-postgresql-1 -n $NAMESPACE
persistentvolumeclaim "data-postgresql-ha-postgresql-0" deleted
persistentvolumeclaim "data-postgresql-ha-postgresql-1" deleted
```

Now when we refresh the pvc our two offending entries disappear

```
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl get pvc -n $NAMESPACE
NAME                                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS                  VOLUMEATTRIBUTESCLASS   AGE
data-postgresql-0                            Bound    pvc-d4459d8e-809c-4ec1-819f-183fd6fcfc6d   8Gi        RWO            standard-rwo                  <unset>                 10h
data-postgresql-ha-postgresql-2              Bound    pvc-edc7ed43-5507-4c8c-863a-450d5ba05b7b   8Gi        RWO            standard-rwo                  <unset>                 10h
data-postgresql-postgresql-ha-postgresql-0   Bound    pvc-c98daa7b-c243-400f-91e7-5d7d88183ef5   8Gi        RWO            premium-rwo-retain-zonal-pg   <unset>                 10h
data-postgresql-postgresql-ha-postgresql-1   Bound    pvc-5cb16910-2496-41e1-b517-03d2033291c9   8Gi        RWO            premium-rwo-retain-zonal-pg   <unset>                 10h
data-postgresql-postgresql-ha-postgresql-2   Bound    pvc-c57ddcc4-9191-4689-a53d-0d94c6db4a63   8Gi        RWO            premium-rwo-retain-zonal-pg   <unset>                 10h
```

Either, GKE backup is trying to make new entries breaking backup, or GKE doesn't know what to do with the extra erroneous disks, so panics out. I think, everything makes sense. We will now retry the automation for GKE to confirm whether it was GKE responsible for it, or GKE was failing because of it. And this time, for good measure, I think we will add some debug for the PVC in the disaster-recovery backup plan creation / execution tool I wrote.

### The big moment
Immediately upon running GKE Backups we can see things are much better already, with backup succeeding immediately.
```
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# ./disaster-recovery.sh
=== WARNING IMPORTANT INFORMATION FOR BACKUP PLAN UNIT TESTING ===
Backing up data on cluster-db1 in us-central1, to be migrated to => cluster-db2 in us-west1 , for the app g-db-protected-app.
We are creating/using g-db-protected-app-bkp-plan-01 for bkp-g-db-protected-app-bkp-plan-01 and the g-db-protected-app-rest-plan-01 for rest-g-db-protected-app-rest-plan-01 to DR Recovery into cluster-db2 bebcause of a failure on cluster-db1
This script delays executing for 60 seconds in the hope of saving lives and jobs...
Starting...
Trying to get Gcloud credentials for cluster-db1 Backup procedure...
Fetching cluster endpoint and auth data.
kubeconfig entry generated for cluster-db1.
DEBUG INFO: Getting pvc for postgresql
NAME                                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS                  VOLUMEATTRIBUTESCLASS   AGE
data-postgresql-0                            Bound    pvc-d4459d8e-809c-4ec1-819f-183fd6fcfc6d   8Gi        RWO            standard-rwo                  <unset>                 10h
data-postgresql-ha-postgresql-2              Bound    pvc-edc7ed43-5507-4c8c-863a-450d5ba05b7b   8Gi        RWO            standard-rwo                  <unset>                 10h
data-postgresql-postgresql-ha-postgresql-0   Bound    pvc-c98daa7b-c243-400f-91e7-5d7d88183ef5   8Gi        RWO            premium-rwo-retain-zonal-pg   <unset>                 10h
data-postgresql-postgresql-ha-postgresql-1   Bound    pvc-5cb16910-2496-41e1-b517-03d2033291c9   8Gi        RWO            premium-rwo-retain-zonal-pg   <unset>                 10h
data-postgresql-postgresql-ha-postgresql-2   Bound    pvc-c57ddcc4-9191-4689-a53d-0d94c6db4a63   8Gi        RWO            premium-rwo-retain-zonal-pg   <unset>                 10h
END DEUG INFO
Verifying Backup enabled at GKE...
enabled=True
Checking status of protectedapplication...
NAMESPACE    NAME            READY TO BACKUP
postgresql   postgresql-ha   true
-------------- BEGIN CREATING BACKUP PLAN --------------
START EXPORTS
END EXPORTS
Create request issued for: [g-db-protected-app-bkp-plan-01]
Waiting for operation [projects/predictx-postgrescluster/locations/us-west1/operations/operation-1743576454731-631c60739160d-d1f2ba19-e73ee624] to complete...done.
Created backup plan [g-db-protected-app-bkp-plan-01].
-------------- END CREATING BACKUP PLAN --------------
Trying to manually create a backup for bkp-g-db-protected-app-bkp-plan-01 in predictx-postgrescluster with a target us-west1 and Backup plan g-db-protected-app-bkp-plan-01
------BEGIN MANUAL BACKUP------
Create in progress for backup bkp-g-db-protected-app-bkp-plan-01 [projects/predictx-postgrescluster/locations/us-west1/operations/operation-1743576462552-631c607b06f89-b568b915-57537d4f].
Creating backup bkp-g-db-protected-app-bkp-plan-01...done.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Backup completed. Backup state: SUCCEEDED
------END MANUAL BACKUP------
--------------- BEGIN CREATING RESTORE PLAN ---------------
Create request issued for: [g-db-protected-app-rest-plan-01]
Waiting for operation [projects/predictx-postgrescluster/locations/us-west1/operations/operation-1743576577249-631c60e8691d0-6db404aa-f7d0a313] to complete...done.
Created restore plan [g-db-protected-app-rest-plan-01].
--------------- END CREATING RESTORE PLAN ---------------
--------------- BEGIN EXECUTING RESTORE FOR bkp-g-db-protected-app-bkp-plan-01:, RESTORE TARGET = cluster-db2, FAILED SOURCE was cluster-db1 ---------------
Create in progress for restore rest-g-db-protected-app-rest-plan-01 [projects/predictx-postgrescluster/locations/us-west1/operations/operation-1743576581781-631c60ecbb7ed-fc419f39-a5ff94e7].
Creating restore rest-g-db-protected-app-rest-plan-01...done.
Waiting for restore to complete... Restore state: CREATING.
Waiting for restore to complete... Restore state: IN_PROGRESS.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
```

Backup now completes, but restore does not complete because the cluster configuration is slightly different. The clusters will need to be identical for the restore to work succesfully. Once a restore completes succesfully, it should gracefully continue to handle connections to the dataset in the same way as the first cluster.

# Troubleshooting GKE Restore to Cluster-DB2

```
kubernetes-autopilot-cluster-helm-postgresql-automation]# gcloud container clusters get-credentials $SOURCE_CLUSTER --region=$REGION
Fetching cluster endpoint and auth data.
kubeconfig entry generated for cluster-db1.
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl get pvc -n $NAMESPACE
NAME                                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS                  VOLUMEATTRIBUTESCLASS   AGE
data-postgresql-0                            Bound    pvc-d4459d8e-809c-4ec1-819f-183fd6fcfc6d   8Gi        RWO            standard-rwo                  <unset>                 11h
data-postgresql-ha-postgresql-2              Bound    pvc-edc7ed43-5507-4c8c-863a-450d5ba05b7b   8Gi        RWO            standard-rwo                  <unset>                 11h
data-postgresql-postgresql-ha-postgresql-0   Bound    pvc-c98daa7b-c243-400f-91e7-5d7d88183ef5   8Gi        RWO            premium-rwo-retain-zonal-pg   <unset>                 11h
data-postgresql-postgresql-ha-postgresql-1   Bound    pvc-5cb16910-2496-41e1-b517-03d2033291c9   8Gi        RWO            premium-rwo-retain-zonal-pg   <unset>                 11h
data-postgresql-postgresql-ha-postgresql-2   Bound    pvc-c57ddcc4-9191-4689-a53d-0d94c6db4a63   8Gi        RWO            premium-rwo-retain-zonal-pg   <unset>                 11h
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]#
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]#
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]#
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# gcloud container clusters get-credentials $TARGET_CLUSTER --region $DR_REGION --project $PROJECT_ID
Fetching cluster endpoint and auth data.
kubeconfig entry generated for cluster-db2.
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl get pvc -n $NAMESPACE
NAME                                         STATUS    VOLUME                 CAPACITY   ACCESS MODES   STORAGECLASS          VOLUMEATTRIBUTESCLASS   AGE
data-postgresql-ha-postgresql-2              Pending                                                    gce-pd-gkebackup-de   <unset>                 70m
data-postgresql-postgresql-ha-postgresql-0   Bound     pvc-1e6d15c45efcd205   8Gi        RWO            gce-pd-gkebackup-dn   <unset>                 70m
data-postgresql-postgresql-ha-postgresql-1   Bound     pvc-cbf157116aaaff0    8Gi        RWO            gce-pd-gkebackup-dn   <unset>                 70m
data-postgresql-postgresql-ha-postgresql-2   Bound     pvc-366b74c5bed755ef   8Gi        RWO            gce-pd-gkebackup-dn   <unset>                 70m
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]#
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]#
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# gcloud container clusters get-credentials $SOURCE_CLUSTER --region=$REGION
Fetching cluster endpoint and auth data.
kubeconfig entry generated for cluster-db1.
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl get pvc -n $NAMESPACE
NAME                                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS                  VOLUMEATTRIBUTESCLASS   AGE
data-postgresql-0                            Bound    pvc-d4459d8e-809c-4ec1-819f-183fd6fcfc6d   8Gi        RWO            standard-rwo                  <unset>                 11h
data-postgresql-ha-postgresql-2              Bound    pvc-edc7ed43-5507-4c8c-863a-450d5ba05b7b   8Gi        RWO            standard-rwo                  <unset>                 11h
data-postgresql-postgresql-ha-postgresql-0   Bound    pvc-c98daa7b-c243-400f-91e7-5d7d88183ef5   8Gi        RWO            premium-rwo-retain-zonal-pg   <unset>                 11h
data-postgresql-postgresql-ha-postgresql-1   Bound    pvc-5cb16910-2496-41e1-b517-03d2033291c9   8Gi        RWO            premium-rwo-retain-zonal-pg   <unset>                 11h
data-postgresql-postgresql-ha-postgresql-2   Bound    pvc-c57ddcc4-9191-4689-a53d-0d94c6db4a63   8Gi        RWO            premium-rwo-retain-zonal-pg   <unset>                 11h
```
Here we can see the state of the restore for the target cluster is missing 2 volumes. This is because the cluster restore target has 7 nodes, and the source_cluster has 9 nodes, and also, because there is insufficient resources in the second-cluster node pool allocations GCP is unable to scale-up cluster-db2 to reproduce the backup state of the first clusters 9 nodes, namely data-postgresql-2. I am unsure at present whether the storageclass should be identical, or not and whether this is a factor in the issue. For this to be properly resolved the cluster-db2 must more closely match the maximum and minimums of cluster-db1's nodes pools.


# Matching Autoscaling Configurations to allow backup to provision correct number of nodes

Here we update the autoscaling_profiles for cluster-db1 ($SOURCE_CLUSTER) and cluster-db2 ($TARGET_CLUSTER) accordingly.

``` [root@localhost gke-stateful-postgres]# cat terraform/gke-standard/main.tf | grep autoscaling_profile -A 6
    "autoscaling_profile": "OPTIMIZE_UTILIZATION",
    "enabled" : true,
    "gpu_resources" : [],
    "min_cpu_cores" : 1,
    "min_memory_gb" : 25,
    "max_cpu_cores" : 80,
    "max_memory_gb" : 80,
--
    "autoscaling_profile": "OPTIMIZE_UTILIZATION",
    "enabled" : true,
    "gpu_resources" : [],
    "min_cpu_cores" : 1,
    "min_memory_gb" : 25,
    "max_cpu_cores" : 80,
    "max_memory_gb" : 80,
```

We also need to make sure the pools are identical, in case the limits are not sufficient for GKE Backup. For now, we concentrate on matching them, and then we can tune the primary to be smaller later on. We need to make sure we can work at scale first, and then scale down accordingly to load via the optimization algorithm of the autoscaling profile.

## Changing/Matching Cluster Cofigurations of the cluster and its DR failover
#
```
# cat terraform/gke-standard/main.tf | grep "node_pools =" -A 6
  node_pools = [
    {
      name            = "pool-sys"
      autoscaling     = true
      min_count       = 1
      max_count       = 6
      max_surge       = 1
--
  node_pools = [
    {
      name            = "pool-sys"
      autoscaling     = true
      min_count       = 1
      max_count       = 6
      max_surge       = 1
```

Another thing we will need to be mindful of is how the application interacts with the cluster-db1 and cluster-db2, for exmaple once cluster-db2 is recovered, do we use GCP to takeover the dns for that pg_pool, or, do we write in our application rules to test connections for cluster-db1 and if they fail, to trigger a restore to cluster-db2 automatically, replicating the dataset of cluster-db1 and then once ready, continuing the application. I always prefer the second option, as I believe application should be aware of failover, however some may suggest an Infrastructure as code deployment should not be aware of its datastore state, and that the cloud should be configured so that it is transparent, and seemlessly operate with a private or public lb with a failover instance cluster group. Some limitations of my understanding of how to google cloud may preclude me from understanding the best practice. Though - I think it depends on the application and the type of workload and it's budget.

## Important: Autoscale Consideration Total Node Limits / vs per zone limits
With this all in mind, Additionally we should consider using total_servers instead of total_zones, in case provisioning of 1 per zone fails because of lack of capacity or an error in one of the 3 zones it uses. This should prevent pain related to their not being enough nodes if db-clusters us-west1-b builds fail due to lack of resources in the hypervisor cells. i.e. the application needs to be able to tolerate failure in one of it's 3 region cloud zones, too. eg. If one of the zones is unprovidable and only 1 per zone is defined in the autoscaling profile, it will result in 2 nodes, not the expected 3. This is why its important to understand Total vs Zonal Node limits.
```
[root@localhost gke-stateful-postgres]# terraform -chdir=terraform/gke-standard apply -var project_id=$PROJECT_ID
<snip>

Terraform will perform the following actions:

  # module.gke-db2.google_container_cluster.primary will be updated in-place
  ~ resource "google_container_cluster" "primary" {
        id                                       = "projects/predictx-postgrescluster/locations/us-west1/clusters/cluster-db2"
        name                                     = "cluster-db2"
        # (35 unchanged attributes hidden)

      ~ cluster_autoscaling {
            # (3 unchanged attributes hidden)

          ~ resource_limits {
              ~ maximum       = 50 -> 80
                # (2 unchanged attributes hidden)
            }
          ~ resource_limits {
              ~ maximum       = 50 -> 80
              ~ minimum       = 4 -> 25
                # (1 unchanged attribute hidden)
            }

            # (1 unchanged block hidden)
        }

        # (29 unchanged blocks hidden)
    }

  # module.gke-db2.google_container_node_pool.pools["pool-sys"] will be updated in-place
  ~ resource "google_container_node_pool" "pools" {
        id                          = "projects/predictx-postgrescluster/locations/us-west1/clusters/cluster-db2/nodePools/pool-sys"
        name                        = "pool-sys"
        # (11 unchanged attributes hidden)

      ~ autoscaling {
          ~ max_node_count       = 3 -> 6
            # (4 unchanged attributes hidden)
        }

        # (5 unchanged blocks hidden)
    }

Plan: 0 to add, 2 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.gke-db2.google_container_cluster.primary: Modifying... [id=projects/predictx-postgrescluster/locations/us-west1/clusters/cluster-db2]
module.gke-db2.google_container_cluster.primary: Still modifying... [id=projects/predictx-postgrescluster/locations/us-west1/clusters/cluster-db2, 10s elapsed]
module.gke-db2.google_container_cluster.primary: Modifications complete after 17s [id=projects/predictx-postgrescluster/locations/us-west1/clusters/cluster-db2]
module.gke-db2.google_container_node_pool.pools["pool-sys"]: Modifying... [id=projects/predictx-postgrescluster/locations/us-west1/clusters/cluster-db2/nodePools/pool-sys]
module.gke-db2.google_container_node_pool.pools["pool-sys"]: Still modifying... [id=projects/predictx-postgrescluster/locat...lusters/cluster-db2/nodePools/pool-sys, 10s elapsed]
module.gke-db2.google_container_node_pool.pools["pool-sys"]: Modifications complete after 13s [id=projects/predictx-postgrescluster/locations/us-west1/clusters/cluster-db2/nodePools/pool-sys]

Apply complete! Resources: 0 added, 2 changed, 0 destroyed.
```

We check the gke-autoscale change carefully, making sure db-1 production is left untouched, and its failover configuration will apply correctly before accepting and applying the template change in terraform.

I also notice that one of the $TARGET_CLUSTER cluster-db2 pools has this configuration.

```
    {
      name            = "pool-db"
      autoscaling     = true
      max_surge       = 1
      max_unavailable = 0
      machine_type    = "e2-standard-2"
      node_locations  = "us-west1-a"
      auto_repair     = true
    },
```

We add us-west1-b and us-west1-c again, to make sure the exact number of pool regions are the same between the clusters. And then re-apply. Hopefully this should lead to 3 nodes per zone, preventing gke backup restore failures in future.


```
[root@localhost gke-stateful-postgres]# cat terraform/gke-standard/main.tf | grep "node_locations"
      node_locations  = "us-central1-a,us-central1-b,us-central1-c"
      node_locations  = "us-central1-a,us-central1-b,us-central1-c"
      node_locations  = "us-west1-b,us-west1-a,us-west1-c"
      node_locations  = "us-west1-a,us-west1-b,us-west1-c"
```

Now we can see the 4 node-locations are identical in their number, and, adding the extra 2 node_locations should account for the 2 missing PVC's when doing backup restore from cluster-db1->cluster-db2.

After applying the changes we can see that the db-pool of cluster-db2 now has 3 nodes (1 per zone), but , for some reason db-sys has only 2 nodes even though it should have 1 per zone. In GCP UI we check workloads to make sure nothing is failing to build. And all looks fine, so we delete the node_sys on GCP side, and re-run the terraform script to re-add the missing pool.  the cluster-db pool-sys is definitely reconfigured because it says 0-2 per zone. We need 1 per zone so lets delete that sys-pool and let the automation re-add it, to confirm our runonce automation will succeed for a dry run of all parts of the automation components described in this document.

```
terraform -chdir=terraform/gke-standard apply -var project_id=$PROJECT_ID
<snip>

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.gke-db2.google_container_node_pool.pools["pool-sys"]: Creating...
module.gke-db2.google_container_node_pool.pools["pool-sys"]: Still creating... [10s elapsed]
module.gke-db2.google_container_node_pool.pools["pool-sys"]: Still creating... [20s elapsed]
module.gke-db2.google_container_node_pool.pools["pool-sys"]: Still creating... [30s elapsed]
module.gke-db2.google_container_node_pool.pools["pool-sys"]: Still creating... [40s elapsed]
module.gke-db2.google_container_node_pool.pools["pool-sys"]: Still creating... [50s elapsed]
module.gke-db2.google_container_node_pool.pools["pool-sys"]: Still creating... [1m0s elapsed]
module.gke-db2.google_container_node_pool.pools["pool-sys"]: Still creating... [1m10s elapsed]
module.gke-db2.google_container_node_pool.pools["pool-sys"]: Still creating... [1m20s elapsed]
module.gke-db2.google_container_node_pool.pools["pool-sys"]: Still creating... [1m30s elapsed]
module.gke-db2.google_container_node_pool.pools["pool-sys"]: Still creating... [1m40s elapsed]
module.gke-db2.google_container_node_pool.pools["pool-sys"]: Still creating... [1m50s elapsed]
module.gke-db2.google_container_node_pool.pools["pool-sys"]: Creation complete after 1m57s [id=projects/predictx-postgrescluster/locations/us-west1/clusters/cluster-db2/nodePools/pool-sys]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

We now have 3 instances (1 per zone) as anticipated. Now we can retry the GKE Backup automation, and, in theory, it should succeed flawlessly with the test data we populated cluster-db1 with. It seems some of the cluster configuration generated at build time calculated the per zone variable, so we now take this into account. The automation should provide all states for the infrastructure, without any intervention such as this. This is why we are matching everything correctly, testing each component interactions with eachother,so that the template will work in all circumstances without intervention.


# Re-Testing GKE Restores
The only thing that was broken in Backup for GKE was restores, now we have given the correct matched resources and zonal configurations of each cluster, the restore should complete. So I deleted the 'restores' rest-g-db-protected-app-rest-plan-01, and manually re-tested it with the new cloud configuration we've pushed with terraform.



# A Grim Situation in postgres GXE HA - guidebook
The trim situation has been we have multiple problems obfuscating eachother. 

```
2025-04-01 11:45:23.260: child pid 224: WARNING:  failed to connect to PostgreSQL server, getaddrinfo() failed with error "Name or service not known"
2025-04-01 11:45:23.260: child pid 224: FATAL:  failed to create a backend 0 connection
2025-04-01 11:45:23.260: child pid 224: DETAIL:  not executing failover because failover_on_backend_error is off
2025-04-01 11:45:23.279: main pid 1: WARNING:  failed to connect to PostgreSQL server, getaddrinfo() failed with error "Name or service not known"
2025-04-01 11:45:23.279: main pid 1: LOG:  find_primary_node: make_persistent_db_connection_noerror failed on node 0
2025-04-01 11:45:23.291: main pid 1: WARNING:  failed to connect to PostgreSQL server, getaddrinfo() failed with error "Name or service not known"
2025-04-01 11:45:23.291: main pid 1: LOG:  find_primary_node: make_persistent_db_connection_noerror failed on node 1
2025-04-01 11:45:23.305: main pid 1: WARNING:  failed to connect to PostgreSQL server, getaddrinfo() failed with error "Name or service not known"
2025-04-01 11:45:23.305: main pid 1: LOG:  find_primary_node: make_persistent_db_connection_noerror failed on node 2
2025-04-01 11:45:23.305: main pid 1: LOG:  exit handler called (signal: 15)
2025-04-01 11:45:23.305: main pid 1: LOG:  shutting down by signal 15
2025-04-01 11:45:23.305: main pid 1: LOG:  terminating all child processes
2025-04-01 11:45:23.451: main pid 1: LOG:  Pgpool-II system is shutdown
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl get pods -n postgresql
NAME                                              READY   STATUS             RESTARTS        AGE
pg-client                                         1/1     Running            0               177m
postgresql-postgresql-ha-pgpool-8479dbf9d-d7jtx   0/1     CrashLoopBackOff   9 (2m20s ago)   20m
postgresql-postgresql-ha-postgresql-0             2/2     Running            0               90s
postgresql-postgresql-ha-postgresql-1             0/2     Pending            0               90s
postgresql-postgresql-ha-postgresql-2             0/2     Pending            0               90s
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# helm get values postgresql -n postgresql
```

We can see pgpool is in crashloopbackoff, normally a state from improper helm configuration, however, the ha nodes are failing to get the necessary PDB sometimes inconsistently. We reduce the replicas to 0, and rebuild the clusters normally to resolve this.


## Implement Helm on the Cluster-db2
```
[root@localhost gke-stateful-postgres]# helm upgrade --install postgresql bitnami/postgresql -n $NAMESPACE --values recovered-namespace-values.yaml
Release "postgresql" does not exist. Installing it now.
NAME: postgresql
LAST DEPLOYED: Tue Apr  1 12:49:02 2025
NAMESPACE: postgresql
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: postgresql
CHART VERSION: 16.6.0
APP VERSION: 17.4.0
```
We want to make sure that it can build succesfully on cluster-db2 before we try to restore the backup again.

```
[root@localhost gke-stateful-postgres]# kubectl logs -l app=postgresql-postgresql-ha-postgresql -n postgresql
No resources found in postgresql namespace.
```

Lets increase the replicas again for the postgresql-postgresql-ha-postgresql node

```
[root@localhost gke-stateful-postgres]# kubectl scale statefulset postgresql-postgresql-ha-postgresql --replicas=3 -n postgresql^C
[root@localhost gke-stateful-postgres]# kubectl get pods -n postgresql
NAME                                              READY   STATUS              RESTARTS         AGE
pg-client                                         1/1     Running             0                3h
postgresql-0                                      1/1     Running             0                99s
postgresql-postgresql-ha-pgpool-8479dbf9d-d7jtx   1/1     Running             10 (5m23s ago)   23m
postgresql-postgresql-ha-postgresql-0             2/2     Running             0                4m33s
postgresql-postgresql-ha-postgresql-1             2/2     Running             0                4m33s
postgresql-postgresql-ha-postgresql-2             0/2     ContainerCreating   0                4s
```

Looks good now. phew. We should review the logs from postgresql-1 in the ha group to get an idea of whats happening

``` 
kubectl logs postgresql-postgresql-ha-postgresql-1 -n postgresql
<shortened snip>
DEBUG: get_recovery_type(): SELECT pg_catalog.pg_is_in_recovery()
INFO: standby promoted to primary after 1 second(s)
DEBUG: setting node 1001 as primary and marking existing primary as failed
DEBUG: begin_transaction()
DEBUG: commit_transaction()
NOTICE: STANDBY PROMOTE successful
DETAIL: server "postgresql-postgresql-ha-postgresql-1" (ID: 1001) was successfully promoted to primary
DEBUG: _create_event(): event is "standby_promote" for node 1001
DEBUG: get_recovery_type(): SELECT pg_catalog.pg_is_in_recovery()
DEBUG: _create_event():
   INSERT INTO repmgr.events (              node_id,              event,              successful,              details             )       VALUES ($1, $2, $3, $4)    RETURNING event_timestamp
DEBUG: _create_event(): Event timestamp is "2025-04-01 11:51:52.163859+00"
DEBUG: _create_event(): command is '/opt/bitnami/repmgr/events/router.sh %n %e %s "%t" "%d"'
INFO: executing notification command for event "standby_promote"
DETAIL: command is:
  /opt/bitnami/repmgr/events/router.sh 1001 standby_promote 1 "2025-04-01 11:51:52.163859+00" "server \"postgresql-postgresql-ha-postgresql-1\" (ID: 1001) was successfully promoted to primary"
DEBUG: clear_node_info_list() - closing open connections
DEBUG: clear_node_info_list() - unlinking
[2025-04-01 11:51:52] [NOTICE] node 1001 has recovered, reconnecting
[2025-04-01 11:51:52] [NOTICE] notifying node "postgresql-postgresql-ha-postgresql-2" (ID: 1002) to follow node 1001
INFO:  node 1002 received notification to follow node 1001
[2025-04-01 11:51:52] [NOTICE] monitoring cluster primary "postgresql-postgresql-ha-postgresql-1" (ID: 1001)
2025-04-01 11:52:01.862 GMT [251] LOG:  checkpoint starting: immediate force wait
2025-04-01 11:52:01.914 GMT [251] LOG:  checkpoint complete: wrote 5 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.002 s, sync=0.004 s, total=0.052 s; sync files=5, longest=0.003 s, average=0.001 s; distance=16383 kB, estimate=31129 kB; lsn=0/E000060, redo lsn=0/E000028
[2025-04-01 11:52:04] [NOTICE] new standby "postgresql-postgresql-ha-postgresql-0" (ID: 1000) has connected
[2025-04-01 11:52:10] [NOTICE] new standby "postgresql-postgresql-ha-postgresql-0" (ID: 1000) has connected
```

and we see an encouraging message. Now cluster-db2 is behaving again. But we don't have the information that was restored in the backup
```
I have no name!@pg-client:/$ psql -h $HOST_PGPOOL -U postgres -a -q
postgres=# \dt
      List of relations
 Schema | Name | Type | Owner
--------+------+------+-------
(0 rows)

postgres=# /dt
postgres-# \dt
      List of relations
 Schema | Name | Type | Owner
--------+------+------+-------
(0 rows)

postgres-# \list
                                                 List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    | ICU Locale | Locale Provider |   Access privileges
-----------+----------+----------+-------------+-------------+------------+-----------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            |
 repmgr    | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            |
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            | =c/postgres          +
           |          |          |             |             |            |                 | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            | =c/postgres          +
           |          |          |             |             |            |                 | postgres=CTc/postgres
(4 rows)
```
After looking around the UI I see that the volumes failed to build. Basically a provisioning issue at GCP end caused all this trouble. I also notice gcp give so so many wrong and misleading error messages, complaining service account doesnt have this var or that role , and so on, despite succesfully implementing this without it the first time. So, all this, provisioning. Annoying but thats life. It will be useful to someone else troubleshooting these issues perhaps.

### Starting again
Now everything is in order, we should re-attempt the gke-backup. We have an automated shellscript at the moment to do this, if youd prefer to use terraform you can adapt the tf script i created for in helpers/ in the git root of this project.

```
chmod +x  disaster-recovery.sh
./disaster-recovery.sh
```
After all this shenanigans it looks like provisioning issue, quota issue, min pdb limits and so on, can make the validation of restore and backup states fail. God that is pretty awful situation actually, and I expected more, but, it is a limitation of cloud that we have to live with, this is the problem with a generic and complex system of this nature, it is prone to expensive and time consuming failures that even the cloud provider aren't sure about without expending precious time and money. Using cloud can get expensive if done incorrectly because of problems like these. Migrations that should cost a few hundred will end up costing thousands in man hours and so on. 

IT FAILS AGAIN

```
------BEGIN MANUAL BACKUP------
Create in progress for backup bkp-g-db-protected-app-bkp-plan-01 [projects/predictx-postgrescluster/locations/us-west1/operations/operation-1743509802516-631b68270ff8e-a00b5444-f5f5810b].
Creating backup bkp-g-db-protected-app-bkp-plan-01...done.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Waiting for backup to complete... Backup state: IN_PROGRESS.
Backup completed. Backup state: SUCCEEDED
------END MANUAL BACKUP------
--------------- BEGIN CREATING RESTORE PLAN ---------------
Create request issued for: [g-db-protected-app-rest-plan-01]
Waiting for operation [projects/predictx-postgrescluster/locations/us-west1/operations/operation-1743509918430-631b68959b43b-9d9b2219-e9930dc4] to complete...done.
Created restore plan [g-db-protected-app-rest-plan-01].
--------------- END CREATING RESTORE PLAN ---------------
--------------- BEGIN EXECUTING RESTORE FOR bkp-g-db-protected-app-bkp-plan-01:, RESTORE TARGET = cluster-db2, FAILED SOURCE was cluster-db1 ---------------
Create in progress for restore rest-g-db-protected-app-rest-plan-01 [projects/predictx-postgrescluster/locations/us-west1/operations/operation-1743509923013-631b6899fa3a1-b518c15c-bbeba696].
Creating restore rest-g-db-protected-app-rest-plan-01...done.
Waiting for restore to complete... Restore state: CREATING.
Waiting for restore to complete... Restore state: CREATING.
Waiting for restore to complete... Restore state: CREATING.
Waiting for restore to complete... Restore state: CREATING.
Waiting for restore to complete... Restore state: CREATING.
Waiting for restore to complete... Restore state: CREATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Waiting for restore to complete... Restore state: VALIDATING.
Restore completed. Restore state: FAILED
--------------- END EXECUTING RESTORE FOR bkp-g-db-protected-app-bkp-plan-01:, RESTORE TARGET = cluster-db2, FAILED SOURCE was cluster-db1 ---------------

Volume Validation Error: Some of the volume restores failed - projects/998933573494/locations/us-west1/restorePlans/g-db-protected-app-rest-plan-01/restores/rest-g-db-protected-app-rest-plan-01/volumeRestores/vr-9efb72ce44904cd8, projects/998933573494/locations/us-west1/restorePlans/g-db-protected-app-rest-plan-01/restores/rest-g-db-protected-app-rest-plan-01/volumeRestores/vr-9efb75ce449051f1, projects/998933573494/locations/us-west1/restorePlans/g-db-protected-app-rest-plan-01/restores/rest-g-db-protected-app-rest-plan-01/volumeRestores/vr-9efb74ce4490503e
```
My god.

## Treating the PDB Budget Scourge once and for all
Lets increase the PDB limit to a number above 0, basically if its 0 no pods are allowed to be evicted, and I think this upsets the backup/restore functions for some odd reason, or at least, inconsistent backup and restore at the very least.
```
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl get pdb -n $NAMESPACE
NAME                                  MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
postgresql                            N/A             1                 1                     37m
postgresql-postgresql-ha-pgpool       1               N/A               0                     6m48s
postgresql-postgresql-ha-postgresql   N/A             1                 0                     6m48s
```
The issue lies with the last two PDBs (for postgresql-postgresql-ha-pgpool and postgresql-postgresql-ha-postgresql), where the allowed disruptions is set to 0. This means no pod disruptions are allowed for these resources, which is preventing GKE from performing maintenance. Although there is 'nothing' wrong with the script and it worked ok, and fixed the helm values etc. The second attempts always fail.

 Issue is with the node as toBeDeleted/unschedulable , specifically gke-cluster-db2-nap-e2-standard-2-1lq-38ffa5d9-h5m4. Annoyingly it is deleted before I can look properly which made this really hard on me to fix.

```
ZONE_RESOURCE_POOL_EXHAUSTED 	gke-cluster-db2-pool-db-2fe134fa-v637 	us-west1-b 	Creating 	Apr 1, 2025, 4:42:47 pm UTC+01:00 	Instance 'gke-cluster-db2-pool-db-2fe134fa-v637' creation failed: The zone 'projects/predictx-postgrescluster/zones/us-west1-b' does not have enough resources available to fulfill the request. Try a different zone, or try again later. 
```
See above - Turns out, the problem with GKE backup is that there is not eough resources on west-1 anymore. I will have to change the region for cluster-db2 and re-apply the build.


# Verifying Data Migraton between central1.cluster-db1 to => us-west1.cluster-db2

```
# create the pgclient pod
./scripts/launch-client.sh
# exec into pg-client
 kubectl exec -it pg-client -n postgresql -- /bin/bash
# connect to pgsql
 psql -h $HOST_PGPOOL -U postgres
# create the database marker to confirm migration of db state
CREATE DATABASE "SUCCESFUL_MIGRATION_FROM_DB1_MARK";

postgres-# \list
 SUCCESFUL_MIGRATION_FROM_DB1_MARK | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            |
 postgres                          | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            |
 repmgr                            | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            |
 template0                         | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            | =c/postgres          +
                                   |          |          |             |             |            |                 | postgres=CTc/postgres
 template1                         | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            | =c/postgres          +
                                   |          |          |             |             |            |                 | postgres=CTc/postgres

```


I know its a simple test for now, but this dbdata should be seen when the cluster-db2 migrates in the data from cluster-db1 using gke backup. 

We will now make one last ditch attempt to get the whole orchestration working together;

```
./disaster_recover.sh

```

# Here lays GKE Cloud Cluster Helm f00

## Documenting a Strange GKE Kube-DNS Build Issue

The DNS failure stops the postgresql-ha group from communicating with eachother.

After succesfully completing the automation and doing a dry run, everything worked, except that when got to helm automation a few vars weren't passed as expected. However, that is when the entire build automation for gke-release stopped working without a good explanation. To eliminate a permissions issue, I use the main owner account of the project_id and check the service permissions are added, which they are. It seems artfact register read permissions are there.
3 out of the 4 kubedns containers for the 3 ha regions come up, but the 4th one doesnt because GKE refers to a completely non existent repo image. How frustrating. Everything works in the automation but google Cloud's own repo images does not. Here is how I went about debugging it. A lengthy process...

```
[root@localhost gke-stateful-postgres]# kubectl get pods -l k8s-app=kube-dns -n kube-system
NAME                        READY   STATUS             RESTARTS   AGE
kube-dns-6664c9c7fc-h7p4s   3/4     ImagePullBackOff   0          31m
kube-dns-94776b584-m842z    3/4     ImagePullBackOff   0          61m
kube-dns-94776b584-nbwcx    3/4     ImagePullBackOff   0          65m

```

I done a describe of the VM to identify the failed image pull for gke cluster causing the ImagePullBackOff

```
[root@localhost gke-stateful-postgres]# kubectl describe pod kube-dns-6664c9c7fc-h7p4s -n kube-system

Events:
  Type     Reason             Age                    From                Message
  ----     ------             ----                   ----                -------
  Warning  FailedScheduling   34m                    default-scheduler   0/7 nodes are available: 1 Insufficient memory, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}, 3 node(s) had untolerated taint {app.stateful/component: postgresql}.
  Warning  FailedScheduling   34m                    default-scheduler   0/7 nodes are available: 1 Insufficient memory, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}, 3 node(s) had untolerated taint {app.stateful/component: postgresql}. preemption: not eligible due to a terminating pod on the nominated node.
  Warning  FailedScheduling   34m                    default-scheduler   0/7 nodes are available: 1 Insufficient memory, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}, 3 node(s) had untolerated taint {app.stateful/component: postgresql}. preemption: not eligible due to a terminating pod on the nominated node.
  Normal   Scheduled          32m                    default-scheduler   Successfully assigned kube-system/kube-dns-6664c9c7fc-h7p4s to gke-cluster-db1-nap-e2-highcpu-2-10s8-e8d38620-kgll
  Normal   NotTriggerScaleUp  34m                    cluster-autoscaler  pod didn't trigger scale-up: 9 max cluster cpu, memory limit reached
  Normal   Pulled             32m                    kubelet             Container image "us-central1-artifactregistry.gcr.io/gke-release/gke-release/k8s-dns-kube-dns:1.25.0-gke.4@sha256:06837d58557deb555dfc26937cc45a32a0726a2e94f5b7c23a168273e544a077" already present on machine
  Normal   Started            32m                    kubelet             Started container dnsmasq
  Normal   Started            32m                    kubelet             Started container kubedns
  Normal   Pulled             32m                    kubelet             Container image "us-central1-artifactregistry.gcr.io/gke-release/gke-release/k8s-dns-dnsmasq-nanny:1.25.0-gke.4@sha256:5c86940a8b0578cd97f113da10850956f55b66d88a8899dfc2c60ad3fdca3ea6" already present on machine
  Normal   Created            32m                    kubelet             Created container: dnsmasq
  Normal   Created            32m                    kubelet             Created container: kubedns
  Normal   Pulled             32m                    kubelet             Container image "us-central1-artifactregistry.gcr.io/gke-release/gke-release/k8s-dns-sidecar:1.25.0-gke.4@sha256:e6adc0cf878edaa70778582684a97ac744e2e88b69de6f3d4b536e3dd68fe1fd" already present on machine
  Normal   Started            32m                    kubelet             Started container sidecar
  Normal   Created            32m                    kubelet             Created container: sidecar
  Warning  Unhealthy          32m                    kubelet             Readiness probe failed: Get "http://192.168.5.25:8081/readiness": dial tcp 192.168.5.25:8081: connect: connection refused
  Normal   Pulling            29m (x5 over 32m)      kubelet             Pulling image "us-central1-artifactregistry.gcr.io/gke-release/gke-release/gke-metrics-collector:20250317_2300_RC0@sha256:a34349ad63db36e11c2055578c3d2ef08bee75be14a2ee3cb244d9ddf74f0c19"
  Warning  Failed             29m (x5 over 32m)      kubelet             Failed to pull image "us-central1-artifactregistry.gcr.io/gke-release/gke-release/gke-metrics-collector:20250317_2300_RC0@sha256:a34349ad63db36e11c2055578c3d2ef08bee75be14a2ee3cb244d9ddf74f0c19": rpc error: code = NotFound desc = failed to pull and unpack image "us-central1-artifactregistry.gcr.io/gke-release/gke-release/gke-metrics-collector@sha256:a34349ad63db36e11c2055578c3d2ef08bee75be14a2ee3cb244d9ddf74f0c19": failed to resolve reference "us-central1-artifactregistry.gcr.io/gke-release/gke-release/gke-metrics-collector@sha256:a34349ad63db36e11c2055578c3d2ef08bee75be14a2ee3cb244d9ddf74f0c19": us-central1-artifactregistry.gcr.io/gke-release/gke-release/gke-metrics-collector@sha256:a34349ad63db36e11c2055578c3d2ef08bee75be14a2ee3cb244d9ddf74f0c19: not found
  Warning  Failed             29m (x5 over 32m)      kubelet             Error: ErrImagePull
  Normal   BackOff            2m45s (x132 over 32m)  kubelet             Back-off pulling image "us-central1-artifactregistry.gcr.io/gke-release/gke-release/gke-metrics-collector:20250317_2300_RC0@sha256:a34349ad63db36e11c2055578c3d2ef08bee75be14a2ee3cb244d9ddf74f0c19"
  Warning  Failed             2m45s (x132 over 32m)  kubelet             Error: ImagePullBackOff
```

I am greeted with extremely unceremonious message, causing great disapointment after much time and hard work exhaustively writing the code, it seems though GKE cluster does not behave consistently at all due it's over-complexity. This must make working with GKE Cluster incredibly frustrating compared to other potential solutions. However it has amazing capability for sure, so let us persevere tracing this down. I think GKE is trying to pull an image that isnt there, rather than it a serviceaccount permissions problem with the cluster.

So, I actually think it might be possible the ImagePullBackOff error could be cause by low memory, which means increasing quota or decreasing the number of nodes should fix it.

I will have to re-deploy the cluster step by step again, and troubleshoot whether this goes wrong before or after HA and HELM cofiguration.

Confirm that GKE pulling non existent image us-central1-artifactregistry.gcr.io/gke-release/gke-release/gke-metrics-collector, ErrImagePull. Unsure what to do because template changes or IAM permissions shouldnt cause this. If it was the repo read permissions for the service account the other 3 contaiers wouldnt have pulled their images from the same path (gke-release/gke-release).

It seems like my limits have been reduced the error is something to do with "  Normal   NotTriggerScaleUp  75s   cluster-autoscaler                     pod didn't trigger scale-up: 5 max cluster cpu, memory limit reached". I have looked in Google Quota Limits carefully for all mentions of cluster and 5 max cluster cpu, but I am confused what quota limit it is refering to. One source of frustration is there appears to be no way to find what quota limits have been recently hit, denying builds, so that is very unhelpful and difficult to use, because one does not have a way of parsing the logs to identify specifically what the var is. As a cloud provider I would be ashamed if I was not able to provide the limit var context for which the soft/hard limit was associated.

## Checking closely the Bitnami and Helm Image Automation

Here we are inspecting the output of helm

```
helm -n postgresql template postgresql .   --set global.imageRegistry="us-docker.pkg.dev/$PROJECT_ID/main" | grep debian
```

Output looks like revealing the versions:
```
          image: us-docker.pkg.dev/predictx-postgrescluster/main/bitnami/pgpool:4.6.0-debian-12-r2
          image: us-docker.pkg.dev/predictx-postgrescluster/main/bitnami/postgresql-repmgr:16.6.0-debian-12-r3
          image: us-docker.pkg.dev/predictx-postgrescluster/main/bitnami/postgres-exporter:0.17.1-debian-12-r2
```

## Maually Verifying the Images match Helm Template
```
[root@localhost postgresql-bootstrap]# gcloud artifacts docker images list us-docker.pkg.dev/predictx-postgrescluster/main/bitnami/pgpool --include-tags --filter="tags=4.6.0-debian-12-r2"
Listing items under project predictx-postgrescluster, location us, repository main.

IMAGE                                                           DIGEST                                                                   TAGS                CREATE_TIME          UPDATE_TIME          SIZE
us-docker.pkg.dev/predictx-postgrescluster/main/bitnami/pgpool  sha256:8a0dc3e4dc5c75fd7a0a6825906b4bd010e60b4c1ff39802106603a5c3d1ca2c  4.6.0-debian-12-r2  2025-03-30T10:37:16  2025-03-30T10:37:16  70386751
[root@localhost postgresql-bootstrap]# gcloud artifacts docker images list us-docker.pkg.dev/predictx-postgrescluster/main/bitnami/postgresql-repmgr --include-tags --filter="tags=16.6.0-debian-12-r3"
Listing items under project predictx-postgrescluster, location us, repository main.

IMAGE                                                                      DIGEST                                                                   TAGS                 CREATE_TIME          UPDATE_TIME          SIZE
us-docker.pkg.dev/predictx-postgrescluster/main/bitnami/postgresql-repmgr  sha256:13c55cc0b94333f8f87741d6c3c509ccaaddd599a75b425591ba757e500d6e9a  16.6.0-debian-12-r3  2025-03-30T10:36:54  2025-03-30T10:36:54  111648819
[root@localhost postgresql-bootstrap]# gcloud artifacts docker images list us-docker.pkg.dev/predictx-postgrescluster/main/bitnami/postgres-exporter --include-tags --filter="tags=0.17.1-debian-12-r2"
Listing items under project predictx-postgrescluster, location us, repository main.

IMAGE                                                                      DIGEST                                                                   TAGS                 CREATE_TIME          UPDATE_TIME          SIZE
us-docker.pkg.dev/predictx-postgrescluster/main/bitnami/postgres-exporter  sha256:8365c34d614424bdbb0d4347fcb21456fb2ae66b8cdcf1cc2707e14ed9dcc0fe  0.17.1-debian-12-r2  2025-03-30T10:37:01  2025-03-30T10:37:01  50971090
[root@localhost postgresql-bootstrap]#

```

This seems really perplexing, because a lot of changes were made. However on deeper inspection I see that gcr.io is being used. This seems not in accordance with the template, and I am not sure how this is controlled. I am begining to think that this is not a template issue and is something unique to GKE Cluster in Google Cloud. For good measure, I will delete the gcr.io repo in hope that this might do something, ,however the central1 artifact registry doesn't appear to be under my control, nor do the images that gke uses to build kube-dns. I really wonder where I can change this, because its not obvious at all.

```
[root@localhost postgresql-bootstrap]# kubectl describe pod kube-dns-94776b584-bgtwv -n kube-system | grep us-central1-artifactregistry.gcr.io
    Image:         us-central1-artifactregistry.gcr.io/gke-release/gke-release/k8s-dns-kube-dns:1.25.0-gke.4@sha256:06837d58557deb555dfc26937cc45a32a0726a2e94f5b7c23a168273e544a077
    Image ID:      us-central1-artifactregistry.gcr.io/gke-release/gke-release/k8s-dns-kube-dns@sha256:06837d58557deb555dfc26937cc45a32a0726a2e94f5b7c23a168273e544a077
    Image:         us-central1-artifactregistry.gcr.io/gke-release/gke-release/k8s-dns-dnsmasq-nanny:1.25.0-gke.4@sha256:5c86940a8b0578cd97f113da10850956f55b66d88a8899dfc2c60ad3fdca3ea6
    Image ID:      us-central1-artifactregistry.gcr.io/gke-release/gke-release/k8s-dns-dnsmasq-nanny@sha256:5c86940a8b0578cd97f113da10850956f55b66d88a8899dfc2c60ad3fdca3ea6
    Image:         us-central1-artifactregistry.gcr.io/gke-release/gke-release/k8s-dns-sidecar:1.25.0-gke.4@sha256:e6adc0cf878edaa70778582684a97ac744e2e88b69de6f3d4b536e3dd68fe1fd
    Image ID:      us-central1-artifactregistry.gcr.io/gke-release/gke-release/k8s-dns-sidecar@sha256:e6adc0cf878edaa70778582684a97ac744e2e88b69de6f3d4b536e3dd68fe1fd
    Image:          us-central1-artifactregistry.gcr.io/gke-release/gke-release/gke-metrics-collector:20250317_2300_RC0@sha256:a34349ad63db36e11c2055578c3d2ef08bee75be14a2ee3cb244d9ddf74f0c19
  Warning  Failed            59m (x5 over 62m)      kubelet            Failed to pull image "us-central1-artifactregistry.gcr.io/gke-release/gke-release/gke-metrics-collector:20250317_2300_RC0@sha256:a34349ad63db36e11c2055578c3d2ef08bee75be14a2ee3cb244d9ddf74f0c19": rpc error: code = NotFound desc = failed to pull and unpack image "us-central1-artifactregistry.gcr.io/gke-release/gke-release/gke-metrics-collector@sha256:a34349ad63db36e11c2055578c3d2ef08bee75be14a2ee3cb244d9ddf74f0c19": failed to resolve reference "us-central1-artifactregistry.gcr.io/gke-release/gke-release/gke-metrics-collector@sha256:a34349ad63db36e11c2055578c3d2ef08bee75be14a2ee3cb244d9ddf74f0c19": us-central1-artifactregistry.gcr.io/gke-release/gke-release/gke-metrics-collector@sha256:a34349ad63db36e11c2055578c3d2ef08bee75be14a2ee3cb244d9ddf74f0c19: not found
  Normal   BackOff           3m37s (x259 over 62m)  kubelet            Back-off pulling image "us-central1-artifactregistry.gcr.io/gke-release/gke-release/gke-metrics-collector:20250317_2300_RC0@sha256:a34349ad63db36e11c2055578c3d2ef08bee75be14a2ee3cb244d9ddf74f0c19"
```
It at least looks like issue is on google GKE Side, because the other gke-releases pull fine except this one. What's different? nothing that I can see.... Can you?

I wiped the gcr.io repo then rerun the kube-dns roll
```
[root@localhost postgresql-bootstrap]# kubectl rollout restart deployment/kube-dns --namespace=kube-system
Warning: spec.template.metadata.annotations[scheduler.alpha.kubernetes.io/critical-pod]: non-functional in v1.16+; use the "priorityClassName" field instead
Warning: spec.template.metadata.annotations[seccomp.security.alpha.kubernetes.io/pod]: non-functional in v1.27+; use the "seccompProfile" field instead
deployment.apps/kube-dns restarted
```

and here we have exactly the same problem.
```
[root@localhost postgresql-bootstrap]# kubectl get pods -l k8s-app=kube-dns -n kube-system
NAME                        READY   STATUS             RESTARTS   AGE
kube-dns-74574dcb7f-kvh89   3/4     ImagePullBackOff   0          9m16s
kube-dns-74fc497549-bdsmc   3/4     ErrImagePull       0          63s
kube-dns-94776b584-2ntq6    3/4     ImagePullBackOff   0          69m
```

I really cannot understand why this is happening or what feature about my build could possibly affect this. I am not too familiar with Google Cloud product though, perhaps other things can cause DNS failure like this. Such as Quota. I see no way in GC to ascertain easily the most recently quota's exceeded, or, quotas that werent exceeded, because the slot_limit threshold wasn't triggered because it would not fit within the quota. So this means the quota limit could be really small, and because the slot wont fit, and its not in use, ,can't trace it down easily in google quota. I suspect these sort of issues are easier to resolve when one has a lot more familiarity with the build process. But, this really is a shame, because the automation for the most part completely works. I will be honest, after nearly completing all the objectives, these problems were serious grief, as I would have liked to spend more time exposing it with a LB, and safer security groups and spent more time on autopilot :(.

Although it may not be proper, I wonder if deleting them and rerolling the deployment might help.

```
[root@localhost postgresql-bootstrap]# kubectl rollout restart deployment/kube-dns --namespace=kube-system
Warning: spec.template.metadata.annotations[scheduler.alpha.kubernetes.io/critical-pod]: non-functional in v1.16+; use the "priorityClassName" field instead
Warning: spec.template.metadata.annotations[seccomp.security.alpha.kubernetes.io/pod]: non-functional in v1.27+; use the "seccompProfile" field instead
deployment.apps/kube-dns restarted
[root@localhost postgresql-bootstrap]# kubectl rollout restart ^Cployment/kube-dns --namespace=kube-system
[root@localhost postgresql-bootstrap]# kubectl scale --replicas=0 deployment/kube-dns --namespace=kube-system
Warning: spec.template.metadata.annotations[scheduler.alpha.kubernetes.io/critical-pod]: non-functional in v1.16+; use the "priorityClassName" field instead
Warning: spec.template.metadata.annotations[seccomp.security.alpha.kubernetes.io/pod]: non-functional in v1.27+; use the "seccompProfile" field instead
deployment.apps/kube-dns scaled
[root@localhost postgresql-bootstrap]# kubectl get pods -l k8s-app=kube-dns -n kube-system
NAME                        READY   STATUS        RESTARTS   AGE
kube-dns-74574dcb7f-kvh89   3/4     Terminating   0          14m
kube-dns-74fc497549-bdsmc   3/4     Terminating   0          6m
kube-dns-85ddb76787-zb8m9   3/4     Terminating   0          38s
```

Though it appears not
```
[root@localhost postgresql-bootstrap]# kubectl get pods -l k8s-app=kube-dns -n kube-system
NAME                        READY   STATUS             RESTARTS   AGE
kube-dns-85ddb76787-6nnmr   3/4     ErrImagePull       0          67s
kube-dns-85ddb76787-lmfsh   3/4     ImagePullBackOff   0          67s
```

It is just a really weird error, and I spent several hours trying to look for the cause, despite everything being right and previously working multiple times, it is as if DNS suddenly stopped working. Perhaps IAM or permissions is causing misleading error. Also, why does this only appear to impact db1? Is it the use of the service account? I suspect so actually. I will try rebuilding without the service account to rule this out;


```
[root@localhost postgresql-bootstrap]# kubectl get pods -n kube-system
NAME                                                             READY   STATUS         RESTARTS      AGE
calico-node-k5bmt                                                1/1     Running        0             77m
calico-node-mdjnj                                                1/1     Running        0             78m
calico-node-vertical-autoscaler-6d4c965dc7-k5f2z                 1/1     Running        0             80m
calico-node-vj8hn                                                1/1     Running        0             77m
calico-typha-7dfc8f8b49-8gd57                                    0/1     Pending        0             78m
calico-typha-7dfc8f8b49-dmvhl                                    1/1     Running        0             78m
calico-typha-horizontal-autoscaler-856df86957-j6vls              1/1     Running        0             80m
calico-typha-vertical-autoscaler-bccbb6ffb-qlmr8                 1/1     Running        0             80m
event-exporter-gke-746c49d5b8-n9zcj                              2/2     Running        0             4m35s
fluentbit-gke-cmxm6                                              3/3     Running        0             79m
fluentbit-gke-zbpfl                                              3/3     Running        0             79m
fluentbit-gke-zvnd8                                              3/3     Running        0             79m
gke-metadata-server-7mlnm                                        1/1     Running        0             79m
gke-metadata-server-m9qnx                                        1/1     Running        0             79m
gke-metadata-server-pkw4f                                        1/1     Running        0             79m
ip-masq-agent-jhdz6                                              1/1     Running        0             79m
ip-masq-agent-khcdv                                              1/1     Running        0             79m
ip-masq-agent-nmfh9                                              1/1     Running        0             79m
konnectivity-agent-7d6f885699-fc76w                              2/2     Running        0             79m
konnectivity-agent-7d6f885699-mnk2h                              2/2     Running        0             80m
konnectivity-agent-7d6f885699-rfkvc                              2/2     Running        0             79m
konnectivity-agent-autoscaler-6c7895ffbf-rcrvm                   1/1     Running        0             80m
kube-dns-85ddb76787-6nnmr                                        3/4     ErrImagePull   0             3m50s
kube-dns-85ddb76787-lmfsh                                        3/4     ErrImagePull   0             3m50s
kube-dns-autoscaler-56f4c4d44-klqc6                              1/1     Running        0             80m
kube-proxy-gke-cluster-db1-nap-e2-highcpu-2-170j-9f5c5937-mp74   1/1     Running        0             79m
kube-proxy-gke-cluster-db1-pool-db-a1c8486e-z3l1                 1/1     Running        0             79m
kube-proxy-gke-cluster-db1-pool-sys-960c1684-b3ct                1/1     Running        0             79m
l7-default-backend-5bbfcf9b-gg9hh                                1/1     Running        0             80m
metrics-server-v1.32.0-84dd868749-9hrf2                          1/1     Running        0             79m
netd-csqdb                                                       3/3     Running        0             79m
netd-smc2c                                                       3/3     Running        0             79m
netd-smgjs                                                       3/3     Running        0             79m
pdcsi-node-4dbbp                                                 2/2     Running        1 (79m ago)   79m
pdcsi-node-779fc                                                 2/2     Running        1 (79m ago)   79m
pdcsi-node-x4h85                                                 2/2     Running        0             79m
[root@localhost postgresql-bootstrap]#
```

I really think that, it should not be this hard to trouleshoot a dns issue, but I suspect the provision of the DNS is being caused by a variable conflict with the sizeof cluster, or quota variables, ,and I just dont have familiarity with google cloud enough to fix it quickly. It is most likely the fix for this error will take several minutes only I am just not sure what it is. Having had to think about other things I am also not used to working with it has made it challenging.
```
[root@localhost postgresql-bootstrap]#   kubectl delete deployment kube-dns -n kube-system
deployment.apps "kube-dns" deleted
```

# Exploring DNS Failure of kube-system on GKE

We will try and reinstall the kube-system so it can pull a working image of a version that will build.
```
[root@localhost postgresql-bootstrap]# helm repo add coredns https://charts.coredns.org
Error: looks like "https://charts.coredns.org" is not a valid chart repository or cannot be reached: Get "https://charts.coredns.org/index.yaml": dial tcp: lookup charts.coredns.org on 192.168.1.254:53: no such host
[root@localhost postgresql-bootstrap]# helm repo add coredns https://coredns.github.io/helm
"coredns" has been added to your repositories
```
Then we update the repo;
```
[root@localhost postgresql-bootstrap]# helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "coredns" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈Happy Helming!⎈
```
Then we reintall kube-dns system using latest coredns

```
[root@localhost postgresql-bootstrap]# helm install coredns coredns/coredns --namespace kube-system
Error: INSTALLATION FAILED: cannot re-use a name that is still in use
[root@localhost postgresql-bootstrap]# helm uninstall coredns -n kube-system
release "coredns" uninstalled
[root@localhost postgresql-bootstrap]# helm install coredns coredns/coredns --namespace kube-system
NAME: coredns
LAST DEPLOYED: Sun Mar 30 15:31:34 2025
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
```
CoreDNS is now running in the cluster as a cluster-service.

It can be tested with the following:

1. Launch a Pod with DNS tools:
```
kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools
```
2. Query the DNS server:
```
[root@localhost postgresql-bootstrap]# kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools
Error from server (AlreadyExists): pods "dnstools" already exists
```
Delete existing pods failing
```
[root@localhost postgresql-bootstrap]# kubectl delete pod dnstools
```
#Attempt to build from latest image a pod and test hostname resolution
```
[root@localhost postgresql-bootstrap]# kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools
If you don't see a command prompt, try pressing enter.
dnstools#  host kubernetes


;; connection timed out; no servers could be reached

```
Thinks seem borked with it, and DNS is the only thing holding back Development. What a pain.
The issue is definitely kaliko i think. You can try running the following to get events from the system

```
[root@localhost postgresql-bootstrap]# kubectl get events -n kube-system
```

# Pertinent error messages:

```
28m         Warning   FailedCreatePodSandBox   pod/calico-node-vertical-autoscaler-6d4c965dc7-npmt6                 Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "1724729e3ee714c0e788a992ecb5958a4f2e3534ddad5b0757d261d9a2b76fe1": plugin type="calico" failed (add): error getting ClusterInformation: resource does not exist: ClusterInformation(default) with error: clusterinformations.crd.projectcalico.org "default" not found
```

```
6m59s       Warning   FailedScheduling         pod/coredns-coredns-64fc886fd4-b6zdm                                 0/7 nodes are available: 1 Insufficient memory, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}, 3 node(s) had untolerated taint {app.stateful/component: postgresql}. preemption: 0/7 nodes are available: 1 No preemption victims found for incoming pod, 6 Preemption is not helpful for scheduling.
119s        Normal    NotTriggerScaleUp        pod/coredns-coredns-64fc886fd4-b6zdm                                 pod didn't trigger scale-up: 9 max cluster cpu, memory limit reached
66s         Warning   FailedScheduling         pod/coredns-coredns-64fc886fd4-b6zdm                                 0/7 nodes are available: 1 Insufficient memory, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}, 3 node(s) had untolerated taint {app.stateful/component: postgresql}. preemption: 0/7 nodes are available: 1 No preemption victims found for incoming pod, 6 Preemption is not helpful for scheduling.
7m          Normal    SuccessfulCreate         replicaset/coredns-coredns-64fc886fd4                                Created pod: coredns-coredns-64fc886fd4-b6zdm
7m          Normal    ScalingReplicaSet        deployment/coredns-coredns                                           Scaled up replica set coredns-coredns-64fc886fd4 from 0 to 1
12m         Warning   FailedScheduling         pod/event-exporter-gke-746c49d5b8-4mtbz                              0/7 nodes are available: 1 Insufficient memory, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}, 3 node(s) had untolerated taint {app.stateful/component: postgresql}. preemption: 0/7 nodes are available: 1 No preemption victims found for incoming pod, 6 Preemption is not helpful for scheduling.
12m         Normal    NotTriggerScaleUp        pod/event-exporter-gke-746c49d5b8-4mtbz                              pod didn't trigger scale-up: 9 max cluster cpu, memory limit reached
11m         Warning   FailedScheduling         pod/event-exporter-gke-746c49d5b8-4mtbz                              0/7 nodes are available: 1 Insufficient memory, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}, 3 node(s) had untolerated taint {app.stateful/component: postgresql}. preemption: 0/7 nodes are available: 1 No preemption victims found for incoming pod, 6 Preemption is not helpful for scheduling.
```
This is caused by the min unavailable or memory limit value, preventing a node from being scheduled.


# Reconfiguring Kube-Dns, Reinstalling, Pulling new configmap

```
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl delete configmap coredns -n kube-system
configmap "coredns" deleted
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/dns/coredns/coredns.yaml
error: unable to read URL "https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/dns/coredns/coredns.yaml", server reported 404 Not Found, status code=404
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl delete deployment coredns -n kube-system
deployment.apps "coredns" deleted
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# helm install coredns coredns/coredns --namespace kube-system
Error: INSTALLATION FAILED: cannot re-use a name that is still in use
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# helm uninstall coredns -n kube-system
release "coredns" uninstalled
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# helm list -n kube-system
NAME    NAMESPACE       REVISION        UPDATED STATUS  CHART   APP VERSION
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# helm install coredns coredns/coredns --namespace kube-system
NAME: coredns
LAST DEPLOYED: Sun Mar 30 15:50:53 2025
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CoreDNS is now running in the cluster as a cluster-service.
```
It can be tested with the following:

1. Launch a Pod with DNS tools:
```
kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools
```

2. Query the DNS server:
```
host kubernetes
```
## Starting a DNStool console to Troubleshoot KUBE DNS Failure
```
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools
Error from server (AlreadyExists): pods "dnstools" already exists

[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# helm uninstall co^Cn kube-system
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl delete pod dnstools
pod "dnstools" deleted
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools
If you don't see a command prompt, try pressing enter.
dnstools# host kubernetes
;; connection timed out; no servers could be reached
dnstools# exit
^C[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# helm list -n kube-system
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
coredns kube-system     1               2025-03-30 15:50:53.857713588 +0100 BST deployed        coredns-1.39.2  1.12.0
```

After much ado, discovered this is caused by PDR Quota on my account. Which has been a roadblock as to achieving what i desired which was upgrade procedure, disaster recovery, and migration to db2. 

Also something is wrong with the nameservers. I think it would be faster at this point to just rebuild the project each time to prevent leftovers from happening. It was worth the trouble for the experience gained though.

# Final Remarks DNS Failure causes Build to halt

Unknown reason for the DNS Failure, likely to do with my attempt to delete and rebuild it when it stopped working though. Also some images are not being pulled for GKE. It looks like permissions, but, this worked fine before.
#
#
```
[root@localhost gke-stateful-postgres]# kubectl get all -n $NAMESPACE
NAME                                                        READY   STATUS             RESTARTS      AGE
pod/pg-client                                               1/1     Running            0             133m
pod/postgresql-postgresql-bootstrap-pgpool-d6dd4dd4-g9kbc   1/1     Running            0             89m
pod/postgresql-postgresql-ha-pgpool-8479dbf9d-b5f92         0/1     Running            0             89m
pod/postgresql-postgresql-ha-postgresql-0                   0/2     Pending            0             89m
pod/postgresql-postgresql-ha-postgresql-1                   1/2     CrashLoopBackOff   6 (96s ago)   89m
pod/postgresql-postgresql-ha-postgresql-2                   1/2     Running            6 (76s ago)   89m
pod/prepare-three-zone-ha-567487b7c-4qw28                   1/1     Running            0             92m

NAME                                                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/postgresql-postgresql-ha-pgpool                ClusterIP   192.168.107.93   <none>        5432/TCP   89m
service/postgresql-postgresql-ha-postgresql            ClusterIP   192.168.123.49   <none>        5432/TCP   89m
service/postgresql-postgresql-ha-postgresql-headless   ClusterIP   None             <none>        5432/TCP   89m
service/postgresql-postgresql-ha-postgresql-metrics    ClusterIP   192.168.90.225   <none>        9187/TCP   89m

NAME                                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/postgresql-postgresql-bootstrap-pgpool   1/1     1            1           89m
deployment.apps/postgresql-postgresql-ha-pgpool          0/1     1            0           89m
deployment.apps/prepare-three-zone-ha                    1/1     1            1           92m

NAME                                                              DESIRED   CURRENT   READY   AGE
replicaset.apps/postgresql-postgresql-bootstrap-pgpool-d6dd4dd4   1         1         1       89m
replicaset.apps/postgresql-postgresql-ha-pgpool-8479dbf9d         1         1         0       89m
replicaset.apps/prepare-three-zone-ha-567487b7c                   1         1         1       92m

NAME                                                   READY   AGE
statefulset.apps/postgresql-postgresql-ha-postgresql   0/3     89m
[root@localhost gke-stateful-postgres]# helm install coredns coredns/coredns --namespace kube-system
NAME: coredns
LAST DEPLOYED: Sun Mar 30 19:46:46 2025
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CoreDNS is now running in the cluster as a cluster-service.

It can be tested with the following:

1. Launch a Pod with DNS tools:

kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools

2. Query the DNS server:

/ # host kubernetes
[root@localhost gke-stateful-postgres]# kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools

If you don't see a command prompt, try pressing enter.

dnstools# host kubernetes
;; connection timed out; no servers could be reached
dnstools# cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local us-central1-b.c.predictx-postgrescluster.internal c.predictx-postgrescluster.internal google.internal
nameserver 192.168.64.10
options ndots:5
dnstools#
```

Constantly hitting quotas and 10 minute build and destroy times has been a frustratingly annoying. As has no support for delete protection disable for google versions <5.00 which are necesary to avoid network cli bugs
```
CrashLoopBackOff Container 'postgresql' keeps crashing.
PodUnschedulable Cannot schedule pods: Preemption is not helpful for scheduling.
PodUnschedulable Cannot schedule pods: Insufficient cpu.
PodUnschedulable Cannot schedule pods: No preemption victims found for incoming pod.
PodUnschedulable Cannot schedule pods: node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}.
PodUnschedulable Cannot schedule pods: node(s) didn't match Pod's node affinity/selector.
```

Fixed main repo kube-dns issues, new build failures, and health alerts, but at least kube-dns is fixed, nothing was working without that in the ha group.
```
kube-dns-5d469d74b4-bzp6p                                        4/4     Running   0          58m
kube-dns-5d469d74b4-z2btd                                        4/4     Running   0          54m
kube-dns-autoscaler-6c87cf5796-xws6j                             1/1     Running   0          56m

```

Increased the values of cluster temporarily to test helm builds and provisioning, the will slowly reduce.

The same problem with backoff, appears related to cluster limits;
```
kubectl describe pod postgresql-postgresql-ha-postgresql-1
Events:
  Type     Reason                  Age                   From                                   Message
  ----     ------                  ----                  ----                                   -------
  Normal   Scheduled               5m18s                 gke.io/optimize-utilization-scheduler  Successfully assigned default/postgresql-postgresql-ha-postgresql-1 to gke-cluster-db1-pool-db-c163639c-dk1t
  Normal   SuccessfulAttachVolume  5m14s                 attachdetach-controller                AttachVolume.Attach succeeded for volume "pvc-74653481-490f-4d53-9617-a3e2aa503bc6"
  Normal   Pulled                  5m7s                  kubelet                                Container image "us-docker.pkg.dev/predictx-postgrescluster/main/bitnami/postgres-exporter:0.17.1-debian-12-r2" already present on machine
  Normal   Created                 5m7s                  kubelet                                Created container: metrics
  Normal   Started                 5m7s                  kubelet                                Started container metrics
  Warning  Unhealthy               4m53s                 kubelet                                Readiness probe failed: psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  the database system is starting up
  Warning  Unhealthy               4m53s                 kubelet                                Readiness probe failed: psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "postgres"
  Normal   Pulled                  106s (x6 over 5m7s)   kubelet                                Container image "us-docker.pkg.dev/predictx-postgrescluster/main/bitnami/postgresql-repmgr:16.6.0-debian-12-r3" already present on machine
  Normal   Created                 106s (x6 over 5m7s)   kubelet                                Created container: postgresql
  Normal   Started                 106s (x6 over 5m7s)   kubelet                                Started container postgresql
  Warning  BackOff                 11s (x23 over 4m47s)  kubelet                                Back-off restarting failed container postgresql in pod postgresql-postgresql-ha-postgresql-1_default(56e370fd-eb9f-42e3-9cfb-47b5f3ec17a9)
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]#
```
Contininuing on we redeploy Helm
```
helm upgrade --install postgresql . \
  --set global.imageRegistry="us-docker.pkg.dev/$PROJECT_ID/main" \
  --set postgresql.password="$(gcloud secrets versions access latest --secret=DB_PASSWORD | tr -d '\n')" \
  --set postgresql.database="$(gcloud secrets versions access latest --secret=DB_NAME | tr -d '\n')" \
  -n postgresql
```
Later on we will reconfigure the imageregistry to use docker.io bitnami repo which is kept up more up to date. 

# Output looks like
```
W0331 04:53:51.449662 1396621 warnings.go:70] spec.template.spec.topologySpreadConstraints[0].labelSelector: a null labelSelector results in matching no pod
NAME: postgresql
LAST DEPLOYED: Mon Mar 31 04:53:46 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
==== BEGIN BUILD CREDENTIALS INFO====
```

# Namespace also missing labels/tags
```[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl get all -n $NAMESPACE
No resources found in postgresql namespace.
```
I think this might break stuff. 

Cofirming the source of the issue was Chart VARS not getting passed or changing between versions, will track this and fix it soon.
```[root@localhost gke-stateful-postgres]# ./scripts/launch-client.sh

Launching Pod pg-client in the namespace postgresql ...
Error from server (NotFound): secrets "postgresql-postgresql-ha-postgresql" not found
Error from server (NotFound): secrets "postgresql-postgresql-ha-postgresql" not found
pod/pg-client created
waiting for the Pod to be ready
```

We are getting close to fully working again.
```
[root@localhost gke-stateful-postgres]# kubectl get all
NAME                                                        READY   STATUS             RESTARTS        AGE
pod/postgresql-postgresql-bootstrap-pgpool-d6dd4dd4-qm2fq   1/1     Running            0               25m
pod/postgresql-postgresql-ha-pgpool-8479dbf9d-pgh8w         1/1     Running            0               25m
pod/postgresql-postgresql-ha-postgresql-0                   2/2     Running            0               25m
pod/postgresql-postgresql-ha-postgresql-1                   1/2     CrashLoopBackOff   9 (3m13s ago)   25m
pod/postgresql-postgresql-ha-postgresql-2                   1/2     CrashLoopBackOff   9 (3m7s ago)    25m

NAME                                                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/kubernetes                                     ClusterIP   192.168.64.1     <none>        443/TCP    82m
service/postgresql-postgresql-ha-pgpool                ClusterIP   192.168.85.158   <none>        5432/TCP   25m
service/postgresql-postgresql-ha-postgresql            ClusterIP   192.168.100.68   <none>        5432/TCP   25m
service/postgresql-postgresql-ha-postgresql-headless   ClusterIP   None             <none>        5432/TCP   25m
service/postgresql-postgresql-ha-postgresql-metrics    ClusterIP   192.168.99.117   <none>        9187/TCP   25m

NAME                                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/postgresql-postgresql-bootstrap-pgpool   1/1     1            1           25m
deployment.apps/postgresql-postgresql-ha-pgpool          1/1     1            1           25m

NAME                                                              DESIRED   CURRENT   READY   AGE
replicaset.apps/postgresql-postgresql-bootstrap-pgpool-d6dd4dd4   1         1         1       25m
replicaset.apps/postgresql-postgresql-ha-pgpool-8479dbf9d         1         1         1       25m

NAME                                                   READY   AGE
statefulset.apps/postgresql-postgresql-ha-postgresql   1/3     25m

```

# Fixing PG Client Image Pull Failure
It seems that it is trying to pull different helm images sometimes depending on the gke version/build and the helmdependency lists. Here is how I fixed the workload;

See below solution, also enabled in helm script.
[root@localhost gke-stateful-postgres]# ./scripts/gcr.sh bitnami/postgresql-repmgr 15.1.0-debian-11-r0
Working on project: predictx-postgrescluster
15.1.0-debian-11-r0: Pulling from bitnami/postgresql-repmgr
Digest: sha256:2bf6e92edd90563f71594a83ffb85dedc4cd585e1e20eff0e606cf699588b44b
Status: Image is up to date for bitnami/postgresql-repmgr:15.1.0-debian-11-r0

Whilst confirming pgclient then appeared greenlighted, I try the pgclient, it seems indeed the versio of helms postgresql was expecting slightly different secret format than I anticipated; I think that once this is resolved that builds should suceed completely. 
```
[root@localhost gke-stateful-postgres]# ./scripts/launch-client.sh

Launching Pod pg-client in the namespace postgresql ...
Error from server (NotFound): secrets "postgresql-postgresql-ha-postgresql" not found
Error from server (NotFound): secrets "postgresql-postgresql-ha-postgresql" not found
Error from server (AlreadyExists): pods "pg-client" already exists
waiting for the Pod to be ready
Copying script files to the target Pod pg-client ...
Pod: pg-client is healthy
```

Unless kubedns fails again, and I find that you now have to generate yaml file to reload coredns services, and google removed 404'ing the yaml file mentioned in documentation.  That's all folks. It's a long fu, and needs shortening for real documentation.

Last TODO: need to fix google terraform version to ~>5.00 so i can use the delete_protection = false flag. It's been a real pain having to destroy the cluster heads manually. Terraform removes all the nodes and rules, just, not the cluster. Apparently the delete protection flag was introduced in versions over 5.00. This needs addressing for terraform destroy to work as expected.

# Fixing Helm Automation for complete autoinstaller task

## Debugging Helm Chart
```
kubectl get secrets postgresql-db-secret -n postgresql -o yaml
#verifying secret
```
If something is missing, Helm might not be using the Secret correctly—check values.yaml and templates/.

## Current format used by postgresql Helm Chart
```
data:
  password: <base64-encoded-value>
  database: <base64-encoded-value>
```
Note: Helm encodes value into base64 received from GSM in plaintext. Using --set has some risks, without sanitation.

## Check Pod Environment Vars
```
kubectl describe pod <postgresql-pod-name> -n postgresql
#check helm templates

grep -r "password" helm/templates/
```

# How this Could Break Your HA PostgreSQL Chart

## 1.Password Might Be Required

1. Many PostgreSQL Helm charts (especially HA ones) require a password to properly initialize replication and clustering.
If postgresql.password is empty, the cluster might fail to start or could create an unexpected default password that doesn’t match what other services expect.

## 2.Database Initialization Issues

If postgresql.database is empty, the chart might not create a database, causing connection failures for apps expecting it.

## HA Components (PgPool, Replication) Might Fail

If HA features like PgPool-II or Patroni depend on these values being set, they could fail to configure correctly.

## 🔍 How to Check if It's Causing Issues
```
kubectl describe statefulset postgresql -n postgresql
```
Look for error messages related to password authentication or missing database configurations.
## Check pod logs for failures
```
kubectl logs -l app=postgresql -n postgresql
```

Common errors:

    FATAL: password authentication failed

    ERROR: database "xyz" does not exist

    pgpool: failed to authenticate backend

## Verify That Secrets Exist and Are Used
```
kubectl get secrets -n postgresql
```
Check if Helm actually set the secrets.

# ✅ How to Fix This
#
## Option 1 - Direct Set (not super secure)
```
helm upgrade --install postgresql . \
  --set postgresql.password="$(gcloud secrets versions access latest --secret=DB_PASSWORD | tr -d '\n')" \
  --set postgresql.database="$(gcloud secrets versions access latest --secret=DB_NAME | tr -d '\n')" \
  -n postgresql
```
## Option 2 - Kubernetes Password in gsm
```
kubectl create secret generic postgresql-db-secret \
  --from-literal=password="$(gcloud secrets versions access latest --secret=DB_PASSWORD)" \
  --from-literal=database="$(gcloud secrets versions access latest --secret=DB_NAME)" \
  -n postgresql
```

Refrence the secret in helm like, noting the trim tr -d line so anything unusual wont break helm.
```
helm upgrade --install postgresql . \
  --set global.imageRegistry="us-docker.pkg.dev/$PROJECT_ID/main" \
  --set postgresql.password="$(gcloud secrets versions access latest --secret=DB_PASSWORD | tr -d '\n')" \
  --set postgresql.database="$(gcloud secrets versions access latest --secret=DB_NAME | tr -d '\n')" \
  -n postgresql
```
## 🚀 Final Checks after Deployment
#
```
kubectl get statefulset -n postgresql
```
## Finding the Correct StatefulSet Name if statefulset missing

```
kubectl get all -n postgresql
```
Look for something like
```
NAME                                READY   STATUS    RESTARTS   AGE
statefulset.apps/postgresql-ha      2/2     Running   0          30m
```
If you see a StatefulSet like postgresql-ha, then describe it:
```
kubectl describe statefulset postgresql-ha -n postgresql
```
## Step 2 Check if helm deployment exists
```
helm list -n postgresql
```
### Check if pods were created
```
kubectl get pods -n postgresql
```
## Debugging CrashLoopBackOff or Error states
```
kubectl logs <pod-name> -n postgresql
```
##Redeploy the script something like
```
# may need to uninstall
helm uninstall postgresql
# install
helm upgrade --install postgresql . \
  --set postgresql.password="$(gcloud secrets versions access latest --secret=DB_PASSWORD | tr -d '\n')" \
  --set postgresql.database="$(gcloud secrets versions access latest --secret=DB_NAME | tr -d '\n')" \
  -n postgresql
```

# Running Automation with Helm Deploy Alone (without terraform)

This is very useful as you wont have to keep running template. Also if you place regional db-clusters with one zone, you can add greater replication/redundancy later on.
```
chmod +x deploy_helm_postgres.sh
./deploy_helm_postgressql.sh
<snipped>
==== HELM CHART ENDS HERE =====
Release "postgresql" does not exist. Installing it now.
W0331 07:40:37.126206 1423321 warnings.go:70] spec.template.spec.topologySpreadConstraints[0].labelSelector: a null labelSelector results in matching no pod
NAME: postgresql
LAST DEPLOYED: Mon Mar 31 07:40:31 2025
NAMESPACE: postgresql
STATUS: deployed
REVISION: 1
TEST SUITE: None
==== BEGIN BUILD CREDENTIALS INFO====
auth.username:<someuser>
auth.password:<somepassword>
auth.database:<databasename>
==== END BUILD CREDENTIALS INFO ====
Giving helm some grace time before attempting to pull build from kubectl get...
NAME                                                        READY   STATUS    RESTARTS   AGE
pod/pg-client                                               1/1     Running   0          141m
pod/postgresql-postgresql-bootstrap-pgpool-d6dd4dd4-bh29j   1/1     Running   0          33s
pod/postgresql-postgresql-ha-pgpool-8479dbf9d-rplr5         1/1     Running   0          33s
pod/postgresql-postgresql-ha-postgresql-0                   2/2     Running   0          33s
pod/postgresql-postgresql-ha-postgresql-1                   1/2     Running   0          33s
pod/postgresql-postgresql-ha-postgresql-2                   1/2     Running   0          33s

NAME                                                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/postgresql-postgresql-ha-pgpool                ClusterIP   192.168.67.157   <none>        5432/TCP   34s
service/postgresql-postgresql-ha-postgresql            ClusterIP   192.168.72.104   <none>        5432/TCP   34s
service/postgresql-postgresql-ha-postgresql-headless   ClusterIP   None             <none>        5432/TCP   34s
service/postgresql-postgresql-ha-postgresql-metrics    ClusterIP   192.168.90.220   <none>        9187/TCP   34s

NAME                                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/postgresql-postgresql-bootstrap-pgpool   1/1     1            1           35s
deployment.apps/postgresql-postgresql-ha-pgpool          1/1     1            1           35s

NAME                                                              DESIRED   CURRENT   READY   AGE
replicaset.apps/postgresql-postgresql-bootstrap-pgpool-d6dd4dd4   1         1         1       35s
replicaset.apps/postgresql-postgresql-ha-pgpool-8479dbf9d         1         1         1       35s

NAME                                                   READY   AGE
statefulset.apps/postgresql-postgresql-ha-postgresql   1/3     34s
```

Then check the statefulset again 
```
kubectl get statefulset -n postgresql
```

#Final Checks
Output should look like:
```
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl get statefulset -n postgresql
NAME                                  READY   AGE
postgresql-postgresql-ha-postgresql   3/3     3m39s
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl get pods -n postgresql
NAME                                                    READY   STATUS    RESTARTS   AGE
pg-client                                               1/1     Running   0          144m
postgresql-postgresql-bootstrap-pgpool-d6dd4dd4-bh29j   1/1     Running   0          3m58s
postgresql-postgresql-ha-pgpool-8479dbf9d-rplr5         1/1     Running   0          3m58s
postgresql-postgresql-ha-postgresql-0                   2/2     Running   0          3m58s
postgresql-postgresql-ha-postgresql-1                   2/2     Running   0          3m58s
postgresql-postgresql-ha-postgresql-2                   2/2     Running   0          3m58s
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl get all -n postgresql
NAME                                                        READY   STATUS    RESTARTS   AGE
pod/pg-client                                               1/1     Running   0          145m
pod/postgresql-postgresql-bootstrap-pgpool-d6dd4dd4-bh29j   1/1     Running   0          4m11s
pod/postgresql-postgresql-ha-pgpool-8479dbf9d-rplr5         1/1     Running   0          4m11s
pod/postgresql-postgresql-ha-postgresql-0                   2/2     Running   0          4m11s
pod/postgresql-postgresql-ha-postgresql-1                   2/2     Running   0          4m11s
pod/postgresql-postgresql-ha-postgresql-2                   2/2     Running   0          4m11s

NAME                                                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/postgresql-postgresql-ha-pgpool                ClusterIP   192.168.67.157   <none>        5432/TCP   4m12s
service/postgresql-postgresql-ha-postgresql            ClusterIP   192.168.72.104   <none>        5432/TCP   4m12s
service/postgresql-postgresql-ha-postgresql-headless   ClusterIP   None             <none>        5432/TCP   4m12s
service/postgresql-postgresql-ha-postgresql-metrics    ClusterIP   192.168.90.220   <none>        9187/TCP   4m12s

NAME                                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/postgresql-postgresql-bootstrap-pgpool   1/1     1            1           4m12s
deployment.apps/postgresql-postgresql-ha-pgpool          1/1     1            1           4m12s

NAME                                                              DESIRED   CURRENT   READY   AGE
replicaset.apps/postgresql-postgresql-bootstrap-pgpool-d6dd4dd4   1         1         1       4m13s
replicaset.apps/postgresql-postgresql-ha-pgpool-8479dbf9d         1         1         1       4m13s

NAME                                                   READY   AGE
statefulset.apps/postgresql-postgresql-ha-postgresql   3/3     4m12s

```

## Check all is alive and well with the pgclient launcher
```
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# cd gke-stateful-postgres/
[root@localhost gke-stateful-postgres]# ./scripts/launch-client.sh

Launching Pod pg-client in the namespace postgresql ...
Error from server (AlreadyExists): pods "pg-client" already exists
waiting for the Pod to be ready
Copying script files to the target Pod pg-client ...
Pod: pg-client is healthy

[root@localhost gke-stateful-postgres]# #kubectl exec -it pg-client -n postgresql -- /bin/bash
[root@localhost gke-stateful-postgres]# cd gke-stateful-postgres/^C
[root@localhost gke-stateful-postgres]# kubectl exec -it pg-client -n postgresql -- /bin/bash
I have no name!@pg-client:/$ postgres --version
postgres (PostgreSQL) 15.1
```

#
# Configuring Tertiary Account
The Helm script uses --secret=DB_PASSWORD and DB_NAME, DB_USER is unused by helm template.
However, you may want to add a tertiary user. To do that add the var metadata to GSM.

Lets demonstrate how that is achieved;

#Create Secondary/Tertiary User Secrets
replacing the tertiary_prefixes with the desired credentials.
```
gcloud secrets create TERTIARY_USER --data-file=<(echo -n "tertiary_user")
gcloud secrets create TERTIARY_PASSWORD --data-file=<(echo -n "tertiary_password")
gcloud secrets create TERTIARY_DATABASE --data-file=<(echo -n "tertiary_database")
```
Be sure to wipe your history afterwards.
#SET GSM Postgress Admin PGUSER and TERTIARY USER
Note DB_USER Secret unused, as helm chart only accepts password and dbname for admin account. That doesnt matter we can simulate it, see below.
```
PGUSER="postgres"
PGPASSWORD=$(gcloud secrets versions access latest --secret=DB_PASSWORD)
PGDATABASE=$(gcloud secrets versions access latest --secret=DB_NAME)
TERTIARY_USER=$(gcloud secrets versions access latest --secret=TERTIARY_USER)
TERTIARY_PASSWORD=$(gcloud secrets versions access latest --secret=TERTIARY_PASSWORD)
TERTIARY_DATABASE=$(gcloud secrets versions access latest --secret=TERTIARY_DATABASE)
```


# TEST Primary & Tertiary User working
```
kubectl exec -it pg-client -n postgresql -- /bin/bash -c "\
export HOST_PGPOOL='postgresql-postgresql-ha-pgpool' && \
export PGUSER='postgres' && \
export PGDATABASE='predictx' && \
export TERTIARY_USER='tertiary_user' && \
export TERTIARY_DATABASE='tertiary_db' && \
export PGPASSWORD='your_password_here' && \
psql -h \$HOST_PGPOOL -U \$PGUSER -d \$PGDATABASE -tAc \"SELECT 1;\" && \
psql -h \$HOST_PGPOOL -U \$TERTIARY_USER -d \$TERTIARY_DATABASE -tAc \"SELECT 1;\" && \
echo 'Main postgres user and tertiary user have access to their respective databases.' || \
echo 'Either the main postgres user or tertiary user does not have access to their respective database.'"
echo ""
```

##One-liner to Create the Tertiary User and Database:
```
kubectl exec -it pg-client -n postgresql -- /bin/bash -c "\
TERTIARY_USER=\$(gcloud secrets versions access latest --secret=TERTIARY_USER) && \
TERTIARY_PASSWORD=\$(gcloud secrets versions access latest --secret=TERTIARY_PASSWORD) && \
TERTIARY_DATABASE=\$(gcloud secrets versions access latest --secret=TERTIARY_DATABASE) && \
psql -h \$HOST_PGPOOL -U postgres -c \"CREATE USER \$TERTIARY_USER WITH PASSWORD '\$TERTIARY_PASSWORD';\" && \
psql -h \$HOST_PGPOOL -U postgres -c \"CREATE DATABASE \$TERTIARY_DATABASE;\" && \
psql -h \$HOST_PGPOOL -U postgres -c \"GRANT ALL PRIVILEGES ON DATABASE \$TERTIARY_DATABASE TO \$TERTIARY_USER;\" && \
echo 'Tertiary user, password, and database created successfully.'"
```
##Retest Primary (and Tertiary User after adding it) both should report OK
```
kubectl exec -it pg-client -n postgresql -- /bin/bash -c "\
export HOST_PGPOOL='postgresql-postgresql-ha-pgpool' && \
export PGUSER='postgres' && \
export PGDATABASE='predictx' && \
export TERTIARY_USER='tertiary_user' && \
export TERTIARY_DATABASE='tertiary_db' && \
export PGPASSWORD='your_password_here' && \
psql -h \$HOST_PGPOOL -U \$PGUSER -d \$PGDATABASE -tAc \"SELECT 1;\" && \
psql -h \$HOST_PGPOOL -U \$TERTIARY_USER -d \$TERTIARY_DATABASE -tAc \"SELECT 1;\" && \
echo 'Main postgres user and tertiary user have access to their respective databases.' || \
echo 'Either the main postgres user or tertiary user does not have access to their respective database.'"
```

Simple oneliner to test

```kubectl exec -it pg-client -n postgresql -- /bin/bash -c "\
export PGUSER='postgres' && \
export PGPASSWORD='$PGPASSWORD' && \
export PGDATABASE='$PGDATABASE' && \
psql -h postgresql-postgresql-ha-pgpool -U \$PGUSER -d \$PGDATABASE -tAc 'SELECT 1;' && \
echo 'Postgres user can connect to the database.' || \
echo 'Postgres user cannot connect to the database.'"
```

I am a bit tired, so these oneliners are a bit obtuse to say the least. Will streamline for a great automation.
Now, the cluster will build from start to finish without user intervention both gke standard, and the stateful postgres ha. 

## Disaster Recovery and Migration
is what I hope to cover next. That and shorten the readme by about 1000 lines.

## Theoretically you can do nearly all this above with just this one line
```
curl -s https://raw.githubusercontent.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation/refs/heads/master/autoinstaller.sh | bash
```

TODO: expose port or create vpn gateway / bastion for privatenet and document process etc
TODO: DRYRUN

## Terraform GKE Cluster and Helm Template Attempt 1

I also created a custom template for Terraform and was able to build and communicate with the cluster. Sometimes though when it was run, because of the delay in cluster state coming available terraform can quit out, probably a delay can be added to stop that happening, because, it seems to affect the password generation run time and end up getting locked out of the postgresql database, as the password is needed to rerun automation for upgrades etc. This below template is only rough but it should work, and have spent a few hours testing, and after getting Google to increase quota on max cpu to 64, Networks to 20, and Disk quotas to 1500GB, the previous build errors are behind us.

```

# Define the Google Cloud provider with project and region
provider "google" {
  project = var.project_id
  region  = var.region
}

# Define the Helm provider with Kubernetes context
provider "helm" {
  kubernetes {
    config_context = "gke_${var.project_id}_${var.region}_${var.cluster_name}"
    config_path    = "~/.kube/config"

  }
}

# Create a GKE cluster without a default node pool
resource "google_container_cluster" "gke_cluster" {
  name     = var.cluster_name
  location = var.region

  remove_default_node_pool = true  # Remove the default node pool since we define a custom one
  initial_node_count       = 1     # Placeholder value (not used since node pool is removed)

  network    = "default"           # Use the default network
  subnetwork = "default"           # Use the default subnetwork
  deletion_protection = false
}

# Create a node pool for PostgreSQL with autoscaling
resource "google_container_node_pool" "postgres_pool" {
  name       = "postgres-pool"
  cluster    = google_container_cluster.gke_cluster.name
  location   = var.region


  node_count = 3  # Initial number of nodes
  autoscaling {
    min_node_count = 3  # Minimum number of nodes
    max_node_count = 5  # Maximum number of nodes
  }

  node_config {
    machine_type = "e2-small"  # Machine type for the nodes
    #preemptible  = true         # Use preemptible nodes to reduce costs

    ]
  }
}

# Retrieve kubeconfig credentials for the created GKE cluster
resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name} --region ${var.region} --project ${var.project_id}
    EOT
  }
}

# Generate a random password for PostgreSQL
resource "random_password" "pg_password" {
  length  = 16   # Password length
  special = true # Include special characters
}


# helm requires this line to succeed succesfully before running
# gcloud container clusters get-credentials predictx-cluster --region us-central1-a --project predictx-postgrescluster


# Deploy PostgreSQL using Helm
  resource "helm_release" "postgres" {
  name       = "postgres"
  repository = "https://charts.helm.sh/stable"
  chart      = "postgresql"                           # PostgreSQL Helm chart
  namespace  = "default"                             # Kubernetes namespace
  version    = "8.6.2"

  set {
    name  = "global.postgresql.auth.database"
    value = "predictx"  # Create database 'predictx'
  }

  set {
    name  = "global.postgresql.auth.username"
    value = "px-user"  # Create user 'px-user'
  }

  set_sensitive {
    name  = "global.postgresql.auth.password"
# it seems this does not set the password given, probably because the script needs to be rerun.
# it should only be run once, for now using a static password
#    value = random_password.pg_password.result  # Set randomly generated password to test
   value = "px-user"
  }

  set {
    name  = "service.type"
    value = "LoadBalancer"  # Expose PostgreSQL via NodePort for external access
  }
}

# Create a Firewall Rule to allow external access to NodePort range
resource "google_compute_firewall" "allow_nodeport" {
  name    = "allow-nodeport"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["30000-32767","5432"]  # Allow NodePort range for external access
  }

  source_ranges = ["0.0.0.0/0"]  # Allow connections from any IP address

  target_tags = ["gke-node-pool"]  # Apply to GKE nodes
}


output "postgres_password" {
  description = "The randomly generated password for the px-user"
  value       = random_password.pg_password.result
  sensitive   = true
}


```

The above script does several things.

* Loads the kubeconfig credentials to the local controller, after building, may need delay to prevent failures.
* Uses min_node_count 3 and max_node_count =5
* Installs postgresql on the cluster via helm stable chart repo
* Sets a db name, username for the db, and generates random password [todo: privileges/granular permissions, disable root etc, safedb install etc]
* Exposes a public ipv4 via a LoadBalancer, Also support Nodeport, however that is apparently not exposable directly as an public ipv4, and only works within gcloud range.
* Problems that need addressing: firewall needs extra ports 5432 added. Password finicky and not always retrieved. Sometimes pull fail due to quota which made troubleshooting this difficult, and time consuming.
* Insecure usage of source_ranges and oauth_scopes variable, not required, some of the permission concerns were difficult to address without better knowledge of google cloud.

