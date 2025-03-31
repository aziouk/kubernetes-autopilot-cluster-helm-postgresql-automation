# Author: A. Bull 30/03/2025 - with some help from ma and the computer
# Description:
# It's a script that locks down GSM permissions to the build user that uses it only exclusively.
# Requires Argument SECRET_NAME and optionally SERVICE_ACCOUNT PROJECT_ID, ,see below
# The goal is to create an audit helper function for locking down GSM accounts, that could be potentially
# implemented as a Terraform or Helm Chart later. Theoretically could form part of a security component
# that would be designed to detect intrusions into the IAM scope perimeter.

# Hey - there is probably lots better ways to do this

#!/bin/bash

# Check if a secret name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <SECRET_NAME> [SERVICE_ACCOUNT] [PROJECT_ID] [--]"
    exit 1
fi

SECRET_NAME=$1
SERVICE_ACCOUNT=$2
PROJECT_ID=${3:-$(gcloud config get-value project 2>/dev/null)}
AUTO_APPLY=$4

if [ -z "$PROJECT_ID" ]; then
    echo "No project ID provided and no default project set in gcloud. Exiting."
    exit 1
fi

# Fetch current IAM policy
echo "Fetching IAM policy for secret: $SECRET_NAME in project: $PROJECT_ID..."
POLICY_JSON=$(gcloud secrets get-iam-policy "$SECRET_NAME" --project="$PROJECT_ID" --format=json)

if [ -z "$POLICY_JSON" ]; then
    echo "Error retrieving IAM policy. Ensure the secret exists and you have permissions."
    exit 1
fi

# Extract current members with access
echo "\nCurrent users with access to $SECRET_NAME:"
if echo "$POLICY_JSON" | jq -e '.bindings | length > 0' >/dev/null 2>&1; then
    echo "$POLICY_JSON" | jq -r '.bindings[] | "Role: " + .role + "\nUsers: " + (.members | join(", ")) + "\n"'
else
    echo "No explicit bindings found (may be inherited)."
fi

# If service account is not provided, prompt for it
if [ -z "$SERVICE_ACCOUNT" ]; then
    read -p "\nEnter the service account to have exclusive access (e.g., service-account@project.iam.gserviceaccount.com): " SERVICE_ACCOUNT

    if [ -z "$SERVICE_ACCOUNT" ]; then
        echo "No service account provided. Exiting."
        exit 1
    fi
fi

# Create new policy JSON to grant exclusive access
NEW_POLICY_JSON=$(jq -n --arg sa "user:$SERVICE_ACCOUNT" '{
    "bindings": [
        {
            "role": "roles/secretmanager.secretAccessor",
            "members": [$sa]
        }
    ]
}')

# Display the new policy
echo "\nGenerated policy.json for exclusive access:"  
echo "$NEW_POLICY_JSON" | jq '.'

# Check if auto-apply is enabled
if [ "$AUTO_APPLY" == "--" ]; then
    echo "$NEW_POLICY_JSON" > policy.json
    gcloud secrets set-iam-policy "$SECRET_NAME" policy.json --project="$PROJECT_ID"
    echo "\nPolicy applied successfully!"
    rm policy.json
    exit 0
fi

# Confirm before applying
read -p "\nWould you like to apply this policy to $SECRET_NAME? (yes/no): " CONFIRM

if [ "$CONFIRM" == "yes" ]; then
    echo "$NEW_POLICY_JSON" > policy.json
    gcloud secrets set-iam-policy "$SECRET_NAME" policy.json --project="$PROJECT_ID"
    echo "\nPolicy applied successfully!"
    rm policy.json
else
    echo "\nPolicy not applied. Exiting."
fi
# todo
## once specific bindings are created for service_account any global ones should be checked and removed.
