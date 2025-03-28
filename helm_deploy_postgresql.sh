echo "BEGIN>> Automation for Helm postgresql chart for GKE Cluster Autopilot"


# set environment
chmod +x setenv.sh
./setenv.sh

# enter into automation root
cd gke-stateful-postgres 

# configure docker repo used for image pulls
gcloud auth configure-docker us-docker.pkg.dev

# pull compatible images recommended by google GKE Documentation
./scripts/gcr.sh bitnami/postgresql-repmgr 15.1.0-debian-11-r0
./scripts/gcr.sh bitnami/postgres-exporter 0.11.1-debian-11-r27
./scripts/gcr.sh bitnami/pgpool 4.3.3-debian-11-r28

# Verify the packages are stored in repo
gcloud artifacts docker images list us-docker.pkg.dev/$PROJECT_ID/main \
    --format="flattened(package)"

# Configure Credentials for kubectl cli access of primary cluster

gcloud container clusters get-credentials $SOURCE_CLUSTER \
--region=$REGION --project=$PROJECT_ID

export NAMESPACE=postgresql
kubectl create namespace $NAMESPACE

# increase replicas to 3set PodAntiAffinity with requiredDuringSchedulingIgnoredDuringExecution and topologykey:"topology.kubernetes.io/zone"
kubectl -n $NAMESPACE apply -f scripts/prepareforha.yaml


# update HELM dependencies
cd helm/postgresql-bootstrap
helm dependency update

# Display source of the Helm Chart being Installed 
echo "==== HELM CHART BEGINS HERE ====="
helm -n postgresql template postgresql . \
  --set global.imageRegistry="us-docker.pkg.dev/$PROJECT_ID/main"
echo "==== HELM CHART ENDS HERE ====="

# Install Chart

helm -n postgresql upgrade --install postgresql . \
    	--set global.imageRegistry="us-docker.pkg.dev/$PROJECT_ID/main"

#Output looks like
NAMESPACE: postgresql
STATUS: deployed
REVISION: 1
TEST SUITE: None
###

# Verify that the PostgreSQL Replicas are Running
kubectl get all -n $NAMESPACE

echo "<<END Automation for Helm postgresql chart for GKE Cluster Autopilot."
