#/bin/bash
# this script is a placeholder for something that could be a bit better soon

# We really need to add some vars here that the user could provide, or make the script exit if the user has not edited the gsm secrets in helm_deploy_postgresql.sh
# Not sure the best way to do this, but it is discsued in detail in the README docs, that, the best way would be for helm to autogenerate the password and dbname.

#for sanity really in case other scripts change
rootpath=$(pwd)

# Ensure that pre-requirements are installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud command not found. Please install the required dependencies first described in prequirements.txt."
    echo "Note: This script does not install gcloud automatically, as using package managers like brew can modify your environment in unintended ways."
    curl https://raw.githubusercontent.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation/refs/heads/master/requirements.txt 
    exit 1
fi


# Ensuring those who manually git clone dont end up with an extra dir.
# Target directory name
target_dir="kubernetes-autopilot-cluster-helm-postgresql-automation"

# Check if PWD ends with target directory name and run commands if true
if [[ "$(pwd)" == *"/$target_dir" ]]; then
    echo "In $target_dir, so no need to git clone the repo..."

else
        echo "Not in $target_dir, so assuming quick install being run without project..."
	echo "Installing to $rootpath/kubernetes-autopilot-cluster-helm-postgresql-automation..."
	git clone https://github.com/aziouk/kubernetes-autopilot-cluster-helm-postgresql-automation
	cd kubernetes-autopilot-cluster-helm-postgresql-automation
fi



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


# Quick Uninstall 

# Run the command if an argument is provided
if [[ "$1" == "uninstall" ]]; then

 read -p "Are you sure you want to proceed with uninstallation? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "Running uninstall ..."
	helm uninstall postgresql
        terraform -chdir=terraform/gke-standard destroy -var project_id=predictx-postgrescluster

    else
        echo "Uninstallation cancelled."
        exit 1
    fi
fi


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


