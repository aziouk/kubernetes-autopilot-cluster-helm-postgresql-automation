# this script is a placeholder for something that could be a bit better soon

#for sanity really in case other scripts change
rootpath=$(pwd)

echo "Installing to $rootpath/kubernetes-autopilot-cluster-helm-postgresql-automation..."
git clone https://github.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation
cd kubernetes-autopilot-cluster-helm-postgresql-automation

#chmod +x setenv.sh
echo "Sourcing environment variabbles for project_id..."
. setenv.sh


cd gke-stateful-postgres
echo "Starting terraform initailization..."
terraform -chdir=terraform/gke-standard init -var project_id=predictx-postgrescluster
#not really needed for automation or regular use, maybe a flag for the autoinstaller like --type [plan/apply] 
#echo "Starting teraform plan..."
#terraform -chdir=terraform/gke-standard plan -var project_id=predictx-postgrescluster

echo "Starting Terraform apply..."
#comment this line when doing unsupervised installations
terraform -chdir=terraform/gke-standard apply -var project_id=predictx-postgrescluster
#uncoment this line to auto-approve template (WARNING: DANGER) for unsupervised installations
terraform -chdir=terraform/gke-standard apply -var project_id=predictx-postgrescluster --auto-approve

#

echo "Initializing Helm Deploy Script"
cd ../
chmod +x helm_deploy_postgres.sh
./helm_deploy_postgres.sh

echo "Deprecated: Optional db automation tasks [this is not for prod]"
echo "Info: this is deprecated, in place of GSM and Helm Chart vars, but script could be useful for populating data and running other tests etc"
cd $rootpath
echo "performing remaining db tasks via automation script"
chmod +x execute-database-tasks.sh
./execute-database-tasks.sh
