# List all backup plans
echo "Listing all backup plans..."
BACKUP_PLANS=$(gcloud beta container backup-restore backup-plans list \
  --project=$PROJECT_ID \
  --location=$DR_REGION \
  --format="value(name)")

# Loop through each backup plan and delete its backups
for BACKUP_PLAN in $BACKUP_PLANS; do
  echo "Deleting backups for backup plan: $BACKUP_PLAN"
  
  # List all backups for the current backup plan
  BACKUPS=$(gcloud beta container backup-restore backups list \
    --project=$PROJECT_ID \
    --location=$DR_REGION \
    --backup-plan=$BACKUP_PLAN \
    --format="value(name)")

  # Loop through each backup and delete it
  for BACKUP in $BACKUPS; do
    echo "Deleting backup: $BACKUP"
    gcloud beta container backup-restore backups delete $BACKUP \
      --project=$PROJECT_ID \
      --location=$DR_REGION \
      --backup-plan=$BACKUP_PLAN --quiet
  done

  # Now, delete the backup plan itself
  echo "Deleting backup plan: $BACKUP_PLAN"
  gcloud beta container backup-restore backup-plans delete $BACKUP_PLAN \
    --project=$PROJECT_ID \
    --location=$DR_REGION --quiet
done

echo "All backups and backup plans have been deleted successfully."
