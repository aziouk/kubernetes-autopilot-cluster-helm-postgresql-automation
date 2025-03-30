# 🚀 Deploy PostgreSQL on GKE with Terraform 

## What this does
This provides terraform and helm automation templates for multi region, redundant, stateful Google Cloud GKE Cluster, for PostgreSQL using Helm Charts and Docker-Kubernetes as a deployment strategy.

This github repo collection uses the reference samples from google cloud. We have forked it at https://github.com/aziouk/kubernetes-engine-samples and that fork is a subrepo of this repo. The GoogleCloudPlatform samples repo can be found [here](https://github.com/GoogleCloudPlatform/kubernetes-engine-samples).  

Future versions of this repository will implement only kubernetes-engine-samples subrepo, and the gke-stateful-postgres folder in the root of this repository will disappear, and reappear at <mark>kubernetes-engine-samples/databases/gke-stateful-postgres</mark> instead. This will ensure changes will be more consistent and the subrepo can be used for global changes.

This resource consists of two components 1. Terraform Templates for **Google Kubernetes Engine (GKE) cluster** and 2. **Helm charts** Autoinstaller for bootstrapping Terraform Built GKE Cluster in the same namespace.  

# ⚡ Quick Start
Before using the Quick Start installers please view the prequisites and GSM Setup needed for the automation components to run securely. It is important to understand that automation expects <mark> Google Secrets Manager must be first initialized</mark> and without that being done installs of helm postgresql chart on the cluster will fail. If you have initialized GSM and installed the prequirements you can proceed immediately to the [install section](https://github.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation/tree/master?tab=readme-ov-file#install-method-1)

## Initaializing GSM for First time
<p align="left">
  <strong>⚠️ Warning:</strong> *MUST* be run at least once for helm installer to succeed. Helm Chart autoinstaller automation uses credentials from GSM to support deployment, without it builds will fail.
Replace <mark>px-user-password</mark>, <mark>px-user</mark> and <mark>px-database</mark> with desired credentials. This must be ran *before* the autoinstaller. 
</p>

```
gcloud secrets create DB_PASSWORD --replication-policy="automatic"
gcloud secrets create DB_USER --replication-policy="automatic"
gcloud secrets create DB_NAME --replication-policy="automatic"
echo -n "px-user-password" | gcloud secrets versions add DB_PASSWORD --data-file=-
echo -n "px-user" | gcloud secrets versions add DB_USER --data-file=-
echo -n "px-database" | gcloud secrets versions add DB_NAME --data-file=-

# Recommend to sanitize the plaintext password entry from BASH History something like
history -d $(history 4 | awk '{print $1}') && history -w

```
The above could be handled by the setenv install (please request this if needed), but it would involve automation scripts containing sensitive credentials in plaintext. It is much better not to use setenv, but it is trivial to add automation to set random variables at runtime instead if this is desired. For example if the deploy scripts are on a bastion which self destroys, then it would be potentially acceptable to include credentials in scripts, but best practice makes this seem less desirable approach. Perhaps if setenv had a pre-encrypted credential values added to it, then the credentials could be ported with the template, streamlined for special circumstances, but this is not recommended, as the cipher of the variable could be more unreliable than common, maintained secret stores like GSM. Also it creates a larger burden on maintenance of tooling associated with that. It is not recommended to manage this via a bucket with a helper terraform script for this reason and GSM is favored in this implementation.

The third "middle way approach" is to generate random username, password, and database credential variales at run-time and store them in GSM programatically, and then have the automation refer to the given gsm secret vars. At the end of the helm build calls can be made to reveal the DB_PASSWORD, DB_USER and DB_NAME in GSM used by Helm Chart upgrade installer. This change would require only trivial/arbitrary changes if it is desired instead of pre-assigned credentials, the generative approach would not expose any plaintext credentials, or take input credentials from anywhere, or require manual initialisation of GSM or keystore. For consistency the latter is probably most suitable in most prod and dev scenarios. 

# Checking if GSM Is already set

```
gcloud secrets versions access latest --secret=DB_USER
gcloud secrets versions access latest --secret=DB_PASSWORD
gcloud secrets versions access latest --secret=DB_NAME
```



# Install Method 1
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
<mark> Autoinstaller supports gke-standard cluster via terraform and helm chart postgresql. gke-autopilot not production ready yet. </mark>

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


For details refer to the Google Cloud reference [here](https://cloud.google.com/kubernetes-engine/docs/tutorials/stateful-workloads/postgresql#autopilot), which contains significant inaccuracies, typos, and unmaintained deprecations for example <mark>role/artifactregistry.Admin</mark> should be prefixed by <mark>roles/</mark> not role/. Some api names are wrong, like  <mark>artifactregistry.repoAdmin</mark> is used now and not artifactregistry.repo</mark> as of 28/03/2025. It seems that the Google Clouds SDK own documentation repository is floating unworkable example templates which are not maintained by anyone, or it is just not a big priority for them. Perhaps there are templates elsewhere that do not suffer from these issues and the maintainer forgot to deprecate the reference?

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


# Running Helm Automation

```bash
chmod +x helm_deploy_postgres.sh
./helm_deploy_postgres.sh
```
## Connecting to cluster-db instance

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

```bash
#input generated db for testing
psql -h $HOST_PGPOOL -U postgres -a -q -f /tmp/scripts/generate-db.sql
#test counting rows
psql -h $HOST_PGPOOL -U postgres -a -q -f /tmp/scripts/count-rows.sql
```
## Create Database, with credentials to named postgresdb
You can run the command <mark>psql -h $HOST_PGPOOL -U postgres -a -q -f /tmp/scripts/create-user.sql</mark> maually to update user names, passwords or perform other SQL command sets. GSM is preffered for Security reasons. 
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

# Confirm user added
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

# Adding Service Accounts
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

I fixed it. I wrote a new master-client for the 0th node postgresql-postgresql-ha-postgresql-0 to upload the necessary init db scripts. Theoretically client-connect pgclient script can be adapted to switch to any pod and upload the /tmp/scripts for workload/population on postgresql etc. I don't think this was a proper way of doing it, so we're using HELM automation for now, which works to carry out this portion of the credential and db set vars.


# Documenting a Strange GKE Kube-DNS Build Issue

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
```[root@localhost postgresql-bootstrap]# kubectl get pods -l k8s-app=kube-dns -n kube-system
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


```[root@localhost postgresql-bootstrap]# kubectl get pods -n kube-system
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
/ # host kubernetes
[root@localhost postgresql-bootstrap]# kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools
Error from server (AlreadyExists): pods "dnstools" already exists
```
Delete existing pods failing
[root@localhost postgresql-bootstrap]# kubectl delete pod dnstools
pod "dnstools" deleted

#Attempt to build from latest image a pod and test hostname resolution
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

```6m59s       Warning   FailedScheduling         pod/coredns-coredns-64fc886fd4-b6zdm                                 0/7 nodes are available: 1 Insufficient memory, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}, 3 node(s) had untolerated taint {app.stateful/component: postgresql}. preemption: 0/7 nodes are available: 1 No preemption victims found for incoming pod, 6 Preemption is not helpful for scheduling.
119s        Normal    NotTriggerScaleUp        pod/coredns-coredns-64fc886fd4-b6zdm                                 pod didn't trigger scale-up: 9 max cluster cpu, memory limit reached
66s         Warning   FailedScheduling         pod/coredns-coredns-64fc886fd4-b6zdm                                 0/7 nodes are available: 1 Insufficient memory, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}, 3 node(s) had untolerated taint {app.stateful/component: postgresql}. preemption: 0/7 nodes are available: 1 No preemption victims found for incoming pod, 6 Preemption is not helpful for scheduling.
7m          Normal    SuccessfulCreate         replicaset/coredns-coredns-64fc886fd4                                Created pod: coredns-coredns-64fc886fd4-b6zdm
7m          Normal    ScalingReplicaSet        deployment/coredns-coredns                                           Scaled up replica set coredns-coredns-64fc886fd4 from 0 to 1
12m         Warning   FailedScheduling         pod/event-exporter-gke-746c49d5b8-4mtbz                              0/7 nodes are available: 1 Insufficient memory, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}, 3 node(s) had untolerated taint {app.stateful/component: postgresql}. preemption: 0/7 nodes are available: 1 No preemption victims found for incoming pod, 6 Preemption is not helpful for scheduling.
12m         Normal    NotTriggerScaleUp        pod/event-exporter-gke-746c49d5b8-4mtbz                              pod didn't trigger scale-up: 9 max cluster cpu, memory limit reached
11m         Warning   FailedScheduling         pod/event-exporter-gke-746c49d5b8-4mtbz                              0/7 nodes are available: 1 Insufficient memory, 3 node(s) had untolerated taint {app.stateful/component: postgresql-pgpool}, 3 node(s) had untolerated taint {app.stateful/component: postgresql}. preemption: 0/7 nodes are available: 1 No preemption victims found for incoming pod, 6 Preemption is not helpful for scheduling.
```

It looks like the dns is causing taints in the whole build process because some memory quota limit is reached. Unfortunately the error message is so unhelpful it is dificult to conclude what 9 max cluster cpu refers to. I've checked in quotas and everything looks fine. so weird.

