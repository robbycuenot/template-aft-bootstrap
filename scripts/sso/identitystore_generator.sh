#!/bin/bash

# -----------------------------------------------------------------------------
# Script Name: identitystore_generator.sh
# Description: Processes users, groups, and memberships from AWS Identity Store
# Usage: ./identitystore_generator.sh
# -----------------------------------------------------------------------------



# Global Variables/Constants
# -----------------------------------------------------------------------------
identityStoreId=$(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text) || {
    echo "Error: Failed to retrieve the identityStoreId. Please check your AWS credentials."
    exit 1
}

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

# Make the identityStoreId and files array immutable
readonly identityStoreId
readonly -A files
# -----------------------------------------------------------------------------



# Utility Functions
# -----------------------------------------------------------------------------
sanitize_for_terraform() {
    local original_name="$1"
    
    # Ensure the name starts with a letter or underscore
    local sanitized_name=$(echo "$original_name" | sed 's/^[^a-zA-Z_]/_/')
    
    # Replace invalid characters with underscores
    sanitized_name=$(echo "$sanitized_name" | sed 's/[^a-zA-Z0-9_-]/_/g')
    
    ## Compute a short hash of the original name (first 5 characters of SHA-1 hash)
    ## Disabling this for now, as collisions are unlikely and names should be unique in AWS
    # local hash=$(echo -n "$original_name" | sha1sum | cut -c 1-5)
    
    ## Append the hash to the sanitized name
    # echo "${sanitized_name}_$hash"

    echo "$sanitized_name"
}
# -----------------------------------------------------------------------------



# File Initializing / Closing Functions
# -----------------------------------------------------------------------------
write_header() {
    local file="$1"
    echo "# Generated Terraform file for AWS IAM Identity Center" > "$file"
}

write_content() {
    local file="$1"
    shift
    local content="$@"
    cat >> "$file" <<- EOM
$content
EOM
}

write_initial_content() {
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

write_closing_content() {
    write_content "${files[users_map]}" '
  }
}'

    # Finish the Terraform group map file
    write_content "${files[groups_map]}" '
  }
}'

    write_content "${files[group_memberships_map]}" '
  }
}'

    write_content "${files[group_memberships_map_scim]}" '
  }
}'
}
# -----------------------------------------------------------------------------



# User Helper Functions
# -----------------------------------------------------------------------------
extract_user_optional_root_attributes() {
    local user_json="$1"
    declare -n userOptionalAttributesRef="$2"

    userOptionalAttributesRef=(
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
}

extract_user_email_attributes() {
    local user_json="$1"
    declare -n userEmailAttributesRef="$2"

    userEmailAttributesRef=(
        ["value"]=$(jq -r '.Emails[0].Value' <<< "$user_json")
        ["primary"]=$(jq -r '.Emails[0].Primary' <<< "$user_json")
        ["type"]=$(jq -r '.Emails[0].Type' <<< "$user_json")
    )
}

extract_user_address_attributes() {
    local user_json="$1"
    declare -n userAddressAttributesRef="$2"

    userAddressAttributesRef=(
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
}

extract_user_phone_attributes() {
    local user_json="$1"
    declare -n userPhoneAttributesRef="$2"

    userPhoneAttributesRef=(
        ["value"]=$(jq -r '.PhoneNumbers[0].Value' <<< "$user_json")
        ["primary"]=$(jq -r '.PhoneNumbers[0].Primary' <<< "$user_json")
        ["type"]=$(jq -r '.PhoneNumbers[0].Type' <<< "$user_json")
    )
}

fetch_all_users() {
    local userNextToken=""
    local userResponses=""

    while true; do
        local userResponseArgs=("--identity-store-id" "$identityStoreId" "--output" "json")
        [ -n "$userNextToken" ] && userResponseArgs+=("--next-token" "$userNextToken")
        
        local userResponse=$(aws identitystore list-users "${userResponseArgs[@]}")
        userResponses+=$(jq -r '.Users[]' <<< "$userResponse")
        
        userNextToken=$(jq -r '.NextToken' <<< "$userResponse")
        [ "$userNextToken" == "null" ] && break
    done

    echo "$userResponses"
}

process_users_list() {
    local usersList="$1"

    # Encode and then decode the JSON to address potential formatting issues
    local encodedUsers=$(echo "$usersList" | jq -s -c '.' | base64)
    local decodedUsers=$(echo "$encodedUsers" | base64 --decode)

    local sortedUsers=$(echo "$decodedUsers" | jq -s -c 'sort_by(.[] | .UserName)[]')
    local totalUsers=$(echo "$sortedUsers" | jq 'length')
    local processedUsers=0

    # Display the total number of users being processed
    echo "Processing $totalUsers users:"

    # Initialize progress bar
    echo -ne '[>-------------------] (0%)\r'

    jq -r '.[] | @base64' <<< "$sortedUsers" | while read -r user_encoded; do
        local user_decoded=$(echo "$user_encoded" | base64 --decode)
        process_user "$user_decoded"

        # Update progress bar
        processedUsers=$((processedUsers + 1))
        local progress=$((processedUsers * 100 / totalUsers))
        local progressBar=$(printf '=%.0s' $(seq 1 $((progress / 5))))
        echo -ne "[${progressBar:0:20}>] ($progress%)\r"
    done

    # End the progress bar with a newline and display completion message
    echo -e "\nUser processing complete."
}

generate_user_map_line() {
    local sanitizedUserName="$1"
    local isSCIM="$2"
    local prefix=""

    [[ "$isSCIM" == "true" ]] && prefix="data."

    printf '%s\n' \
    "    \"$sanitizedUserName\" = ${prefix}aws_identitystore_user.$sanitizedUserName.user_id" \
    >> "${files[users_map]}"
}

generate_user_resource_block() {
    local userName="$1"
    local userDisplayName="$2"
    local userGivenName="$3"
    local userFamilyName="$4"
    declare -n userOptionalAttributesRef="$5"
    declare -n userEmailAttributesRef="$6"
    declare -n userAddressAttributesRef="$7"
    declare -n userPhoneAttributesRef="$8"

    {
        printf "resource \"aws_identitystore_user\" \"%s\" {\n" "$sanitizedUserName"
        printf "  user_name         = \"%s\"\n" "$userName"
        printf "  display_name      = \"%s\"\n" "$userDisplayName"
        echo "  identity_store_id = local.sso_instance_id"
        printf "  name {\n    given_name  = \"%s\"\n    family_name = \"%s\"\n  }\n" "$userGivenName" "$userFamilyName"

        # Print optional user attributes
        for attribute in "${!userOptionalAttributesRef[@]}"; do
            value="${userOptionalAttributesRef[$attribute]}"
            [[ $value != "null" ]] && printf "  %s = \"%s\"\n" "$attribute" "$value"
        done

        generate_user_nested_attributes "emails" userEmailAttributesRef
        generate_user_nested_attributes "addresses" userAddressAttributesRef
        generate_user_nested_attributes "phone_numbers" userPhoneAttributesRef

        # Add lifecycle block to prevent destruction of users
        echo "  lifecycle {"
        echo "    prevent_destroy = true"
        echo "  }"

        echo "}"
        echo ""

    } >> "${files[users]}"
}

generate_user_data_block() {
    local userName="$1"
    local sanitizedUserName="$2"

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
    "" >> "${files[users]}"
}

generate_user_import_block() {
    local sanitizedUserName="$1"
    local userId="$2"

    printf '%s\n' \
    "import {" \
    "  to = aws_identitystore_user.$sanitizedUserName" \
    "  id = \"$identityStoreId/$userId\"" \
    "}" \
    "" \
    >> "${files[users_import]}"
}

generate_user_nested_attributes() {
    local blockName="$1"
    declare -n attrRef="$2"  # Changed the name to avoid conflict

    if [[ ${attrRef["value"]} != "null" ]]; then
        echo "  $blockName {" >> "${files[users]}"
        for attribute in "${!attrRef[@]}"; do
            value=${attrRef[$attribute]}
            if [[ $value != "null" ]]; then
                echo "    $attribute = \"$value\"" >> "${files[users]}"
            fi
        done
        echo "  }" >> "${files[users]}"
    fi
}
# -----------------------------------------------------------------------------



# Group Helper Functions
# -----------------------------------------------------------------------------
fetch_all_groups() {
    local groupNextToken=""
    local groupResponses=""

    while true; do
        local groupResponseArgs=("--identity-store-id" "$identityStoreId" "--output" "json")
        [ -n "$groupNextToken" ] && groupResponseArgs+=("--next-token" "$groupNextToken")
        
        local groupResponse=$(aws identitystore list-groups "${groupResponseArgs[@]}")
        groupResponses+=$(jq -r '.Groups[]' <<< "$groupResponse")
        
        groupNextToken=$(jq -r '.NextToken' <<< "$groupResponse")
        [ "$groupNextToken" == "null" ] && break
    done

    echo "$groupResponses"
}

process_groups_list() {
    local groupsList="$1"

    # Encode and then decode the JSON to address potential formatting issues
    local encodedGroups=$(echo "$groupsList" | jq -s -c '.' | base64)
    local decodedGroups=$(echo "$encodedGroups" | base64 --decode)

    local sortedGroups=$(echo "$decodedGroups" | jq 'sort_by(.DisplayName)')
    local totalGroups=$(echo "$sortedGroups" | jq 'length')
    local processedGroups=0

    # Display the total number of groups being processed
    echo "Processing $totalGroups groups:"

    # Initialize progress bar
    echo -ne '[>-------------------] (0%)\r'

    echo "$sortedGroups" | jq -c '.[]' | while read -r group; do
        process_group "$group"

        # Update progress bar
        processedGroups=$((processedGroups + 1))
        local progress=$((processedGroups * 100 / totalGroups))
        local progressBar=$(printf '=%.0s' $(seq 1 $((progress / 5))))
        echo -ne "[${progressBar:0:20}>] ($progress%)\r"
    done

    # End the progress bar with a newline and display completion message
    echo -e "\nGroup processing complete."
}

generate_group_map_line() {
    local sanitizedGroupDisplayName="$1"
    local isSCIM="$2"
    local prefix=""

    [[ "$isSCIM" == "true" ]] && prefix="data."

    printf '%s\n' \
    "    \"$sanitizedGroupDisplayName\" = ${prefix}aws_identitystore_group.$sanitizedGroupDisplayName.group_id" \
    >> "${files[groups_map]}"
}

generate_group_resource_block() {
    local sanitizedGroupDisplayName="$1"
    local groupDisplayName="$2"
    local groupDescription="$3"
    
    printf '%s\n' \
    "resource \"aws_identitystore_group\" \"$sanitizedGroupDisplayName\" {" \
    "  display_name      = \"$groupDisplayName\"" >> "${files[groups]}"
    
    [ "$groupDescription" != "null" ] && printf '  description       = "%s"\n' "$groupDescription" >> "${files[groups]}"
    
    printf '%s\n' \
    "  identity_store_id = local.sso_instance_id" \
    "" \
    "  lifecycle {" \
    "    prevent_destroy = true" \
    "  }" \
    "}" \
    "" >> "${files[groups]}"
}

generate_group_data_block() {
    local sanitizedGroupDisplayName="$1"
    local groupDisplayName="$2"
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
    "" >> "${files[groups]}"
}

generate_group_import_block() {
    local sanitizedGroupDisplayName="$1"
    local groupId="$2"
    printf '%s\n' \
    "import {" \
    "  to = aws_identitystore_group.$sanitizedGroupDisplayName" \
    "  id = \"$identityStoreId/$groupId\"" \
    "}" \
    "" >> "${files[groups_import]}"
}
# -----------------------------------------------------------------------------



# Group Membership Helper Functions
# -----------------------------------------------------------------------------
extract_group_membership_details() {
    local membership="$1"
    local membershipId=$(jq -r '.MembershipId' <<< "$membership")
    local membershipUserId=$(jq -r '.MemberId.UserId' <<< "$membership")
    echo "$membershipId $membershipUserId"
}

generate_group_membership_map_line() {
    local membershipUserNames="$1"
    local targetMembershipMapFile="$2"

    for membershipUserName in $membershipUserNames; do
        local sanitizedMembershipUserName=$(sanitize_for_terraform "$membershipUserName")
        echo "      \"$sanitizedMembershipUserName\"," >> ${files[$targetMembershipMapFile]}
    done
}

generate_group_membership_import_block() {
    local sanitizedGroupDisplayName="$1"
    local membershipUserName="$2"
    local membershipId="$3"
    local sanitizedMembershipUserName=$(sanitize_for_terraform "$membershipUserName")
    printf '%s\n' \
    "import {" \
    "  to = aws_identitystore_group_membership.controller[\"${sanitizedGroupDisplayName}___${sanitizedMembershipUserName}\"]" \
    "  id = \"$identityStoreId/$membershipId\"" \
    "}" \
    "" \
    >> ${files[group_memberships_import]}
}

fetch_group_memberships() {
    local groupId="$1"
    local -n membershipsRef="$2"
    
    # Initialize the token for pagination.
    local membershipNextToken=""

    while true; do
        # If there's a next token, include it in the request arguments.
        local nextTokenArg=${membershipNextToken:+--next-token "$membershipNextToken"}

        # Fetch the list of group memberships for the given group ID.
        local membershipResponse=$(aws identitystore list-group-memberships --identity-store-id "$identityStoreId" $nextTokenArg --group-id "$groupId" --output json)
        
        # Extract individual memberships from the response and add them to the memberships array.
        while IFS= read -r membership; do
            membershipsRef+=("$membership")
        done < <(jq -c '.GroupMemberships[]' <<< "$membershipResponse")
        
        # Extract the next token for pagination.
        membershipNextToken=$(jq -r '.NextToken' <<< "$membershipResponse")

        # If there's no next token, exit the loop.
        if [ "$membershipNextToken" == "null" ]; then
            break
        fi
    done
}

fetch_group_membership_user() {
    local membershipUserId="$1"
    local membershipUser=$(aws identitystore describe-user --identity-store-id "$identityStoreId" --user-id "$membershipUserId" --output json)
    echo "$membershipUser"
}
# -----------------------------------------------------------------------------



# Core Functions
# -----------------------------------------------------------------------------
process_user() {
    user_json="$1"

    userId=$(jq -r '.UserId' <<< "$user_json")
    userName=$(jq -r '.UserName' <<< "$user_json")
    userDisplayName=$(jq -r '.DisplayName' <<< "$user_json")
    userGivenName=$(jq -r '.Name.GivenName' <<< "$user_json")
    userFamilyName=$(jq -r '.Name.FamilyName' <<< "$user_json")

    # Sanitize the group name for Terraform block ID
    sanitizedUserName=$(sanitize_for_terraform "$userName")

    # Check if the user is SCIM managed
    isSCIM=$(echo "$user_json" | jq 'has("ExternalIds")')

    if $isSCIM; then
        generate_user_data_block "$userName" "$sanitizedUserName"
    else
        # These are associative arrays that are passed
        # by reference to the extract functions. Bash does
        # not support returning these arrays from a function,
        # so this is the workaround.
        declare -A userOptionalAttributes
        declare -A userEmailAttributes
        declare -A userAddressAttributes
        declare -A userPhoneAttributes

        extract_user_optional_root_attributes "$user_json" userOptionalAttributes
        extract_user_email_attributes "$user_json" userEmailAttributes
        extract_user_address_attributes "$user_json" userAddressAttributes
        extract_user_phone_attributes "$user_json" userPhoneAttributes

        generate_user_resource_block \
            "$userName" \
            "$userDisplayName" \
            "$userGivenName" \
            "$userFamilyName" \
            userOptionalAttributes \
            userEmailAttributes \
            userAddressAttributes \
            userPhoneAttributes 

        # Generate an import block for non-SCIM managed users
        generate_user_import_block "$sanitizedUserName" "$userId"
    fi

    # Generate a mapping for users
    generate_user_map_line "$sanitizedUserName" "$isSCIM"
}

process_group() {
    local group_json="$1"
    
    local groupId=$(jq -r '.GroupId' <<< "$group_json")
    local groupDisplayName=$(jq -r '.DisplayName' <<< "$group_json")
    local groupDescription=$(jq -r '.Description' <<< "$group_json")

    # Sanitize the group name for Terraform block ID
    local sanitizedGroupDisplayName=$(sanitize_for_terraform "$groupDisplayName")

    # Check if the group is SCIM managed
    local isSCIM=$(jq 'has("ExternalIds")' <<< "$group_json")
    
    # Generate Terraform blocks for the group
    if $isSCIM; then
        generate_group_data_block "$sanitizedGroupDisplayName" "$groupDisplayName"
    else
        generate_group_resource_block "$sanitizedGroupDisplayName" "$groupDisplayName" "$groupDescription"
        generate_group_import_block "$sanitizedGroupDisplayName" "$groupId"
    fi

    generate_group_map_line "$sanitizedGroupDisplayName" "$isSCIM"



    # Group memberships are processed as a nested
    # function within group processing to minimize the
    # number of API calls made to AWS.
    declare -a memberships
    fetch_group_memberships "$groupId" memberships
    
    # If there are no memberships, exit early
    [ -z "$memberships" ] && return

    # Process each membership's data
    local membershipUsers=""
    process_group_membership memberships "$sanitizedGroupDisplayName" membershipUsers "$isSCIM"

    # Sort membership users and generate membership mapping
    local sortedMembershipUsers=$(echo "$membershipUsers" | jq -s -c 'sort_by(.UserName)[]')
    local membershipUserNames=$(echo $sortedMembershipUsers | jq -r '.UserName')
    local targetMembershipMapFile=$($isSCIM && echo "group_memberships_map_scim" || echo "group_memberships_map")
    
    echo "    \"$sanitizedGroupDisplayName\" = [" >> ${files[$targetMembershipMapFile]}
    generate_group_membership_map_line "$membershipUserNames" "$targetMembershipMapFile"
    echo "    ]," >> "${files[$targetMembershipMapFile]}"
}

# Child process of process_group() to minimize API calls
process_group_membership() {
    local -n membershipsRef="$1"
    local sanitizedGroupDisplayName="$2"
    local -n membershipUsersRef="$3"
    local isSCIM="$4"

    for membership in "${membershipsRef[@]}"; do
        read membershipId membershipUserId <<< $(extract_group_membership_details "$membership")
        membershipUser=$(fetch_group_membership_user "$membershipUserId")
        membershipUsersRef+=$membershipUser

        if ! $isSCIM; then
            local membershipUserName=$(jq -r '.UserName' <<< "$membershipUser")
            generate_group_membership_import_block "$sanitizedGroupDisplayName" "$membershipUserName" "$membershipId"
        fi
    done
}

fetch_and_process_users() {
    local allUsers=$(fetch_all_users)
    process_users_list "$allUsers"
}

fetch_and_process_groups() {
    local allGroups=$(fetch_all_groups)
    process_groups_list "$allGroups"
}
# -----------------------------------------------------------------------------



# Main Function
# -----------------------------------------------------------------------------
write_initial_content
fetch_and_process_users
fetch_and_process_groups
write_closing_content

echo "Done!"
# -----------------------------------------------------------------------------