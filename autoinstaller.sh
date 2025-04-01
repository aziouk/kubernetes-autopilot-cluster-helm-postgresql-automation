# this script is a placeholder for something that could be a bit better soon

#for sanity really in case other scripts change
rootpath=$(pwd)

#echo "Installing to $rootpath/kubernetes-autopilot-cluster-helm-postgresql-automation..."
#git clone https://github.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation
#cd kubernetes-autopilot-cluster-helm-postgresql-automation

#chmod +x setenv.sh
echo "Sourcing environment variabbles for project_id..."
. setenv.sh


cd gke-stateful-postgres
echo "Starting terraform initailization..."
terraform -chdir=terraform/gke-standard init -var project_id=predictx-postgrescluster

echo "Starting Terraform apply..."
terraform -chdir=terraform/gke-standard apply -var project_id=predictx-postgrescluster
# --auto-approve disabled to prevent nasty disasters for people running the script simply readd --auto-approve to the end of the above line if you wish this danger

#

echo "Initializing Helm Deploy Script"
cd ../
chmod +x helm_deploy_postgresql.sh
./helm_deploy_postgresql.sh

# DEPRECATED SECTION - Handled by Helm and GSM now but handy to have
#
#echo "Info: this is deprecated, in place of GSM and Helm Chart vars, but script could be useful for populating data and running other tests etc"
#cd $rootpath
#echo "performing remaining db tasks via automation script"
#chmod +x execute-database-tasks.sh
#./execute-database-tasks.sh

#todo: add tertiary user add script/teraform
#todo: add bastion vm creation and credentials dropper, for connecting easily to exposed nodeport/lbip/publicipv4 exposed cluster gw
#todo: terraform -chdir=terraform/gke-standard destroy -var project_id=predictx-postgrescluster [can be an argument for this script] like arg1=uninstall
#todo: resize cluster scripts
#todo: migration scripts, monitoring install scripts etc


