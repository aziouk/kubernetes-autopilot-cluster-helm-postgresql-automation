# This is a test file and probably shouldn't be ran without good understanding
# There is no backup policy described and this is for demonstration purposes

# Export the Necessary Variables working for the Namespace DR Recovery.

# DANGER: REGION var is the FAILED statefulset region, and DR_REGION is the target-to-migrate-to, in this example cluster-db2


export SOURCE_CLUSTER=cluster-db1
export TARGET_CLUSTER=cluster-db2
export REGION=us-central1
export DR_REGION=us-west1
export NAME_PREFIX=g-db-protected-app
export BACKUP_PLAN_NAME=$NAME_PREFIX-bkp-plan-01
export BACKUP_NAME=bkp-$BACKUP_PLAN_NAME
export RESTORE_PLAN_NAME=$NAME_PREFIX-rest-plan-01
export RESTORE_NAME=rest-$RESTORE_PLAN_NAME


echo "=== WARNING IMPORTANT INFORMATION FOR BACKUP PLAN UNIT TESTING ==="
echo "Backing up data on $SOURCE_CLUSTER in $REGION, to be migrated to => $TARGET_CLUSTER in $DR_REGION , for the app $NAME_PREFIX."
echo "We are creating/using $BACKUP_PLAN_NAME for $BACKUP_NAME and the $RESTORE_PLAN_NAME for $RESTORE_NAME to DR Recovery into $TARGET_CLUSTER bebcause of a failure on $SOURCE_CLUSTER"
echo "This script delays executing for 60 seconds in the hope of saving lives and jobs..."
# Let the user see the message first before going crazy with it.
sleep 10

echo "Starting..."
# Ensure your in the SOURCE_CLUSTER credentials namespace (CRITICAL)
# (best practice)
echo "Trying to get Gcloud credentials for $SOURCE_CLUSTER Backup procedure..."
gcloud container clusters get-credentials $SOURCE_CLUSTER --region $REGION --project $PROJECT_ID

# DEBUG , important for PVC binding failures related to helm cluster group naming or different repo object name usage of stateful group
# basically, if this comes back with any unbound volumes before GKE runs backups should be aborted. #todo write processor for it

echo "DEBUG INFO: Getting pvc for $NAMESPACE"
kubectl get pvc -n $NAMESPACE
echo "END DEUG INFO"


# Verify Backup for GKE Enabled
echo "Verifying Backup enabled at GKE..."
gcloud container clusters describe $SOURCE_CLUSTER \
    --project=$PROJECT_ID  \
    --region=$REGION \
    --format='value(addonsConfig.gkeBackupAgentConfig)'

# Verify status of the protectedapplication
echo "Checking status of protectedapplication..."
kubectl get ProtectedApplication -A

# Create Backup Plan
echo "-------------- BEGIN CREATING BACKUP PLAN --------------"
echo "START EXPORTS"
export NAMESPACE=postgresql
export PROTECTED_APP=$(kubectl get ProtectedApplication -n $NAMESPACE | grep -v 'NAME' | awk '{ print $1 }')
echo "END EXPORTS"


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
echo "-------------- END CREATING BACKUP PLAN --------------"


# Manually create a backup
echo "Trying to manually create a backup for $BACKUP_NAME in $PROJECT_ID with a target $DR_REGION and Backup plan $BACKUP_PLAN_NAME"
echo "------BEGIN MANUAL BACKUP------"
gcloud beta container backup-restore backups create $BACKUP_NAME \
--project=$PROJECT_ID \
--location=$DR_REGION \
--backup-plan=$BACKUP_PLAN_NAME \
--wait-for-completion
echo "------END MANUAL BACKUP------"

# Set up Restore Plan
# This will restore to $DR_REGION and to $TARGET_CLUSTER 
# Unfortunately there is no reference to the $SOURCE_CLUSTER in API and I think that is sortof notgood.

# for example; someone might push wrong backup from wrong source-cluster because restore-plan-name contain no identifying information of wher eit came from
# maybe it is there somewhere hidden in the api meh idk. -adam

echo "--------------- BEGIN CREATING RESTORE PLAN ---------------"
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
echo "--------------- END CREATING RESTORE PLAN ---------------"


# Restore to 'cluster-db2 from Backup of cluster-db1
echo "--------------- BEGIN EXECUTING RESTORE FOR $BACKUP_NAME:$BACKUP_PLAN, RESTORE TARGET = $TARGET_CLUSTER, FAILED SOURCE was $SOURCE_CLUSTER ---------------"
gcloud beta container backup-restore restores create $RESTORE_NAME \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --restore-plan=$RESTORE_PLAN_NAME \
  --backup=projects/$PROJECT_ID/locations/$DR_REGION/backupPlans/$BACKUP_PLAN_NAME/backups/$BACKUP_NAME \
  --wait-for-completion
echo "--------------- END EXECUTING RESTORE FOR $BACKUP_NAME:$BACKUP_PLAN, RESTORE TARGET = $TARGET_CLUSTER, FAILED SOURCE was $SOURCE_CLUSTER ---------------"

echo "Unit tests complete..."

# Lets check the PVC After the GKE Backup has run, to see if it is GKE related process for any bind failures on the stateful group backend
echo "DEBUG INFO: Getting pvc for $NAMESPACE"
kubectl get pvc -n $NAMESPACE
echo "END DEUG INFO"


# Grace time
echo "Waiting 30 seconds before re-polling."
echo "INFO: The Source cluster was $SOURCE_CLUSTER which has been restored onto the Target Cluster $TARGET_CLUSTER using $BACKUP_PLAN_NAME and $RESTORE_PLAN_NAME. The Old region was $REGION and Disaster caused  need to migrate to the $TARGET_CLUSTER IN $DR_REGION. $TARGET_CLUSTER now has full restored data that the failed $SOURCE_CLUSTER had.. "
sleep 30

# Verification steps checking cluster restored

gcloud container clusters get-credentials $TARGET_CLUSTER --region $DR_REGION --project $PROJECT_ID


