---
title: Build resiliency in your IVR with Genesys Cloud emergency groups and callbacks
author: john.carnell
indextype: blueprint
icon: blueprint
image: images/blueprintcover.png
category: 5
summary: |
  This Genesys Cloud Developer Blueprint describes how to deploy both resilient IVR examples to two different Genesys Cloud organizations using GitHub Actions.
---
:::{"alert":"primary","title":"About Genesys Cloud Blueprints","autoCollapse":false}
Genesys Cloud blueprints were built to help you jump-start building an application or integrating with a third-party partner. 
Blueprints are meant to outline how to build and deploy your solutions, not a production-ready turn-key solution.
 
For more details on Genesys Cloud blueprint support and practices, 
see our Genesys Cloud blueprint [FAQ](https://developer.genesys.cloud/blueprints/faq) sheet.
:::

This Genesys Cloud Developer Blueprint describes how to deploy both resilient IVR examples to two different Genesys Cloud organizations using GitHub Actions.

This blueprint also demonstrates how to:

* Set up a GitHub Action CI/CD pipeline to deploy CX-as-Code
* Configure Terraform Cloud to manage the backing state for the CX-as-Code deployment, and the lock management for Terraform

## Scenario

An organization is interested in developing a resilient IVR that can be used in two different scenarios:

1. **Genesys Cloud is available, but your organization cannot process calls within your contact center.** 
2. **Genesys Cloud availability is impacted in one region, but you want to fail over calls to an IVR running in a different Genesys Cloud region.**

The first scenario, the team wants to implement an IVR that collects voicemail and processes automated callbacks. When the emergency has been resolved, ALL agents can immediately process customer callbacks.  

The second scenario, the implementation team wants the standby IVR to be in a different Genesys Cloud region. They want voice traffic failover on the standby IVR and a small subset of agents (e.g., supervisors) to be able to take calls from the remote region. Because of the variability and volatility of the situation, all customer calls should be directed to voicemail and agents will call back. 


## Solution 1 - IVR Failover within a single Genesys Cloud organization

The first solution demonstrates how Genesys Cloud architect flows, emergency groups, and callbacks can be used to implement a resilient IVR system. All components and configurations are managed through CX as Code and deployed using Terraform CLI or GitHub actions as part of CI/CD pipelines. The following is an illustration:

![Fallback IVR](/blueprint/images/fallbackivr.png "Build a fallback IVR using emergency groups and callbacks")

The following actions are taken in this scenario:

1. When a customer calls the organization, they are directed to an IVR. The IVR checks whether the `Organization Evacuation Emergency Group` is active. Users who do not have an active emergency group are directed to an IVR menu with six destinations. The emergency group check is performed as a startup task before the customer is presented with options.

2. A supervisor activates the Emergency Group in Genesys Cloud in an emergency.

3. In the IVR, the customer is now notified if an emergency group is active when they call. The user will be directed to a voicemail box associated with the `General Help` support queue. 
 
4. When the customer leaves a voicemail, a callback is created and placed in the `General Help` queue. A callback captures the phone number the user initially used to call the organization.

5. After the emergency ends, a Genesys Cloud supervisor deactivates the `Organization Evacuation Emergency Group` emergency group. The call passes through the normal IVR flow. Upon login, agents see the customer's voicemail and callback information. The customer can be contacted and then the transaction can be completed normally.

This solution uses:

1. [A Genesys Cloud Inbound Call Architect Flow](https://help.mypurecloud.com/articles/about-inbound-flows/).
2.  [A call routing configuration to map the IVRs phone number to the IVR flow](https://help.mypurecloud.com/articles/about-call-routing/)
3.  [A Genesys Cloud Emergency Group](https://help.mypurecloud.com/articles/add-an-emergency-group/).  
4.  [Six Genesys Cloud Queues](https://help.mypurecloud.com/articles/create-queues-2/).

The code for deploying this solution can be found in the `terraform-ivr` directory. Users and queue assignment do not happen through Terraform scripts. Instead, they need to be done manually or through the [Genesys Cloud's SCIM](https://help.mypurecloud.com/articles/about-genesys-cloud-scim-identity-management/) integration.

## Solution 2 - IVR Failover to another Genesys Cloud region

In the second scenario, we have two Genesys Cloud organizations with the primary IVR deployed similarly to solution #1. There is also a second IVR deployed in a Genesys Cloud organization in a different region. The following diagram illustrates this.

![Warm IVR](/blueprint/images/warmivr.png "Build a 'Warm' IVR using callbacks")

Following the declaration of an emergency, these actions are taken:

1. Voice traffic from the primary Genesys Cloud organization is manually failed to the secondary Genesys Cloud organization by a Genesys Cloud administrator. 

2. IIn the secondary organization, there is a simple IVR that routes users to a voicemail box queue called `General Help`. Voicemails can be left by the customer. When a voicemail is left, a callback is created.

3. A small group of agents log into the secondary organization to handle customer callbacks. In the secondary organization, it is important to assign the Genesys Cloud group `Emergency Group` to the `General Help` queue. Callbacks must be received by members of this group for agents to process the calls.

This solutions uses:

1. [A Genesys Cloud Inbound Call Architect Flow](https://help.mypurecloud.com/articles/about-inbound-flows/ "Opens the Inbound flows overview article").
2. [A call routing configuration to map the IVRs phone number to the IVR flow](https://help.mypurecloud.com/articles/about-call-routing/ "Opens the Call routing overview article") 
3. [One Genesys Cloud Queues](https://help.mypurecloud.com/articles/create-queues-2/ "Opens the Create queues article").
4. [A Genesys Cloud Groups overview](https://help.mypurecloud.com/articles/groups-overview/#:~:text=Genesys%20Cloud%20groups%20organize%20people,groups%20and%20skill%20expression%20groups "Opens the Groups overview article").
5. [Genesys Cloud SCIM integration](https://help.mypurecloud.com/articles/about-genesys-cloud-scim-identity-management/ "Opens the About Genesys Cloud SCIM (Identity Management article")

IVR architect flow, call routing configuration, queue configuration and the group configuration can be found in the `terraform-warm-ivr` directory. Setting up and configuring Genesys Cloud SCIM is the preferred mechanism for provisioning and assigning users to groups. This type of work can be done with CX as Code, but it is not recommended.  

SCIM setup is not covered in this blueprint. For more information, see the [About Genesys Cloud SCIM (Identity Management](https://help.mypurecloud.com/articles/about-genesys-cloud-scim-identity-management/ "Opens the About Genesys Cloud SCIM (Identity Management article") documentation.

## Solution components

* **Genesys Cloud** - A suite of Genesys Cloud services for enterprise-grade communications, collaboration, and contact center management. In this solution, you use an Architect inbound email flow, and Genesys Cloud integration, data action, queues, and email configuration.
* **CX as Code** - A Genesys Cloud Terraform provider that provides a command line interface for declaring core Genesys Cloud objects.
* **GitHub** - A cloud-based source control system that facilitates collaboration on development projects.
* **Terraform Cloud** - A cloud-based Terraform solution that provides backend state storage and locking at scale.

While the primary focus of this blueprint will be setting up a CI/CD pipeline, the Architect flow used in this example requires the following components to be deployed:

### Specialized knowledge

* Administrator-level knowledge of Genesys Cloud
* Experience using GitHub
* Experience with Terraform or Terraform Cloud

:::primary
**Tip**: This blueprint can be tested on Terraform Cloud or GitHub's free tiers.
:::

### Genesys Cloud account

* A Genesys Cloud license. For more information, see [Genesys Cloud Pricing](https://www.genesys.com/pricing "Goes to the Genesys Cloud pricing page") on the Genesys website.
* Master Admin role. For more information, see [Roles and permissions overview](https://help.mypurecloud.com/?p=24360 "Opens the Roles and permissions overview article") in the Genesys Cloud Resource Center.
* CX as Code. For more information, see [CX as Code](https://developer.genesys.cloud/api/rest/CX-as-Code/ "Opens the CX as Code page").

### Third-party software

* A Terraform Cloud account with administrator-level permissions
* A GitHub account with administrator-level permissions

:::primary
**Tip**: This blueprint can be tested on Terraform Cloud or GitHub's free tiers.
:::

## Implementation steps

1. [Clone the GitHub repository](#clone-the-github-repository "Goes to the Clone the GitHub repository section")
2. [Define the Terraform Cloud configuration](#define-the-terraform-cloud-configuration "Goes to the Define the Terraform Cloud configuration section")
3. [Define the GitHub Actions configuration](#define-the-github-actions-configuration "Goes to the Define the GitHub Actions configuration section")
4. [Deploy the Genesys Cloud objects](#deploy-the-genesys-cloud-objects "Goes to the Deploy the Genesys Cloud objects section")
5. [Test the deployment](#test-the-deployment "Goes to the Test the deployment section")

### Clone the GitHub repository

Clone the GitHub repository [GenesysCloudBlueprints/dr-fallback-ivr](https://github.com/GenesysCloudBlueprints/dr-fallback-ivr "Opens the GitHub repository") to your local machine. The `dr-fallback-ivr/blueprint` folder contains solution-specific scripts and files in these subfolders:
* `terraform-ivr`
* `terraform-warm-ivr`

### Define the Terraform Cloud configuration

Terraform Cloud provides:

*  **A backing store**. All configuration objects that Terraform manages maintain state information. While Terraform backing stores can be set up in many ways, by leveraging Terraform cloud, we let Terraform manage all infrastructure for us.
*  **Lock management**. Terraform allows only one configuration instance to run at a time. This lock mechanism is built into Terraform Cloud and will fail a Terraform deployment if the configuration is already in progress.
*  **An execution environment**. The Terraform Cloud runs your Terraform configuration remotely in one of their cloud environments.

In this blueprint, you need to establish two Terraform Cloud workspaces for your Terraform IVR examples: one for production and one for fallback. You must also configure the Terraform and environment variables that these workspaces use, along with the Terraform cloud user token that GitHub uses to authenticate.

For more information, see [Terraform Configurations in Terraform Cloud Workspaces](https://www.terraform.io/docs/cloud/workspaces/configurations.html "Goes to the Terraform Configurations in Terraform Cloud Workspaces") on the Terraform website.

#### Set up your production workspace

1.  Click **New Workspace**.
2.  Select the CLI-driven workflow.
3.  Enter a workspace name. For this blueprint, we use `ivr_prod`.  
4.  Click **Create workspace** environment. When everything has been configured correctly, a **Waiting for configuration page** appears.  
5.  Click **Settings** > **General** and verify the following settings:
  * **Execution mode** - Remote
  * **Terraform Working Directory** - /blueprint/terraform-ivr
6. Click **Save settings**.

#### Set up your Terraform and environment variables

Terraform variables parameterize your scripts. Terraform providers usually use environment variables to authenticate requests and connect to resources.

1. Click **Variables**.
2. Define the following Terraform variables:

  * `ivr_callback` - When the IVR flow is deployed, a message is injected to indicate an emergency. (e.g., We are currently unable to take your call at this time due to an unexpected emergency. Please leave a voicemail message and a representative will call you back as soon as possible.)
  * `ivr_emergency_group_enabled` - The deployment of an emergency group should be activated by default. This is a `true`/`false` that should be set to `false`.
  * `ivr_failure` - The error message displayed if the IVR cannot recover from the error. (e.g., Sorry, an unrecoverable message has occurred. Please try to call back at another time.)
  * `ivr_initial_greeting` - The IVR plays this greeting at the beginning of the call. (e.g., Hello, welcome to Commonwealth Investment).
  * `ivr_phone_number` - The IVR "front" phone number.
 
3. Define your environment variables:  

  * `GENESYSCLOUD_OAUTHCLIENT_ID` - This is the Genesys Cloud client credential grant Id that CX as Code executes against. Mark this environment variable as sensitive.
  * `GENESYSCLOUD_OAUTHCLIENT_SECRET` - This is the Genesys Cloud client credential secret that CX as Code executes against. Mark this environment variable as sensitive.
  * `GENESYSCLOUD_REGION` - This is the Genesys Cloud region in which your organization is located.

#### Set up a warm IVR workspace

In the warm IVR workspace, repeat the steps you just completed for the prod workspace, but make the following adjustments:  

1. Use a different workspace name. For example: "ivr_fallback_prod". 
2. Set the following variables to point to your ivr_fallback_prod workspace:

  * `ivr_callback`
  * `ivr_emergency_group_enabled`
  * `ivr_failure`
  * `ivr_initial_greeting`
  * `ivr_phone_number`
  * `GENESYSCLOUD_OAUTHCLIENT_ID`
  * `GENESYSCLOUD_OAUTHCLIENT_SECRET`
  * `GENESYSCLOUD_REGION`
#### Set up a Terraform cloud user token

GitHub Actions require a Terraform Cloud user token so Terraform can authenticate with Terraform Cloud when invoked.

1. Log in to your Terraform Cloud account.
2. Click your user profile icon.
3. Select **User settings**.
4. Navigate to the **Tokens** menu item.
5. Click **Create an API token**.
6. Enter a token name, and click **Create API token**.
7. Cut and paste the generated token into a safe text file. The information is required later when setting up your GitHub action.

  :::primary
  **Note**:
   The token cannot be seen again, so you must re-generate it if it is lost.
   :::

8. Click **Done**.

### Define the GitHub Actions configuration

GitHub Actions are the mechanism in which CI/CD pipelines are defined. Actions on GitHub usually consist of two parts:

1.  **One or more workflow files** - The Github Action Workflow files define the sequence of steps in the CI/CD pipeline. Execution of the workflow triggers these steps. This blueprint contains a single workflow file called **deploy-flow.yaml** in the **.github/workflows** directory. This file contains instructions on how to install Terraform, deploy the Architect inbound email flow, and deploy the Genesys Cloud objects to the prod and prod-ivr-fallback organization.


2. Add your [Terraform cloud user token](#set-up-a-terraform-cloud-user-token "Goes to the Set up a Terraform cloud user token section"), which Terraform needs to authenticate with Terraform Cloud:

  * `TF_IVR_TOKEN`

### Deploy the Genesys Cloud objects with GitHub Actions

1. You can deploy both your Genesys Cloud configuration and your Architect flows as follows:

  * **To automatically kick off a deployment**, make a change to the configuration code and commit it to the source repository.  
  * **To manually launch your deployment**:

    1. Log into the GitHub repository that contains your code.
    2. Click **Actions**.
    3.  Click **Genesys Cloud Failure IVR Deploy**.
    4. Click **Run workflow**.
    5. From the drop-down list, select the main branch and click **Run workflow**.

2. Click the **Actions** menu item after you start your deployment and verify that your deployment appears in the list.

### Deploy the Genesys Cloud objects with the Terraform CLI

You do not have to deploy the Terraform scripts using GitHub actions. You need to set the following operating system variables in the operating system shell you execute the Terraform commands against if you want to run these Terraform scripts directly from your laptop.

  * `GENESYSCLOUD_OAUTHCLIENT_ID`
  * `GENESYSCLOUD_OAUTHCLIENT_SECRET`
  * `GENESYSCLOUD_REGION`

The `ivr.auto.tfvars` file is created either in the `blueprint/terraform-ivr`folder, or in the `blueprint/terraform-warm-ivr` folder, depending on the scenario. The script variables in this file must be set just like in Terraform cloud.
  * `ivr_callback`
  * `ivr_emergency_group_enabled`
  * `ivr_failure`
  * `ivr_initial_greeting`
  * `ivr_phone_number`

Lastly, modify the `blueprint/terrafrom-ivr/main.tf` and/or `blueprint/terraform-warm-ivr/main.tf` files for the local file store. Replace the `main.tf` file opening block with the following:

```
terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
    }
  }
  backend "remote" {
    organization = "thoughtmechanix"

    workspaces {
      prefix = "ivr_"
    }
  }
}
```

to this:

```
terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
    }
  }
}
```
Once these values are set, Terraform scripts can run from the command line using the standard Terraform commands:

```
terraform init
terraform apply --auto-approve
```
### Test the first scenario

You can test the first IVR scenario by calling the phone number you entered in the `ivr_phone_number` parameter. If you do not activate the `Organization Evacuation Emergency Group` (created by the `blueprint/terraform-ivr/main.tf` Terraform script), you are presented with a "happy path" in the IVR. Take the following actions to test the "failure" path:

1. Log into Genesys Cloud using an administrator account.
2. Click Admin -> Routing -> Emergency Groups.
3. Select the emergency group "Organization Evacuation Emergency Group".
4. Click the three vertical dots icon on the right of the "Organization Evacuation Emergency Group" and select "Activate".
5. Call the IVR and you should hear a message indicating an emergency event has occurred. You will be asked to leave a voicemail.
6. Hang up after recording a voicemail.

Listen to the voicemail you just left.

1. Log into Genesys Cloud using an administrator account.
2. Click Admin -> Contact Center -> Queues.
3. Locate the `General Help` queue and click the link for the queue name.
4. Assign yourself as a member of that queue.
5. Click the slide bar in the upper right corner to go to the queue.

You should now see the callback. 

6. Accept the callback.
7. Click the voicemail icon to listen to it or call the number in the callback to place an actual call.

### Test the second scenario
A second scenario involves organization-specific testing.  

1. Fail over voice traffic to the other "warm" Genesys Cloud organization.
2. Call the "warm" IVR.  

A message should indicate that service has been interrupted and you should leave a voicemail.

3. Hang up after leaving a voicemail.

Process the callback and hear the voicemail:

1. Log into "Warm IVR" Genesys Cloud using an administrator account.
2. Click Admin -> Contact Center -> Queues.
3. Locate the `General Help` queue and click on its link.
4. Assign yourself as a member of that queue.
5. Click the slide bar in the upper right corner to go to the queue.You should now see the callback. 

You should now see the callback. 

6. Accept the callback.
7. Click the voicemail icon to listen to it or call the number in the callback to place an actual call.

## Additional resources

* [GitHub Actions Documentation](https://docs.github.com/en/actions "Goes to the GitHub Actions Documentation page") on the GitHub website.
* [Terraform Cloud](https://app.terraform.io/signup/account "Goes to the Terraform Cloud sign up page") on the Terraform Cloud website.
* [Terraform Registry Documentation](https://registry.terraform.io/providers/MyPureCloud/genesyscloud/latest/docs "Goes to the Genesys Cloud provider page") on the Terraform website.
* [dr-fallback-ivr repository](https://github.com/GenesysCloudBlueprints/cx-as-code-cicd-gitactions-blueprint "Goes to the r-fallback-ivr repository") in GitHub.

