#!/bin/bash

# Fetch the necessary data using AWS CLI

# Get the AWS SSO instance details
instanceArn=$(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text)
identityStoreId=$(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text)

# Get the groups, accounts, and permission sets
groups=$(aws identitystore list-groups --identity-store-id $identityStoreId --query 'Groups[].GroupId' --output text)
accounts=$(aws organizations list-accounts --query 'Accounts[?Status==`ACTIVE`].Id' --output text)
permissionSets=$(aws sso-admin list-permission-sets --instance-arn $instanceArn --query 'PermissionSets' --output text)



# Start the Terraform locals block
echo 'locals {' > account_assignments.tf
echo '  account_assignments = {' >> account_assignments.tf
echo '    "GROUP" = {' >> account_assignments.tf

# Define an array to store import data
declare -a imports

# Loop through groups and generate the assignments
for group in $groups; do
    groupName=$(aws identitystore describe-group --identity-store-id $identityStoreId --group-id $group --query 'DisplayName' --output text)
    groupName=$(echo $groupName | sed 's/ /_/g')
    group_name_inserted=0
    for account in $accounts; do
        account_name=$(aws organizations describe-account --account-id $account --query 'Account.Name' --output text)
        account_name_inserted=0
        for permissionSet in $permissionSets; do
            permissionSetAssignments=$(aws sso-admin list-account-assignments --account-id $account --instance-arn $instanceArn --permission-set-arn $permissionSet --query "AccountAssignments[?PrincipalId==\`$group\`].PermissionSetArn" --output text)
            if [ -z "$permissionSetAssignments" ]; then
                continue
            fi
            if [ $group_name_inserted -eq 0 ]; then
                echo "      (aws_identitystore_group.$groupName.group_id) = {" >> account_assignments.tf
                group_name_inserted=1
            fi
            if [ $account_name_inserted -eq 0 ]; then
                echo "        \"$account_name\" = [" >> account_assignments.tf
                account_name_inserted=1
            fi
            for permissionSetAssignment in $permissionSetAssignments; do
                permissionSetName=$(aws sso-admin describe-permission-set --instance-arn $instanceArn --permission-set-arn $permissionSetAssignment --query 'PermissionSet.Name' --output text)
                echo "          aws_ssoadmin_permission_set.$permissionSetName.arn," >> account_assignments.tf
                
                # Add the import data to the array
                imports+=("$group,GROUP,$account,AWS_ACCOUNT,$permissionSet,$instanceArn")
            done
        done
        if [ $account_name_inserted -eq 1 ]; then
            echo "        ]," >> account_assignments.tf
        fi
    done
    if [ $group_name_inserted -eq 1 ]; then
        echo "      }," >> account_assignments.tf
    fi
done

# Close the Terraform locals block
echo '    }' >> account_assignments.tf
echo '  }' >> account_assignments.tf
echo '}' >> account_assignments.tf

# Generate the import blocks using the data stored in the array
echo "# Import commands" > account_assignments_import.tf
for importData in "${imports[@]}"; do
    # Extract the individual components from the importData
    IFS=',' read -ra ADDR <<< "$importData"
    principal_type=${ADDR[1]}
    principal=${ADDR[0]}
    account_name=${ADDR[2]}
    permission_set=${ADDR[4]}

    # Construct the key for the "to" value in the import block
    to_key="${principal_type}___${principal}___${account_name}___${permission_set}"

    echo "import {" >> account_assignments_import.tf
    echo "  to = aws_ssoadmin_account_assignment.controller[\"$to_key\"]" >> account_assignments_import.tf
    echo "  id = \"$importData\"" >> account_assignments_import.tf
    echo "}" >> account_assignments_import.tf
    echo "" >> account_assignments_import.tf
done

echo "Terraform locals block written to account_assignments.tf"
echo "Import commands written to account_assignments_import.tf"
