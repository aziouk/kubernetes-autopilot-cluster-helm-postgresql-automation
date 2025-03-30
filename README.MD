# 🚀 Deploy PostgreSQL on GKE with Terraform 

## What this does
This provides terraform and helm automation templates for multi region, redundant, stateful Google Cloud GKE Cluster, for PostgreSQL using Helm Charts and Docker-Kubernetes as a deployment strategy.

This github repo collection uses the reference samples from google cloud. We have forked it at https://github.com/aziouk/kubernetes-engine-samples and that fork is a subrepo of this repo. The GoogleCloudPlatform samples repo can be found [here](https://github.com/GoogleCloudPlatform/kubernetes-engine-samples).  

Future versions of this repository will implement only kubernetes-engine-samples subrepo, and the gke-stateful-postgres folder in the root of this repository will disappear, and reappear at <mark>kubernetes-engine-samples/databases/gke-stateful-postgres</mark> instead. This will ensure changes will be more consistent and the subrepo can be used for global changes.

This resource consists of two components 1. Terraform Templates for **Google Kubernetes Engine (GKE) cluster** and 2. **Helm charts** Autoinstaller for bootstrapping Terraform Built GKE Cluster in the same namespace. todo; shellscript that executes terraform build and helm autoinstaller. 

## ⚡ Quick Start
Before using the Quick Start please view the prequisites just below, as they are needed for the scripts to succeed.
# Install Method 1
make sure you run it in a path you wont to clone the repo to;
```
wget https://raw.githubusercontent.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation/refs/heads/master/autoinstaller.sh
cat autoinstaller.sh
chmod +x ./autoinstaller.sh && ./autoinstaller.sh
```
# Install Method 2
```
curl -s https://raw.githubusercontent.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation/refs/heads/master/autoinstaller.sh | bash
```
This autoinstaller will complete the configuration of both components for google cloud GKE cluster and Helm postgres chart install.
<mark> Autoinstaller supports gke-standard cluster via terraform and postgresql ha cluster via helm templating </mark>

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

## Googles Kubernetes Cloud Examples Fail to Build (Updated 28/03/2025)
<p align="left">
  <strong>⚠️ Warning:</strong> Be forewarned that Googles Terraform and Helm templates documentation for Google Cloud are stale and unmaintained, causing most builds of their examples to imagepullerr or taint.
</p>


For details refer to the Google Cloud reference [here](https://cloud.google.com/kubernetes-engine/docs/tutorials/stateful-workloads/postgresql#autopilot), which contains significant inaccuracies, typos, and unmaintained deprecations for example <mark>role/artifactregistry.Admin</mark> should be prefixed by <mark>roles/</mark> not role/. Some api names are wrong, like  <mark>artifactregistry.repoAdmin</mark> is used now and not artifactregistry.repo</mark> as of 28/03/2025. It seems that the Google Clouds SDK own documentation repository is floating unworkable example templates which are not maintained by anyone, or it is just not a big priority for them. Perhaps there are templats elsewhere that do not suffer from these issues and the maintainer forgot to deprecate the reference?

If google unit tested their referenced templates against their own cloud docs the trouble could be probably avoided for many. Watch out for automation variables becoming empty lists, due to google changing options exposed in their api, breaking their unmaintained templates.

# Manual Installation Details
Setup your environment using 
```git clone https://github.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation
cd kubernetes-autopilot-cluster-helm-postgresql-automation/gke-stateful-postgres
```
then follow the below instructions carefully to carry out manual installation of the automation.


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
# Install GKE Region Cluster with Autopilot (flakey)
By using autopilot it is possible to build a multi region cluster with a redundant backup and nodes in seperate regions, as well as receive additional data for logging and analytics.
```
terraform -chdir=terraform/gke-autopilot init -var project_id=predictx-postgrescluster
terraform -chdir=terraform/gke-autopilot plan -var project_id=predictx-postgrescluster
terraform -chdir=terraform/gke-autopilot apply -var project_id=predictx-postgrescluster
```


# Install GKE Cluster without Autopilot (working)
```
terraform -chdir=terraform/gke-standard init
terraform -chdir=terraform/gke-standard plan -var project_id=$PROJECT_ID
terraform -chdir==terraform/gke-standard apply -var project_id=$PROJECT_ID
```
## Helm Installer for PostgreSQL
The Helm installer provided by helm_deploy_postgres.sh will automate the docker image pull and installation to the GKE Cluster using the setenv project variables and project namespace in kubectl. If you have issues with image installations check your docker status in systemctl status docker. Even though your pushing to remote, you still need a docker socket locally on the controlling machine to communicate with the remote instances in gcloud forming the cluster. 

<p align="left">
  <strong>⚠️ Warning:</strong> Google Cloud Documentation Examples has unmaintained/stale templates, instructions for helm dependencies scripts can not be trusted as correct.
</p>

You need to check carefully the output before proceeding with helm istallation
```
helm -n postgresql template postgresql .   --set global.imageRegistry="us-docker.pkg.dev/$PROJECT_ID/main"
```
The google doc dependancies are out of date, and these pulls will fail to wrong path as wrong version is used which is now missing from the repo listed. These are the changes as follows, make sure the images are there, by default they aren't retrieving the correct version specified by helm template matched chart versions in google docs. The following are used instead with this version of kubernetes builds:

```
./scripts/gcr.sh bitnami/postgresql-repmgr 16.6.0-debian-12-r3
./scripts/gcr.sh bitnami/postgres-exporter 0.17.1-debian-12-r2
./scripts/gcr.sh bitnami/pgpool 4.6.0-debian-12-r2
```
You don't need to run above. all in one helm deploy postgres script will do this for you. 

The goal is to make sure app.kubernetes version matches, I think, for pgpool, 4.6.0

## Helm Component now uses GSM To Store Vault information
You will need to set the DB_USER and DB_PASSWORD once, which is then used by helm_deploy_postgres.sh autoinstall script. Theoretically this step isn't necessary again once it is set, but it is important for first time setup of the cluster, and that anyone working on the project understands this component correctly from a security standpoint.

# Checking if GSM Is already set

```
gcloud secrets versions access latest --secret=DB_USER
gcloud secrets versions access latest --secret=DB_PASSWORD
```

# Initaializing GSM for First time
<p align="left">
  <strong>⚠️ Warning:</strong> **MUST** be run at least once for helm installer. 
Replace px-user-password and px-user with credentials. 
</p>

```
gcloud secrets create DB_PASSWORD --replication-policy="automatic"
gcloud secrets create DB_USER --replication-policy="automatic"

echo -n "px-user-password" | gcloud secrets versions add DB_PASSWORD --data-file=-
echo -n "px-user" | gcloud secrets versions add DB_USER --data-file=-

# Recommend to sanitize the plaintext password entry from BASH History something like
history -d $(history 4 | awk '{print $1}') && history -w

```

# Running Helm Automation

```bash
chmod +x helm_deploy_postgres.sh
./helm_deploy_postgres.sh
```
## Connecting to cluster-db instance
#
```
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
#
```bash
#input generated db for testing
psql -h $HOST_PGPOOL -U postgres -a -q -f /tmp/scripts/generate-db.sql
#test counting rows
psql -h $HOST_PGPOOL -U postgres -a -q -f /tmp/scripts/count-rows.sql
```
## Create Database, with credentials to named postgresdb
You can run the command <mark>psql -h $HOST_PGPOOL -U postgres -a -q -f /tmp/scripts/create-user.sql</mark> maually to update the database. 
```
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
I have no name!@pg-client:/$ psql -h $HOST_PGPOOL -U postgres -a -q -f /tmp/scripts/create-user.sql
CREATE DATABASE predictx;
psql:/tmp/scripts/create-user.sql:1: ERROR:  database "predictx" already exists
CREATE USER "px-user" WITH ENCRYPTED PASSWORD 'px-user';
psql:/tmp/scripts/create-user.sql:2: ERROR:  role "px-user" already exists
GRANT ALL PRIVILEGES ON DATABASE predictx TO "px-user";
I have no name!@pg-client:/$ quit
bash: quit: command not found
```

This will not be permanent, to make it permanent we need to update the pg_hba filee, lets find where it is located:
bitnami runs as a non root user which makes this problematic.
```
I have no name!@pg-client:/$ kubectl exec -it pg-client -n postgresql -- /bin/bash
I have no name!@pg-client:/$ psql -h $HOST_PGPOOL -U postgres -a -q
postgres=# SHOW hba_file;
                 hba_file
------------------------------------------
 /opt/bitnami/postgresql/conf/pg_hba.conf
(1 row)

```
# Troubleshooting password not updating
Found cause: bad namespace export was lost, now fixed.

Solution is
```
[root@localhost scripts]# kubectl exec -it pg-client -n postgresql -- /bin/bash
I have no name!@pg-client:/$ psql -h $HOST_PGPOOL -U postgres -a -q
postgres=# \qu
invalid command \qu
Try \? for help.
postgres=# \du
                                   List of roles
 Role name |                         Attributes                         | Member of
-----------+------------------------------------------------------------+-----------
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 px-user   |                                                            | {}
 repmgr    | Superuser, Create DB, Replication                          | {}

postgres=# exit
```

# Check Database online
```
kubectl exec -it pg-client -n postgresql -- /bin/bash -c "psql -h \$HOST_PGPOOL -U postgres -c 'SELECT version();' -a -q && echo 'PostgreSQL is running fine' || echo 'PostgreSQL is not running'"
SELECT version();
                                          version
-------------------------------------------------------------------------------------------
 PostgreSQL 16.6 on x86_64-pc-linux-gnu, compiled by gcc (Debian 12.2.0-14) 12.2.0, 64-bit
(1 row)

PostgreSQL is running fine
```

Make sure that your $NAMESPACE and $PROJECT_ID env variable is defined too.

# Check User and Data is added
```
kubectl exec -it pg-client -n postgresql -- /bin/bash -c "\
psql -h \$HOST_PGPOOL -U postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='px-user';\" && \
psql -h \$HOST_PGPOOL -U px-user -d predictx -c 'SELECT 1;' -a -q && \
echo 'px-user exists and has access to the predictx database' || \
echo 'px-user does not exist or lacks access to the predictx database'"
```


# Resolved (will remove later)
```
I have no name!@postgresql-postgresql-ha-postgresql-0:/$ kubectl exec -it postgresql-postgresql-ha-postgresql-0 -n postgresql -- psql -U postgres
bash: kubectl: command not found
I have no name!@postgresql-postgresql-ha-postgresql-0:/$ exit
exit
command terminated with exit code 127
[root@localhost scripts]# kubectl exec -it postgresql-postgresql-ha-postgresql-0 -n postgresql -- /bin/bash
Defaulted container "postgresql" out of: postgresql, metrics
I have no name!@postgresql-postgresql-ha-postgresql-0:/$ psql -U postgres
psql (16.6)
Type "help" for help.

postgres=# whoami
postgres-# id
postgres-# su - postgres
postgres-# psql
postgres-# ls -al /tmp/scripts
postgres-# exit
Use \q to quit.
postgres-# CREATE DATABASE predictx;
ERROR:  syntax error at or near "whoami"
LINE 1: whoami
        ^
postgres=# CREATE USER "px-user" WITH ENCRYPTED PASSWORD 'px-user';
ERROR:  role "px-user" already exists
postgres=# GRANT ALL PRIVILEGES ON DATABASE predictx TO "px-user";
GRANT
postgres=#
postgres=# CREATE DATABASE predictx;
ERROR:  database "predictx" already exists
postgres=# CREATE USER "px-user" WITH ENCRYPTED PASSWORD 'px-user';
ERROR:  role "px-user" already exists
postgres=# GRANT ALL PRIVILEGES ON DATABASE predictx TO "px-user";
GRANT
postgres=#
postgres=# DROP DATABASE predictx;
DROP DATABASE
postgres=# CREATE DATABASE predictx;
CREATE DATABASE
postgres=# GRANT ALL PRIVILEGES ON DATABASE predictx TO "px-user";
GRANT
postgres=# ALTER USER "px-user" WITH ENCRYPTED PASSWORD 'px-user';
ALTER ROLE
postgres=# GRANT ALL PRIVILEGES ON DATABASE predictx TO "px-user";
GRANT
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

# Working Automation for Executing Database Tasks
(Such as creating user, database, password in master cluster configuration.)
This seems like not the best way to do it and a plugin/addin will do it better like postgresql --set parameter variable for the existing mod etc.

```
# this runs as part of the autoinstaller.sh you dont need to run it
chmod +x execute-database-tasks.sh && ./execute-database-tasks.sh
```

```
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
[root@localhost gke-stateful-postgres]# echo $PROJECT_ID
predictx-postgrescluster
[root@localhost gke-stateful-postgres]# cd monitoring/
[root@localhost monitoring]# gcloud monitoring dashboards create \
        --config-from-file=dashboard/postgresql-overview.json \
        --project=$PROJECT_ID
gcloud monitoring dashboards create \
        --config-from-file dashboard/gke-postgresql.json \
        --project $PROJECT_ID
Created [0cc3adf6-2082-4ddc-a8b9-9b6c63521817].
Created [f36667d9-1d73-45fe-84de-383774c07d55].
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
```
[root@localhost terraform]# cd ../../../
[root@localhost gke-stateful-postgres]# kubectl exec -it --namespace postgresql pg-client -- /bin/bash
I have no name!@pg-client:/$ pgbench -i -h $HOST_PGPOOL -U postgres -s 200 postgres
dropping old tables...
creating tables...
generating data (client-side)...
6500000 of 20000000 tuples (32%) done (elapsed 126.58 s, remaining 262.89 s)
```

## Retrieving the Kubectl Raw
This allow you to check whether you will get the alert and its triggering profile is right etc. That is about it for now. Except that the kubectrl configuration can be obtained in raw format like
```
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


## Simulating Cluster Failure and Recovery
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
```
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

```
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
```
kubectl -n postgresql describe pods
```




## 🔐 Using Google Secret Manager (GSM)

Using GSM is more secure than storing secrets in a GCS bucket because:

- 🔒 It encrypts secrets by default.
- 🛂 It provides fine-grained access control (IAM permissions).
- 🔄 You can version secrets and rotate credentials easily.

## 🔧 Step 1: Modify Terraform to Store Secrets in GSM

### 1️⃣ Enable the Secret Manager API  

Before running Terraform, enable the Secret Manager API:  

```bash
gcloud services enable secretmanager.googleapis.com
```

## 🔄 Alternative: Store Metadata in a GCS Bucket

If you prefer storing metadata in a GCS bucket (⚠️ less secure than GSM), modify Terraform to save the password into a file and upload it:

```
# Create a GCS bucket for storing metadata
resource "google_storage_bucket" "pg_metadata" {
  name          = "predictx-db-metadata"
  location      = var.region
  force_destroy = true
}

# Store PostgreSQL credentials in the GCS bucket
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

There are two main components at present, the first piece of the automation is <mark> Google Cloud GKE Cluster terraform build component</mark> and the second the <mark>kube-credentials-handler-docker-image-deploy-chart</mark> installer component (helm_deploy_postgres.sh), which carries out the necessary tasks to install charts. Further down a rough outline of a terraform script that performs gke cluster creation and a helm upgrade install within a single script. This is still a rough outline though and isn't as complete as the gke-standard and gke-autopilot cluster autoscale examples provided.

## Comments

I do not have a lot of experience with Terraform and Helm Devops on GCP, and this my first adventure in it, but the scripts split up this way should be helpful for anyone wanting to understand, build or experiment with google GKE Clusters with and without autopilot, with and without DR, and with postgressql or any other chart. 

## Common Errors

Unfortunately because my account has several quota limits with the number of times I can spin up and down automation. I reached the limit of my quota pretty fast. Here are common errors that you will see, that are *not* a result of the automation failing, but potential barriers from untainted builds with the terraform/helm automation included. This seems especially relevant to the ha scaling quota specifically. See below for common issues;

* Pod is blocking scale down because it doesn't have enough pod disruption budget (PDB) 
* Pod is blocking scale down because its controller can't be found. 
* Can't scale up because node auto-provisioning can't provision a node pool for the pod if it would exceed resource limits. 
* Can't scale up because node auto-provisioning can't provision a node pool for a pod with failing predicates 
* Can't scale up a node pool because of a failing scheduling predicate 
* Can't scale up due to exceeded quota 

│ Error: error creating NodePool: googleapi: Error 403: Insufficient project quota to satisfy request: resource "CPUS_ALL_REGIONS": request requires '12.0' and is short '4.0'. project has a quota of '32.0' with '8.0' available. View and manage quotas at https://console.cloud.google.com/iam-admin/quotas?usage=USED&project=predictx-postgrescluster.

│ Error: Error waiting for resuming GKE node pool:
│       - all cluster resources were brought up, but: only 1 nodes out of 3 have registered; cluster may be unhealthy
│       - insufficient quota to satisfy the request: Not all instances running in IGM after 30.915058557s. Expected 1, running 0, transitioning 1. Current errors: [GCE_QUOTA_EXCEEDED]: Instance 'gke-cluster-db1-pool-db-bbafcd47-mpx5' creation failed: Quota 'CPUS' exceeded.  Limit: 24.0 in region us-central1
│       - insufficient quota to satisfy the request: Not all instances running in IGM after 31.08953717s. Expected 1, running 0, transitioning 1. Current errors: [GCE_QUOTA_EXCEEDED]: Instance 'gke-cluster-db1-pool-db-2c5de97c-ztj3' creation failed: Quota 'CPUS' exceeded.  Limit: 24.0 in region us-central1.


<mark> Solution: build a smaller cluster of 1 node only </mark> or <mark> Increase Quota Limits with GCP </mark> alternatively in my case, since this is for demo purposes only I decreased cpu limit to 100m, from 500m and replicas from 3 to 2 in the prepareforha.yaml script and main.tf provided by the google gke cluster docs samples.

It seems that the way that replicas work in zonal regions, building 3 replica instances in 3 regions builds 9 nodes, so I have reduced instances to 1, and max instances to 2. It will scale but now use <mark> much less resources </mark>.

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

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"  # Full cloud platform access
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
    ports    = ["30000-32767"]  # Allow NodePort range for external access
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

#Tasks I could use some help/tips/advice on
# It seems that there could be breakage on pg-client when master is updated. likely due to improper syncing.
#[root@localhost scripts]# ./launch-client.sh

Launching Pod pg-client in the namespace postgresql ...
Error from server (AlreadyExists): pods "pg-client" already exists
waiting for the Pod to be ready
Copying script files to the target Pod pg-client ...
error: scripts doesn't exist in local filesystem
Pod: pg-client is healthy

[root@localhost scripts]# kubectl exec -it pg-client -n postgresql -- psql -U px-user -d predictx -a -q
psql: error: connection to server on socket "/tmp/.s.PGSQL.5432" failed: No such file or directory
        Is the server running locally and accepting connections on that socket?
command terminated with exit code 2
[root@localhost scripts]# kubectl exec -it pg-client -n postgresql
error: you must specify at least one command for the container
[root@localhost scripts]# kubectl exec -it pg-client -n postgresql -- /bin/bash
I have no name!@pg-client:/$ psql -U px-user -d predictx -a -q
psql: error: connection to server on socket "/tmp/.s.PGSQL.5432" failed: No such file or directory
        Is the server running locally and accepting connections on that socket?
I have no name!@pg-client:/$

Something is borked on pg-client see script/client-launch.sh...
```
I have no name!@pg-client:/$ psql -U px-user -d predictx -a -q
psql: error: connection to server on socket "/tmp/.s.PGSQL.5432" failed: No such file or directory
        Is the server running locally and accepting connections on that socket?
I have no name!@pg-client:/$
```

Inconsistency/Error with automation
```[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl exec -it postgresql-postgresql-ha-postgresql-0 -n postgresql -- psql -U postgres -d postgres -a -q -f /tmp/scripts/create-user.sql
Defaulted container "postgresql" out of: postgresql, metrics
CREATE DATABASE predictx;
psql:/tmp/scripts/create-user.sql:1: ERROR:  database "predictx" already exists
CREATE USER "px-user" WITH ENCRYPTED PASSWORD 'px-user';
psql:/tmp/scripts/create-user.sql:2: ERROR:  role "px-user" already exists
GRANT ALL PRIVILEGES ON DATABASE predictx TO "px-user";
[root@localhost kubernetes-autopilot-cluster-helm-postgresql-automation]# kubectl exec -it pg-client -n postgresql -- psql -U postgres -d postgres -a -q -f /tmp/scripts/create-user.sql
psql: error: connection to server on socket "/tmp/.s.PGSQL.5432" failed: No such file or directory
        Is the server running locally and accepting connections on that socket?
command terminated with exit code 2
```
I will come back to this hopefully and fix it.

