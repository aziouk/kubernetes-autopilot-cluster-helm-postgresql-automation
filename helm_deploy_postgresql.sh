echo "BEGIN>> Automation for Helm postgresql chart for GKE Cluster Autopilot"


# set environment
#chmod +x setenv.sh
. setenv.sh

# enter into automation root
cd gke-stateful-postgres 

# configure docker repo used for image pulls
gcloud auth configure-docker us-docker.pkg.dev

# pull compatible images recommended by google GKE Documentation
# google cloud vendor docs are wrong, and multiple versions outdated, what a shocker
#./scripts/gcr.sh bitnami/postgresql-repmgr 15.1.0-debian-11-r0
#./scripts/gcr.sh bitnami/postgres-exporter 0.11.1-debian-11-r27
#./scripts/gcr.sh bitnami/pgpool 4.3.3-debian-11-r28

# these often need to be changed for builds to succeed
./scripts/gcr.sh bitnami/postgresql-repmgr 16.6.0-debian-12-r3
./scripts/gcr.sh bitnami/postgres-exporter 0.17.1-debian-12-r2
./scripts/gcr.sh bitnami/pgpool 4.6.0-debian-12-r2


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

# may need to be run before scripts/gcr is run in some circumstances
helm dependency update

# Display source of the Helm Chart being Installed 
echo "==== HELM CHART BEGINS HERE ====="
helm -n postgresql template postgresql . \
  --set global.imageRegistry="us-docker.pkg.dev/$PROJECT_ID/main"
echo "==== HELM CHART ENDS HERE ====="

# Install Chart Insecure Without Adding User

#helm -n postgresql upgrade --install postgresql . \
#    	--set global.imageRegistry="us-docker.pkg.dev/$PROJECT_ID/main"

# Alternative 1 SECURING HELM DBMS Installation Procedure using Google Secret Store
# for this below section to work the gcloud secret must be predefined. Set it like so in gcloud;
# gcloud secrets create DB_PASSWORD --replication-policy="automatic"
# gcloud secrets create DB_USER --replication-policy="automatic"
# gcloud secrets create DB_NAME --replication-policy="automatic"
# echo -n "px-user-password" | gcloud secrets versions add DB_PASSWORD --data-file=-
# echo -n "px-user" | gcloud secrets versions add DB_USER --data-file=-
# echo -n "predictx" | gcloud secrets version DB_NAME --data-file=-

#helm upgrade --install postgresql ./helm-chart \
#  --set db_user=$(gcloud secrets versions access latest --secret=DB_USER) \
#  --set db_password=$(gcloud secrets versions access latest --secret=DB_PASSWORD)
#  --set db_database=$(gcloud secrets versions access latest --secret=DB_DATABASE)


#Corrections for Bitnami Helm Chart Installation with GSM secret store variables
echo "==== HELM CHART NAMESPACE INSTALL BEGINS HERE ====="
helm upgrade --install postgresql ./helm-chart \
  --set auth.username=$(gcloud secrets versions access latest --secret=DB_USER) \
  --set auth.password=$(gcloud secrets versions access latest --secret=DB_PASSWORD) \
  --set auth.database=$(gcloud secrets versions access latest --secret=DB_NAME)
echo "==== HELM CHART NAMESPACE INSTALL ENDS HERE ====="


#Output looks like
#NAMESPACE: postgresql
#STATUS: deployed
#REVISION: 1
#TEST SUITE: None
###

# Verify that the PostgreSQL Replicas are Running
kubectl get all -n $NAMESPACE

echo "<<END Automation for Helm postgresql chart for GKE Cluster Autopilot."
