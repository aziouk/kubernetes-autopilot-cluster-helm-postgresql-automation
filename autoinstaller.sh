# this script is a placeholder for something that could be a bit better soon


git clone https://github.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation
cd kubernetes-autopilot-cluster-helm-postgresql-automation
chmod +x setenv.sh
./setenv.sh


cd gke-stateful-postgres
echo "Starting terraform initailization..."
terraform -chdir=terraform/gke-standard init -var project_id=predictx-postgrescluster
echo "Starting teraform plan..."
terraform -chdir=terraform/gke-standard plan -var project_id=predictx-postgrescluster
echo "Starting Terraform apply..."
terraform -chdir=terraform/gke-standard apply -var project_id=predictx-postgrescluster


cd ../
chmod +x helm_deploy_postgres.sh
./helm_deploy_postgres.sh
