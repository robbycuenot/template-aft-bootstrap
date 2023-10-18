#!/bin/bash

# -----------------------------------------------------------------------------
# Script Name: identitystore_processor.sh
# Description: This script processes users and groups from AWS Identity Store.
# Usage: ./identitystore_processor.sh
# -----------------------------------------------------------------------------



# Global Variables/Constants
# -----------------------------------------------------------------------------
# Fetch the necessary data using AWS CLI
identityStoreId=$(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text)

# Dictionary of output files
declare -A files=(
    ["instances"]="aws_ssoadmin_instances.tf"
    ["groups"]="aws_identitystore_groups.tf"
    ["groups_map"]="aws_identitystore_groups_map.tf"
    ["groups_import"]="aws_identitystore_groups_import.tf"
    ["group_memberships"]="aws_identitystore_group_memberships.tf"
    ["group_memberships_map"]="aws_identitystore_group_memberships_map.tf"
    ["group_memberships_map_scim"]="aws_identitystore_group_memberships_map_scim.tf"
    ["group_memberships_flattened"]="aws_identitystore_group_memberships_flattened.tf"
    ["group_memberships_import"]="aws_identitystore_group_memberships_import.tf"
    ["users"]="aws_identitystore_users.tf"
    ["users_map"]="aws_identitystore_users_map.tf"
    ["users_import"]="aws_identitystore_users_import.tf"
)
# -----------------------------------------------------------------------------



# Utility Functions
# -----------------------------------------------------------------------------
# Check if AWS credentials are valid
check_aws_credentials() {
    # Try to get the caller identity using AWS STS
    aws sts get-caller-identity > /dev/null 2>&1

    # Check the exit status of the last command
    if [ $? -ne 0 ]; then
        echo "Error: AWS credentials are not valid or you do not have permission to check your identity."
        exit 1
    fi
}

# Sanitize a string for a Terraform resource ID
sanitize_for_terraform() {
    local original_name="$1"
    
    # Ensure the name starts with a letter or underscore
    local sanitized_name=$(echo "$original_name" | sed 's/^[^a-zA-Z_]/_/')
    
    # Replace invalid characters with underscores
    sanitized_name=$(echo "$sanitized_name" | sed 's/[^a-zA-Z0-9_-]/_/g')
    
    # Compute a short hash of the original name (first 5 characters of SHA-1 hash)
    # Disabling this for now, as collisions are unlikely and names should be unique in AWS
    # local hash=$(echo -n "$original_name" | sha1sum | cut -c 1-5)
    
    # Append the hash to the sanitized name
    # echo "${sanitized_name}_$hash"

    echo "$sanitized_name"
}
# -----------------------------------------------------------------------------



# File Initializing / Closing Functions
# -----------------------------------------------------------------------------
# Function to write the header to a file
write_header() {
    local file="$1"
    echo "# Generated Terraform file for AWS IAM Identity Center" > "$file"
}

# Function to write content to a file
write_content() {
    local file="$1"
    shift
    local content="$@"
    cat >> "$file" <<- EOM
$content
EOM
}

# Write initial content for all files
write_initial_content() {
    # Write headers to all files
    for file in "${files[@]}"; do
        write_header "$file"
    done

    write_content "${files[instances]}" 'data "aws_ssoadmin_instances" "instances" {}

locals {
    sso_instance_id = tolist(data.aws_ssoadmin_instances.instances.identity_store_ids)[0]
}'

    write_content "${files[groups_map]}" 'locals {
  groups_map = {'

    write_content "${files[group_memberships_map]}" 'locals {
  group_memberships_map = {'

    write_content "${files[group_memberships_map_scim]}" 'locals {
  group_memberships_map_scim = {'

    write_content "${files[users_map]}" 'locals {
  users_map = {'

    write_content "${files[group_memberships]}" 'resource "aws_identitystore_group_membership" "controller" {
  for_each = { for membership in local.group_memberships_flattened : "${membership.group}___${membership.user}" => membership }

  group_id = local.groups_map[each.value.group]
  member_id  = local.users_map[each.value.user]

  identity_store_id = local.sso_instance_id
}'

    write_content "${files[group_memberships_flattened]}" 'locals {
  group_memberships_flattened = flatten([
    for group, users in local.group_memberships_map : [
      for user in users : {
        "group" = group,
        "user"  = user
      }
    ]
  ])
}'
}

# Write closing content for specific files
write_closing_content() {
    # Finish the Terraform user map file
    write_content "${files[users_map]}" '
  }
}'

    # Finish the Terraform group map file
    write_content "${files[groups_map]}" '
  }
}'

    # Finish the Terraform group memberships map file
    write_content "${files[group_memberships_map]}" '
  }
}'

    # Finish the Terraform group memberships map scim file
    write_content "${files[group_memberships_map_scim]}" '
  }
}'
}
# -----------------------------------------------------------------------------



# Helper Functions
# -----------------------------------------------------------------------------
# Fetch all users from AWS Identity Store in a paginated manner
fetch_all_users() {
    local identityStoreId="$1"
    local userNextToken=""
    local userResponses=""

    while true; do
        local userResponseArgs=("--identity-store-id" "$identityStoreId" "--output" "json")
        [ -n "$userNextToken" ] && userResponseArgs+=("--next-token" "$userNextToken")
        
        local userResponse=$(aws identitystore list-users "${userResponseArgs[@]}")
        userResponses+=$(echo "$userResponse" | jq -r '.Users[]')
        
        userNextToken=$(echo "$userResponse" | jq -r '.NextToken')
        [ "$userNextToken" == "null" ] && break
    done

    echo "$userResponses"
}

# Fetch all groups from AWS Identity Store in a paginated manner
fetch_all_groups() {
    local identityStoreId="$1"
    local groupNextToken=""
    local groupResponses=""

    while true; do
        local groupResponseArgs=("--identity-store-id" "$identityStoreId" "--output" "json")
        [ -n "$groupNextToken" ] && groupResponseArgs+=("--next-token" "$groupNextToken")
        
        local groupResponse=$(aws identitystore list-groups "${groupResponseArgs[@]}")
        groupResponses+=$(echo "$groupResponse" | jq -r '.Groups[]')
        
        groupNextToken=$(echo "$groupResponse" | jq -r '.NextToken')
        [ "$groupNextToken" == "null" ] && break
    done

    echo "$groupResponses"
}

# Process a list of users
process_users_list() {
    local usersList="$1"

    local sortedUsers=$(echo "$usersList" | jq -s -c 'sort_by(.UserName)[]')
    jq -r '@base64' <<< "$sortedUsers" | while read -r user_encoded; do
        local user_decoded=$(echo "$user_encoded" | base64 --decode)
        process_user "$user_decoded"
    done
}

# Process a list of groups
process_groups_list() {
    local groupsList="$1"

    local sortedGroups=$(echo "$groupsList" | jq -s -c 'sort_by(.DisplayName)[]')
    jq -r '@base64' <<< "$sortedGroups" | while read -r group_encoded; do
        local group_decoded=$(echo "$group_encoded" | base64 --decode)
        process_group "$group_decoded"
    done
}
# -----------------------------------------------------------------------------



# Core Functions
# -----------------------------------------------------------------------------
# Process a user
process_user() {
    user_json="$1"

    userId=$(jq -r '.UserId' <<< "$user_json")
    userName=$(jq -r '.UserName' <<< "$user_json")
    userDisplayName=$(jq -r '.DisplayName' <<< "$user_json")
    userGivenName=$(jq -r '.Name.GivenName' <<< "$user_json")
    userFamilyName=$(jq -r '.Name.FamilyName' <<< "$user_json")

    isSCIM=$(echo "$user_json" | jq 'has("ExternalIds")')

    # Sanitize the group name for Terraform block ID
    sanitizedUserName=$(sanitize_for_terraform "$userName")
    if $isSCIM; then
        # Generate a data block for SCIM managed users
        printf '%s\n' \
        "data \"aws_identitystore_user\" \"$sanitizedUserName\" {" \
        "  identity_store_id = local.sso_instance_id" \
        "  alternate_identifier {" \
        "    unique_attribute {" \
        "      attribute_path  = \"UserName\"" \
        "      attribute_value = \"$userName\"" \
        "    }" \
        "  }" \
        "}" \
        "" >> ${files[users]}

        # Generate a mapping for SCIM managed users
        printf '%s\n' \
        "    \"$sanitizedUserName\" = data.aws_identitystore_user.$sanitizedUserName.user_id" >> ${files[users_map]}
    else
        # Generate a resource block for non-SCIM managed users
        declare -A userAttributes=(
            ["formatted"]=$(jq -r '.Name.Formatted' <<< "$user_json")
            ["honorific_prefix"]=$(jq -r '.Name.HonorificPrefix' <<< "$user_json")
            ["honorific_suffix"]=$(jq -r '.Name.HonorificSuffix' <<< "$user_json")
            ["middle_name"]=$(jq -r '.Name.MiddleName' <<< "$user_json")
            ["locale"]=$(jq -r '.Locale' <<< "$user_json")
            ["nick_name"]=$(jq -r '.NickName' <<< "$user_json")
            ["preferred_language"]=$(jq -r '.PreferredLanguage' <<< "$user_json")
            ["profile_url"]=$(jq -r '.ProfileUrl' <<< "$user_json")
            ["timezone"]=$(jq -r '.Timezone' <<< "$user_json")
            ["title"]=$(jq -r '.Title' <<< "$user_json")
            ["type"]=$(jq -r '.UserType' <<< "$user_json")
        )

        declare -A userEmailAttributes=(
            ["value"]=$(jq -r '.Emails[0].Value' <<< "$user_json")
            ["primary"]=$(jq -r '.Emails[0].Primary' <<< "$user_json")
            ["type"]=$(jq -r '.Emails[0].Type' <<< "$user_json")
        )

        declare -A userAddressAttributes=(
            ["value"]=$(jq -r '.Addresses[0].StreetAddress' <<< "$user_json")
            ["country"]=$(jq -r '.Addresses[0].Country' <<< "$user_json")
            ["formatted"]=$(jq -r '.Addresses[0].Formatted' <<< "$user_json")
            ["locality"]=$(jq -r '.Addresses[0].Locality' <<< "$user_json")
            ["postal_code"]=$(jq -r '.Addresses[0].PostalCode' <<< "$user_json")
            ["primary"]=$(jq -r '.Addresses[0].Primary' <<< "$user_json")
            ["region"]=$(jq -r '.Addresses[0].Region' <<< "$user_json")
            ["street_address"]=$(jq -r '.Addresses[0].StreetAddress' <<< "$user_json")
            ["type"]=$(jq -r '.Addresses[0].Type' <<< "$user_json")
        )

        declare -A userPhoneAttributes=(
            ["value"]=$(jq -r '.PhoneNumbers[0].Value' <<< "$user_json")
            ["primary"]=$(jq -r '.PhoneNumbers[0].Primary' <<< "$user_json")
            ["type"]=$(jq -r '.PhoneNumbers[0].Type' <<< "$user_json")
        )

        printf '%s\n' \
        "resource \"aws_identitystore_user\" \"$sanitizedUserName\" {" \
        "  user_name         = \"$userName\"" \
        "  display_name      = \"$userDisplayName\"" \
        "  identity_store_id = local.sso_instance_id" \
        "  name {" \
        "    given_name  = \"$userGivenName\"" \
        "    family_name = \"$userFamilyName\"" \
        "  }" >> ${files[users]}

        # Print user attributes
        for attribute in "${!userAttributes[@]}"; do
            value=${userAttributes[$attribute]}
            if [[ $value != "null" ]]; then
                echo "  $attribute = \"$value\"" >> ${files[users]}
            fi
        done

        # Helper function to print block attributes
        print_block_attributes() {
            local blockName=$1
            declare -n attributes=$2

            if [[ ${attributes["value"]} != "null" ]]; then
                echo "  $blockName {" >> ${files[users]}
                for attribute in "${!attributes[@]}"; do
                    value=${attributes[$attribute]}
                    if [[ $value != "null" ]]; then
                        echo "    $attribute = \"$value\"" >> ${files[users]}
                    fi
                done
                echo "  }" >> ${files[users]}
            fi
        }

        print_block_attributes "emails" userEmailAttributes
        print_block_attributes "addresses" userAddressAttributes
        print_block_attributes "phone_numbers" userPhoneAttributes

        printf '%s\n' \
        "}" \
        "" >> ${files[users]}

        # Generate a mapping for non-SCIM managed users
        printf '%s\n' \
        "    \"$sanitizedUserName\" = aws_identitystore_user.$sanitizedUserName.user_id" >> ${files[users_map]}

        # Generate an import line for non-SCIM managed users
        printf '%s\n' \
        "import {" \
        "  to = aws_identitystore_user.$sanitizedUserName" \
        "  id = \"$identityStoreId/$userId\"" \
        "}" \
        "" \
        >> ${files[users_import]}
    fi
}

# Fetch and process all users
fetch_and_process_users() {
    local identityStoreId="$1"
    local allUsers=$(fetch_all_users "$identityStoreId")
    process_users_list "$allUsers"
}

# Process a group
process_group() {
    group_json="$1"
    
    groupId=$(echo "$group_json" | jq -r '.GroupId')
    groupDisplayName=$(echo "$group_json" | jq -r '.DisplayName')
    groupDescription=$(echo "$group_json" | jq -r '.Description')

    isSCIM=$(echo "$group_json" | jq 'has("ExternalIds")')

    # Sanitize the group name for Terraform block ID
    sanitizedGroupDisplayName=$(sanitize_for_terraform "$groupDisplayName")
    
    if $isSCIM; then
        # For SCIM managed groups

        # Generate a data block
        printf '%s\n' \
        "data \"aws_identitystore_group\" \"$sanitizedGroupDisplayName\" {" \
        "  identity_store_id = local.sso_instance_id" \
        "  alternate_identifier {" \
        "    unique_attribute {" \
        "      attribute_path  = \"DisplayName\"" \
        "      attribute_value = \"$groupDisplayName\"" \
        "    }" \
        "  }" \
        "}" \
        "" >> ${files[groups]}

        # Generate a mapping
        echo "    \"$sanitizedGroupDisplayName\" = data.aws_identitystore_group.$sanitizedGroupDisplayName.group_id" >> ${files[groups_map]}

    else
        # For non-SCIM managed groups

        # Generate a resource block
        printf '%s\n' \
        "resource \"aws_identitystore_group\" \"$sanitizedGroupDisplayName\" {" \
        "  display_name      = \"$groupDisplayName\"" >> ${files[groups]}

        # Add description if it's not null
        [ "$groupDescription" != "null" ] && printf '  description       = "%s"\n' "$groupDescription" >> ${files[groups]}

        printf '%s\n' \
        "  identity_store_id = local.sso_instance_id" \
        "}" \
        "" >> ${files[groups]}

        # Generate a mapping
        echo "    \"$sanitizedGroupDisplayName\" = aws_identitystore_group.$sanitizedGroupDisplayName.group_id" >> ${files[groups_map]}

        # Generate an import block
        printf '%s\n' \
        "import {" \
        "  to = aws_identitystore_group.$sanitizedGroupDisplayName" \
        "  id = \"$identityStoreId/$groupId\"" \
        "}" \
        "" >> ${files[groups_import]}
    fi


    # Gather group membership information
    
    # Define a string to store all responses
    declare -a memberships
    membershipUsers=""
    
    # This loop fetches group memberships from the AWS Identity Store in a paginated manner.
    # For each page of results, it extracts individual group memberships and appends them to the memberships array.

    # Initialize the token for pagination.
    membershipNextToken=""

    while true; do
        # If there's a next token, include it in the request arguments.
        nextTokenArg=${membershipNextToken:+--next-token "$membershipNextToken"}

        # Fetch the list of group memberships for the given group ID.
        membershipResponse=$(aws identitystore list-group-memberships --identity-store-id "$identityStoreId" $nextTokenArg --group-id "$groupId" --output json)
        
        # Extract individual memberships from the response and add them to the memberships array.
        while IFS= read -r membership; do
            memberships+=("$membership")
        done < <(echo "$membershipResponse" | jq -c '.GroupMemberships[]')
        
        # Extract the next token for pagination.
        membershipNextToken=$(jq -r '.NextToken' <<< "$membershipResponse")

        # If there's no next token, exit the loop.
        if [ "$membershipNextToken" == "null" ]; then
            break
        fi
    done
    
    # Return early if there are no memberships
    [ -z "$memberships" ] && return

    # This iterates over the list of group memberships, extracting relevant details
    # such as membership ID and user ID. For each membership, it fetches the corresponding
    # user details from the AWS Identity Store. The user details are save to an array to
    # minimize redundant API calls. If the group is not managed by SCIM, 
    # it sanitizes the user name and writes a Terraform import block for the group membership 
    # to the appropriate output file.

    for membership in "${memberships[@]}"; do
        membershipId=$(jq -r '.MembershipId' <<< "$membership")
        membershipUserId=$(jq -r '.MemberId.UserId' <<< "$membership")

        membershipUser=$(aws identitystore describe-user --identity-store-id $identityStoreId --user-id $membershipUserId --output json)
        membershipUsers+=$membershipUser

        if ! $isSCIM; then
            # Sanitize the user name for Terraform block ID
            membershipUserName=$(jq -r '.UserName' <<< "$membershipUser")
            sanitizedMembershipUserName=$(sanitize_for_terraform "$membershipUserName")    
            
            # Write the group membership import block
            printf '%s\n' \
            "import {" \
            "  to = aws_identitystore_group_membership.controller[\"${sanitizedGroupDisplayName}___${sanitizedMembershipUserName}\"]" \
            "  id = \"$identityStoreId/$membershipId\"" \
            "}" \
            "" \
            >> ${files[group_memberships_import]}
        fi
    done

    # Alphabetize the membership users
    membershipUsers=$(echo "$membershipUsers" | jq -s -c 'sort_by(.UserName)[]')
    membershipUserNames=$(echo $membershipUsers | jq -r '.UserName')

    # Determine target file based on SCIM status
    targetMembershipMapFile=$($isSCIM && echo "group_memberships_map_scim" || echo "group_memberships_map")

    # Generate a mapping for group memberships
    echo "    \"$sanitizedGroupDisplayName\" = [" >> ${files[$targetMembershipMapFile]}
    for membershipUserName in $membershipUserNames; do
        sanitizedMembershipUserName=$(sanitize_for_terraform "$membershipUserName")
        echo "      \"$sanitizedMembershipUserName\"," >> ${files[$targetMembershipMapFile]}
    done

    # Close the group membership mapping
    echo "    ]," >> "${files[$targetMembershipMapFile]}"
}

# Fetch and process all groups
fetch_and_process_groups() {
    local identityStoreId="$1"
    local allGroups=$(fetch_all_groups "$identityStoreId")
    process_groups_list "$allGroups"
}
# -----------------------------------------------------------------------------


# Main Function
# -----------------------------------------------------------------------------
check_aws_credentials
write_initial_content
fetch_and_process_users "$identityStoreId"
fetch_and_process_groups "$identityStoreId"
write_closing_content

echo "Done!"
# -----------------------------------------------------------------------------