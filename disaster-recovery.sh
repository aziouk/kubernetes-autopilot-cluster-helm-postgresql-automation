# This is a test file and probably shouldn't be ran without good understanding
# There is no backup policy described and this is for demonstration purposes

# Export the Necessary Variables working for the Namespace DR Recovery.

# DANGER: REGION var is the FAILED statefulset region, and DR_REGION is the target-to-migrate-to, in this example cluster-db2


echo "Warning this script is dangerous, dont run it unless you know what your doing, CTRL+C now if unsure"
echo "Waiting 10 seconds... grace time"
sleep 10

export SOURCE_CLUSTER=cluster-db1
export TARGET_CLUSTER=cluster-db2
export REGION=us-central1
export DR_REGION=us-west1
export NAME_PREFIX=g-db-protected-app
export BACKUP_PLAN_NAME=$NAME_PREFIX-bkp-plan-01
export BACKUP_NAME=bkp-$BACKUP_PLAN_NAME
export RESTORE_PLAN_NAME=$NAME_PREFIX-rest-plan-01
export RESTORE_NAME=rest-$RESTORE_PLAN_NAME


echo "=== IMPORTANT INFORMATION FOR BACKUP PLAN UNIT TESTING ==="
echo "Backing up data on $SOURCE_CLUSTER in $REGION, to be migrated to => $TARGET_CLUSTER in $DR_REGION , for the app $NAME_PREFIX."
echo "We are using $BACKUP_PLAN_NAME for $BACKUP_NAME and the $RESTORE_PLAN_NAME for $RESTORE_NAME to DR Recovery into $TARGET_CLUSTER bebcause of a failure on $SOURCE_CLUSTER"
# Let the user see the message first before going crazy with it.
sleep 60

# Ensure your in the SOURCE_CLUSTER credentials namespace (CRITICAL)
# (best practice)
echo "Trying to get Gcloud credentials for $SOURCE_CLUSTER Backup procedure..."
gcloud container clusters get-credentials $SOURCE_CLUSTER --region $REGION --project $PROJECT_ID


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
echo "--------------- EXECUTING RESTORE FOR $BACKUP_NAME:$BACKUP_PLAN, RESTORE TARGET = $TARGET_CLUSTER, FAILED SOURCE was $SOURCE_CLUSTER ---------------"
gcloud beta container backup-restore restores create $RESTORE_NAME \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --restore-plan=$RESTORE_PLAN_NAME \
  --backup=projects/$PROJECT_ID/locations/$DR_REGION/backupPlans/$BACKUP_PLAN_NAME/backups/$BACKUP_NAME \
  --wait-for-completion

# Grace time
echo "Waiting 30 seconds before polling the newly migrated data of Source Cluster $SOURCE_CLUSTER which has been restored onto the Target Cluster $TARGET_CLUSTER using $BACKUP_PLAN_NAME and $RESTORE_PLAN_NAME"
sleep 30

# Verification steps checking cluster restored

gcloud container clusters get-credentials $TARGET_CLUSTER --region $DR_REGION --project $PROJECT_ID


