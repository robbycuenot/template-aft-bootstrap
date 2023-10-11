# Account Deletion

The process for deleting an account that has been created / added to Account Factory for Terraform is documented in these AWS guides:

 - [AWS Doc: Remove an account from AFT](https://docs.aws.amazon.com/controltower/latest/userguide/aft-remove-account.html)
 - [AWS Doc: Close an account created in Account Factory](https://docs.aws.amazon.com/controltower/latest/userguide/delete-account.html)
 - [AWS Video: Closing an AWS account in AWS Control Tower](https://www.youtube.com/watch?v=n3eALEKZaHc&list=PLhr1KZpdzukdS9skEXbY0z67F-wrcpbjm&index=7)

These guides outline the general process; however, there are some additional steps that should be taken if using account customizations, such as those featured in this project. This guide assumes you have a complete deployment of aft-bootstrap, aft-framework, and an account created using the "standard" account customization.

## Glossary

 - **AFT Account**: Often called AFT-Management, this is where the framework for Account Factory for Terraform resides (all pipelines, lambdas, step functions, etc)
 - **Management Account**: The Control Tower root / management account
 - **DEL Account**: The account that we are deleting in this guide

## Section 1: Changing Aliases

When an AWS account is deleted, the root user email address associated with that account can never be used again. Because accounts often have generic names like "sandbox", and the email address typically follows a format like aws+accountname@example.com, it is strongly advised that the email address be changed to an accessible throwaway address before deleting the account. If done properly, future email address conflicts can be avoided if an account with the same name is needed in the future. An easy way to generate this address is to append the account number to the current email address:

 - current: aws+sandbox@example.com
 - new: aws+sandbox987654321098@example.com

Account numbers are globally unique and not reused by AWS, so we are safe to make this change. Through this guide, we will do the same with the account name and sso user email to prevent future conflicts/confusion.

1. Log in to the **DEL Account** as root
   1. Top-right drop down -> Account
   1. Account Settings -> Edit
      1. Append the 12 digit account ID to the Account name
      1. Insert the 12 digit account ID into the root email, before the @ symbol
      1. Confirm the new email address
   1. Contact Information -> Edit
      1. Append the 12 digit account ID to the Full name
   1. (Optional: Add MFA with 1Password) Top-right drop down -> Security Credentials
      1. Assign MFA Device
      1. Device Name = 1Password
      1. MFA Device = Authenticator App
      1. Next
      1. Show QR Code
      1. Scan QR Code with 1Password
      1. Enter two sequential OTPs
      1. Add MFA

## Section 2: Updating the Account Request

This step is technically optional, as the AccountEmail, AccountName, and SSOUserEmail fields cannot be updated via aft-account-requests following the initial creation of the account. That being said, it is still recommended for record-keeping purposes.

This guide assumes that you are proceeding with this step, and includes one additional change that would otherwise be completed in the next section; moving the DEL account to the "Suspended" OU.

1. Log in to GitHub
   1. Edit aft-account-requests/terraform/main.tf
   1. Update the following fields:
      1. AccountEmail - Insert the 12 digit account ID into the root email, before the @ symbol
      1. AccountName - Append the 12 digit account ID to the Account name
      1. ManagedOrganizationalUnit - "Suspended"
         1. Note: This will kick off an update to the Service Catalog item for the DEL Account after several minutes. The update will migrate the account to the "Suspended" OU. This process takes ~10 minutes.
      1. SSOUserEmail - Same as AccountEmail
   1. Commit
1. Log in to Terraform
   1. Navigate to ct-aft-account-request
   1. Review the planned changes
   1. Apply

Before proceeding, ensure that the account has successfully moved to the **Suspended** OU.

## Section 3: Updating the Service Catalog

Again, this step is somewhat optional, but recommended if you are going through this guide. The purpose of this step is to update the SSOUserEmail, which can only be done through the Service Catalog item for the DEL Account. This will create a new "Manual" SSO User in IAM Identity Center and assign it as Admin to the account. The old user will remain. Both can be deleted following the termination of the account.

1. Log in to the **Management Account** as an SSO Admin (not root)
   1. Service Catalog -> Provisioned Products
   1. Select the product associated with the account
   1. Actions -> Update
      1. AccountEmail - **THE ORIGINAL ROOT EMAIL, NO CHANGE**
         1. The service catalog provisioned product update will fail if anything other than the original root email is used.
      1. AccountName - Append the 12 digit account ID to the Account name
      1. ManagedOrganizationalUnit - Suspended
      1. SSOUserEmail - Insert the 12 digit account ID into the root email, before the @ symbol
      1. SSOUserFirstName - Same as before
      1. SSOUserLastName - Same as before
   1. Wait for the update to complete

## Section 4: Removing the Account Request

This begins the initial phase of cleanup. Up until this point, all changes are easily reversible. Once this is applied, you are entering the point of no return.

From the AWS Docs:

    When you remove an account request from the account request repository, AFT deletes the customization pipeline and account metadata. For more information, see the 1.8.0 release notes for AFT on GitHub.

The 1.8.0 release notes: https://github.com/aws-ia/terraform-aws-control_tower_account_factory/releases/tag/1.8.0

1. Log in to GitHub
   1. Edit aft-account-requests/terraform/main.tf
   1. Comment out the account request
1. Log in to Terraform
   1. Navigate to ct-aft-account-request
   1. Review the planned changes
   1. Apply

After a few minutes, the aforementioned pipeline and account metadata will be removed from AWS.

## Section 5: Destroy the IaC

Run a destroy on the accountname-accountnumber workspace

[elaboration needed]

## Section 6: Customization Cleanup

This aspect of AFT has quite a bit of maturing to do. Most guides effectively say to delete all resources related to the customization phases manually. However, this can be a very tedious task depending on the complexity of the customizations. At the time of writing, the "standard" customization implemented by aft-bootstrap creates 8 different resources across 3 different services. As this will only grow over time, I found it important to build out a plan for destroying these resources using TFC.

AFT customization pipelines are invoked through a series of step functions, pipelines, and lambdas. Injecting "destroy" actions into that mix myself would cause drift from the main trunk of AFT, which I do not intend to do. I have hope that at some point AFT will support this functionality natively, as the python scripts already have [methods for doing so](https://github.com/aws-ia/terraform-aws-control_tower_account_factory/blob/6c0b356895478bb5c6578417640819aa0c8d774b/sources/scripts/workspace_manager.py#L188C7-L188C7). Until then, invoking a destroy completely outside of those processes is the easiest path forward.

At a high level, this process entails:
 - Downloading the source for the latest applied customization
 - Removing any lifecycle blocks that would prevent destroys
 - Adding a trust to allow your SSO user to assume AFTExecution in the DEL Account
 - Adding a provider block to the code for this assumption ^
 - Allowing deletion of github repos, both at the token and the organization level
 - **DESTROY**

These are still manual steps, however I've found them to be less tedious / error prone than manually removing the customization resources.

This process will destroy the following:
 - AWS OIDC provider, role, policy, and attachment
 - TFC IAC Workspace for the account and its variables
 - GitHub IAC Repo for the workspace

Before proceeding, BACK UP ANYTHING YOU VALUE. This is the nuclear option for your account.

1. Log in to the account to be deleted
    1. Add a trust policy to the AFTExecution role to allow a role you have access to in AWS SSO to assume it.
    1. The policy should look similar to the following. Note, the first two ARNs have the AFT-Management account ID in them, whereas the third ARN that we are adding is for the DEL Account. Make sure you have access to assume whatever role you place here.
    ```
    {
	     "Version": "2012-10-17",
      "Statement": [
		      {
			       "Effect": "Allow",
			       "Principal": {
		        		"AWS": [
				          "arn:aws:iam::12345678910:role/AWSAFTAdmin",
				          "arn:aws:sts::12345678910:assumed-role/AWSAFTAdmin/AWSAFT-Session",
				          "arn:aws:iam::987654321098:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_1234567890abcdef"
				        ]
			       },
			       "Action": "sts:AssumeRole"
		      }
	     ]
    }
    ```
1. Log in to the AFT-Management account
    1. Download the source code for your customizations
    1. S3 -> aft-customizations-pipeline-[AFT-MANAGEMENT-ACCOUNT-ID] ->
[ACCOUNT-YOU-ARE-DELETING-ID]-customi ->
source-aft
    1. Grab the latest two files (one is global, the other is not)
    1. Rename them to .zip and determine which is which. You want the non-global
    1. Extract the folder with the customizations that were applied
1. Open a codespace with the latest version of terraform
    1. https://github.com/robbycuenot/codespaces-terraform
    1. Click  ![Code <>](https://github.com/cuenot-io/aft-bootstrap/assets/51327557/9cf2b448-88fd-4d39-a960-38989ef0cdac)
  -> **Codespaces** tab -> **+** to create a codespace with Terraform
    1. Copy the customizations folder into the codespace
    1. Open a terminal in the codespace
    1. `cd` into the customizations folder
    1. Run `terraform login`
    1. Type `yes`
    1. Create a user token in Terraform Cloud with a short duration (1 day or less)
    1. Paste the user token into the terminal
    1. Apply the following changes to the code:

    ```
    terraform {
      backend "remote" {
        hostname = "app.terraform.io"
        organization = "yourorganization"

        workspaces {
          name = "yourcustomizationworkspace"
        }
      }
    }

    provider "aws" {
      access_key = "youraccesskey"
      secret_key = "yoursecretkey"
      token      = "yourtoken"
      region     = "us-east-1"
    }
    ```
    1. In Terraform Cloud, navigate to the account customization workspace
    1. Workspace Settings -> General -> Apply Settings -> Change from "Auto apply" to "Manual apply"
    1. If you intend to delete the workload repository associated with the account, you will need to ensure the following:
        1. The github_token associated with the workspace has "delete_repo" access
        1. The organization allows collaborators to delete repositories, if the user associated with this token is not an admin or owner of the organization
        1. The repository has this same user ^ as an admin
        1. It is recommended to only enable these settings **temporarily** to prevent accidental deletion of repositories
    1. Comment out any lifecycle "prevent_destroy" blocks (BE SURE YOU KNOW WHAT THIS MEANS. STOP AND RESEARCH BEFORE YOU PROCEED WITH THIS STEP, AS YOU ARE REMOVING CONTROLS THAT WERE IMPLEMENTED TO PREVENT THINGS FROM BEING DELETED)
    	1. If items exist that you do not want to delete, you can do the following:
            1. Use `terraform state list` and `terraform state rm <resource-id>` to remove the item from the workspace state
            1. Comment out the resource from the customization code
            1. Repeat for any other items you want to save
            1. Proceed with the rest of the guide
    1. Run `terraform init`
    1. Run `terraform destroy`
    1. Review the changes
    1. Type `yes`

## Section 7: Remove IAM Identity Center Permission Sets

    This is another optional step, but highly recommended. If you do not remove the permission set assignments, the account will continue to show up in the SSO portal until the account has been permanently closed after 90 days.

    1. Remove all permission set assignments from the account in IAM Identity Center

## Section 8: Unmanaging the Account

    1. Navigate to the provisioned product in Service Catalog
    1. Terminate the provisioned product for the account

## Section 9: Closing the Account

    1. Navigate to the Control Tower menu in the Management Account
    1. Select the account
    1. Close the account
