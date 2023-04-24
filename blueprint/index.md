---
title: Build resiliency in your IVR with Genesys Cloud emergency groups and callbacks
author: john.carnell
indextype: blueprint
icon: blueprint
image: images/blueprintcover.png
category: 5
summary: |
  This Genesys Cloud Developer Blueprint explains how to use GitHub Actions to deploy both examples of a resilient IVRs to two different Genesys Cloud organizations.
---
:::{"alert":"primary","title":"About Genesys Cloud Blueprints","autoCollapse":false} 
Genesys Cloud blueprints were built to help you jump-start building an application or integrating with a third-party partner. 
Blueprints are meant to outline how to build and deploy your solutions, not a production-ready turn-key solution.
 
For more details on Genesys Cloud blueprint support and practices 
please see our Genesys Cloud blueprint [FAQ](https://developer.genesys.cloud/blueprints/faq)sheet.
:::

This Genesys Cloud Developer Blueprint explains how to use GitHub Actions to deploy both examples of a resilient IVRs to two different Genesys Cloud organizations.

This blueprint also demonstrates how to:

* Set up a GitHub Action CI/CD pipeline to execute a CX-as-Code deployment
* Configure Terraform Cloud to manage the backing state for the CX-as-Code deployment along with the lock management for the Terraform deployment


## Scenario

An organization is interested in building a resilient IVR that can be used in two different scenarios:

1. **Genesys Cloud is available, but your origanization is unable to process calls within your contact center.** 
2. **Genesys Cloud availability is being impacted in one region, but you want to failure over calls ot an IVR running in another Genesys Cloud region.**

In the first scenario, the team wants to implement an IVR that can collect voicemail and process  automated callbacks so that when the emergency is over ALL agents can immediately start processing the customer callbacks.  

In the second scenario, the implementation team wants to have standby IVR in a completely separate Genesys Cloud region. They want to failover over voice traffic to the standby IVR and have a small subset of their total agent population (e.g. supervisors) log into the remote region to take calls. Because of the variability and volatility fo the situation they want all customer calls to first go to voicemail and have the agents call back the customers. 


## Solution 1 - IVR Failover within a single Genesys Cloud organization

In this first solution, you will leverage Genesys Cloud architect flows, emergency groups and callbacks to implement our resilient IVR. All components and configurations will be managed via CX as Code and can be deployed via the Terraform CLI or as a CI/CD pipeline using GitHub actions.  This scenario is illustrated below:

![Fallback IVR](/blueprint/images/fallbackivr.png "Build a fallback IVR using emergency groups and callbacks")

In this scenarios the following actions take place:

1. A customer calls into the organization and is going to be directed to an IVR. The IVR checks to see if an emergency group called `Organization Evacuation Emergency Group` is active. If the emergency group is not active normal call processing will occur by directing the user to an IVR menu with 6 destinations.  This check of the emergency group will occur as a startup task that will be executed before a customer is given a menu of choices.

2. If there is an emergency, a supervisor will log into Genesys cloud and will activate the Emergency Group.

3.  Now if a customer calls, in the IVR will check the emergency group and if it is active. It will direct the user to a voicemail box associated with the `General Help` support queue. 
 
4.  Once a voicemail is left by the customer, a callback will be created and placed in the `General Help`  queue. This callback will capture the phone number the user originally used to call the organization.

5.  After the emergency is over, a Genesys Cloud supervisor will deactivate the `Organization Evacuation Emergency Group` emergency group and calls will through the normal IVR flows. As agents log back in and go on queue, they will be presented with the voicemail and the callback information for the customer. They can proceed to call back the customer and process transactions normally.

This solution will use:

1. [A Genesys Cloud Inbound Call Architect Flow](https://help.mypurecloud.com/articles/about-inbound-flows/).
2.  [A call routing configuration to map the IVRs phone number to the IVR flow](https://help.mypurecloud.com/articles/about-call-routing/)
3.  [A Genesys Cloud Emergency Group](https://help.mypurecloud.com/articles/add-an-emergency-group/).  
4.  [Six Genesys Cloud Queues](https://help.mypurecloud.com/articles/create-queues-2/).

All the code for deploying this solution will be found in `terraform-ivr` directory.  Users and user assignment to queues will not occur through the Terraform scripts and will need to be manually or through [Genesys Cloud's SCIM](https://help.mypurecloud.com/articles/about-genesys-cloud-scim-identity-management/) integration.


## Solution 2 - IVR Failover to another Genesys Cloud region

In second scenario, we have two Genesys Cloud organizations with the primary IVR deployed in a similar fashion as solution #1 and a second IVR deployed in a Genesys Cloud organization in a second region. This is illustrated in the following diagram:

![Warm IVR](/blueprint/images/warmivr.png "Build a 'Warm' IVR using callbacks")

In this solution when an emergency is declared the following actions will take place:

1. A Genesys Cloud administrator will fail voice traffic manually over from the primary Genesys Cloud organization to the secondary organization. 

2.  In the secondary organization, there will be a very simple IVR that will route the user to a voicemail box for a queue called `General Help` and allow the customer to leave a voicemail.  When a voicemail is left a callback for the customer will also be created.

3.  A smaller group of agents will log into the secondary organization to start processing callbacks from the customer. It is important to note a Genesys Cloud group called `Emergency Group` will be assigned to the `General Help` queue in the secondary organization.  All agents who will process calls must be a member of this group in order to receive callbacks for processing.

This solutions will use:

1. [A Genesys Cloud Inbound Call Architect Flow](https://help.mypurecloud.com/articles/about-inbound-flows/).
2.  [A call routing configuration to map the IVRs phone number to the IVR flow](https://help.mypurecloud.com/articles/about-call-routing/) 
3.  [One Genesys Cloud Queues](https://help.mypurecloud.com/articles/create-queues-2/).
4.  [A Genesys Cloud Group](https://help.mypurecloud.com/articles/groups-overview/#:~:text=Genesys%20Cloud%20groups%20organize%20people,groups%20and%20skill%20expression%20groups.).
5. [Genesys Cloud SCIM integration](https://help.mypurecloud.com/articles/about-genesys-cloud-scim-identity-management/)

The IVR architect flow, call routing configuration, queue configuration and the group configuration can be found in `terraform-warm-ivr` directory. Setting up and configuring Genesys Cloud SCIM is the preferred mechanism to handle user provisioning and assigning users to groups. While CX as Code can do this type of work, it is not recommended.  

We will not be walking through SCIM setup in this blueprint. Please refer to the [Genesys Cloud SCIM]((https://help.mypurecloud.com/articles/about-genesys-cloud-scim-identity-management/)) documentation for more information.

## Contents

* [Solution components](#solution-components "Goes to the Solution components section")
* [Specialized Knowledge](#prerequisites "Goes to the Prerequisites section")
* [Implementation steps](#implementation-steps "Goes to the Implementation steps section")
* [Additional resources](#additional-resources "Goes to the Additional resources section")

## Solution components

* **Genesys Cloud** - A suite of Genesys Cloud services for enterprise-grade communications, collaboration, and contact center management. In this solution, you use an Architect inbound email flow, and a Genesys Cloud integration, data action, queues, and email configuration.
* **CX as Code** - A Genesys Cloud Terraform provider that provides a command line interface for declaring core Genesys Cloud objects.
* **GitHub** - A cloud-based source control system that facilitates collaboration on development projects.
* **Terraform Cloud** - A cloud-based Terraform solution that provides backend state storage and locking at scale.

While the primary focus of this blueprint will be setting up a CI/CD pipeline, the Architect flow used in this example requires the following components to be deployed:

### Specialized knowledge

* Administrator-level knowledge of Genesys Cloud
* Experience using GitHub
* Experience with Terraform or Terraform Cloud

:::primary
**Tip**: Both GitHub and Terraform Cloud provide free-tier services that you can use to test this blueprint.
:::

### Genesys Cloud account

* A Genesys Cloud license. For more information, see [Genesys Cloud Pricing](https://www.genesys.com/pricing "Opens the Genesys Cloud pricing page") in the Genesys website.
* Master Admin role. For more information, see [Roles and permissions overview](https://help.mypurecloud.com/?p=24360 "Opens the Roles and permissions overview article") in the Genesys Cloud Resource Center.
* CX as Code. For more information, see [CX as Code](https://developer.genesys.cloud/api/rest/CX-as-Code/ "Opens the CX as Code page").

### Third-party software

* A Terraform Cloud account with administrator-level permissions
* A GitHub account with administrator-level permissions

:::primary
**Tip**: Both GitHub and Terraform Cloud provide free-tier services that you can use to test this blueprint.
:::

## Implementation steps

1. [Clone the GitHub repository](#clone-the-github-repository "Goes to the Clone the GitHub repository section")
2. [Define the Terraform Cloud configuration](#define-the-terraform-cloud-configuration "Goes to the Define the Terraform Cloud configuration section")
3. [Define the GitHub Actions configuration](#define-the-github-actions-configuration "Goes to the Define the GitHub Actions configuration section")
4. [Deploy the Genesys Cloud objects](#deploy-the-genesys-cloud-objects "Goes to the Deploy the Genesys Cloud objects section")
5. [Test the deployment](#test-the-deployment "Goes to the Test the deployment section")

### Clone the GitHub repository

Clone the GitHub repository [TODO]//TODO "Opens the GitHub repository") to your local machine. The `dr-ivr-backup/blueprint` folder includes solution-specific scripts and files in these subfolders:
* `terraform-ivr`
* `terraform-warm-ivr`

### Define the Terraform Cloud configuration

Terraform Cloud provides:

*  **A backing store**. Terraform maintains state information for all configuration objects it manages. While there are many ways to set up Terraform backing store, by leveraging Terraform cloud we let Terraform manage all of this infrastructure for us.
*  **Lock management**. Terraform requires that only one instance of a particular Terraform configuration run at a time. Terraform Cloud provides this locking mechanism and will fail a Terraform deploy if the configuration's deployment is already underway.
*  **An execution environment**. Terraform Cloud copies your Terraform configuration and runs it remotely in their cloud environment.

For this blueprint, you need to create two Terraform Cloud workspaces: a production workspace and a fallback workspace for your Terraform IVR examples. In addition, you need to set up the Terraform and environment variables that these workspaces use and a Terraform cloud user token that Github uses to authenticate with Terraform.

For more information, see [Terraform Configurations in Terraform Cloud Workspaces](https://www.terraform.io/docs/cloud/workspaces/configurations.html "Opens the Terraform Configurations in Terraform Cloud Workspaces page") in the Terraform documentation.

#### Set up your production workspace

1.  Click **New Workspace**.
2.  Select the CLI-driven workflow.
3.  Provide a workspace name. For this blueprint, we use `ivr_prod`.  
4.  Click **Create workspace** environment. If everything works correctly the **Waiting for configuration page** appears.  
5.  Click **Settings** > **General** and verify these settings:
  * **Execution mode** - Remote
  * **Terraform Working Directory** - /blueprint/terraform-ivr
6. Click **Save settings**.

#### Set up your Terraform and environment variables

Terraform variables parameterize your scripts. Environment variables are usually used by Terraform providers to authenticate requests and connect to resources.

1. Click **Variables**.
2. Define the following Terraform variables:

  * `ivr_callback` - This is a message that will be injected into the IVR flow at deployment time indicating that an emergency has taken place. (e.g. We are currently unable to take your call at this time do to an unexpected emergency.  Please leave a voicemail message and a representative will call you back as soon as possible.)
  * `ivr_emergency_group_enabled` - Whether the deployed emergency group should be activated by default.  This is a `true`/`false` that should be set to `false`.
  * `ivr_failure` - This is a message that places if the IVR encounters an error that it can not recover from. (e.g. Sorry, an unrecoverable message has occurred. Please try to call back at another time.)
  * `ivr_initial_greeting` - This is the initial greeting played in the IVR. (e.g. Hello, welcome to Commonwealth Investment).
  * `ivr_phone_number` - The phone number that will "front" the IVR.
 
3. Define your environment variables:  

  * `GENESYSCLOUD_OAUTHCLIENT_ID` - This is the Genesys Cloud client credential grant Id that CX as Code executes against. Mark this environment variable as sensitive.
  * `GENESYSCLOUD_OAUTHCLIENT_SECRET` - This is the Genesys Cloud client credential secret that CX as Code executes against. Mark this environment variable as sensitive.
  * `GENESYSCLOUD_REGION` - This is the Genesys Cloud region in which your organization is located.

#### Set up a warm IVR workspace

Repeat the steps you just completed to set up your prod workspace, but make the following adjustments for your warm IVR workspace:  

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

You now need to generate a Terraform Cloud user token so that when Terraform is invoked in our GitHub Action, it can authenticate with Terraform Cloud.

1. Log in to your Terraform Cloud account.
2. Click your user profile icon.
3. Select **User settings**.
4. Navigate to the **Tokens** menu item.
5. Click **Create an API token**.
6. Provide a name for the token and click **Create API token**.
7. Cut and paste the generated token to a safe text file. You will need it later to set up your GitHub action.

  :::primary
  **Note**:
   You will not be able to see the token again and will need to re-generate the token if you lose it.
   :::

8. Click **Done**.

### Define the GitHub Actions configuration

GitHub Actions are the mechanism in which you define a CI/CD pipeline. GitHub Actions generally consist of two parts:

1.  **One or more workflow files** - Github Action Workflow files define the sequence of steps that comprise the CI/CD pipeline. These steps occur when the workflow executes. This blueprint contains a single workflow file called deploy-flow.yaml, which is located in the **.github/workflows** directory. This file contains all of the steps needed to install Terraform, deploy the Architect inbound email flow, and deploy the Genesys Cloud objects to the prod and prod-ivr-fallback organization.


2. Add your [Terraform cloud user token](#set-up-a-terraform-cloud-user-token "Goes to the Set up a Terraform cloud user token section"), which Terraform needs to authenticate with Terraform Cloud:

  * `TF_IVR_TOKEN`

### Deploy the Genesys Cloud objects with GitHub Actions

1. To deploy both your Genesys Cloud configuration and your Architect flows, do one of the following:

  * **To automatically kick off a deploy**, make a change to the configuration code and commit it to the source repository.  
  * **To manually launch your deploy**:

    1. Log into the Github repository that contains your code.
    2. Click **Actions**.
    3.  Click **Genesys Cloud Failure IVR Deploy**.
    4. Click **Run workflow**.
    5. From the drop-down list, select the main branch click **Run workflow**.

2. After you start your deploy, click the **Actions** menu item and verify that your deploy appears in the list.

### Deploy the Genesys Cloud objects with the Terraform CLI

You do not need to deploy the Terraform scripts using GitHub actions. If you want to just run these Terraform scripts directly from your laptop against your Genesys Cloud organizations you will need to
set the following operating system environment variables in the operating system shell you are going to execute the Terraform commands against:

  * `GENESYSCLOUD_OAUTHCLIENT_ID`
  * `GENESYSCLOUD_OAUTHCLIENT_SECRET`
  * `GENESYSCLOUD_REGION`

Depending on the scenario you want to run you will need to create a file call `ivr.auto.tfvars` in either the `blueprint/terraform-ivr`, `blueprint/terraform-warm-ivr`, or both. In this file you will need to set the script variables just as if you have set them in Terraform cloud.
  * `ivr_callback`
  * `ivr_emergency_group_enabled`
  * `ivr_failure`
  * `ivr_initial_greeting`
  * `ivr_phone_number`

Once these values are set you can run the Terraform scripts from the command-line using the standard Terraform command from the respective directories:

```
terraform init
terraform apply --auto-approve
```
### Test the deployment

To test the first IVR scenario, you can simply call the phone number you entered via `ivr_phone_number` parameter. If the `Organization Evacuation Emergency Group` (the emergency group created by the `blueprint/terraform-ivr/main.tf` Terraform script) has not been activated you will
be presented with the "happy path" in the IVR.  To test the "failure" path take the following actions:

1. Log into Genesys Cloud using an account with administrator access.
2. Click on the Admin -> Routing -> Emergency Groups.
3. Select the emergency group "Organization Evacuation Emergency Group".
4. Click on the vertical three period icon to the right of "Organization Evacuation Emergency Group" and select "Activate".
5. Now make a phone call to the IVR and you should now hear a message indicating that an emergency event has occurred and you will be asked to leave a voicemail.
6. Record your voicemail and hang up.

To hear the voicemail that you just left.

1. Log into Genesys Cloud using an account with administrator access.
2. Click the Admin -> Contact Center -> Queues.
3. Locate the `General Help` queue and click on link for the name of the queue.
4. Assign your self as a member of that queue.
5. Go on queue by clicking the slide bar in the upper right part of the screen.
6. The callback should now pop up.  Accept it.
7. You can then listen to the voicemail by clicking on it or perform an actual call by clicking on the phone number in the callback.

Testing the second scenario will be organization specific.  

1.  Fail the voice traffic over to the other "warm" Genesys Cloud organization.
2.  Make a call to the "warm" ivr.  You should be presented with a messaging indicating that there was an unexpected interruption in service and that you should leave voicemail.
3.  Leave a voicemail and hangup.

To hear the voicemail and process the callback:

1. Log into "Warm IVR" Genesys Cloud using an account with administrator access.
2. Click the Admin -> Contact Center -> Queues.
3. Locate the `General Help` queue and click on link for the name of the queue.
4. Assign your self as a member of that queue.
5. Go on queue by clicking the slide bar in the upper right part of the screen.
6. The callback should now pop up.  Accept it.
7. You can then listen to the voicemail by clicking on it or perform an actual call by clicking on the phone number in the callback.

## Additional resources

* [GitHub Actions](https://docs.github.com/en/actions "Opens the Github Actions page") in the GitHub website
* [Terraform Cloud](https://app.terraform.io/signup/account "Opens the Terraform Cloud sign up page") in the Terraform Cloud website
* [Terraform Registry Documentation](https://registry.terraform.io/providers/MyPureCloud/genesyscloud/latest/docs "Opens the Genesys Cloud provider page") in the Terraform documentation
* [cx-as-code-cicd-gitactions-blueprint repository](https://github.com/GenesysCloudBlueprints/cx-as-code-cicd-gitactions-blueprint "Goes to the cx-as-code-cicd-gitactions-blueprint repository") in Github
