# How it works
You provide the script the name of the source space on an Octopus Deploy instance, the name of a destination space on an Octopus instance.  The script leverages the Octopus Deploy Restful API to copy items from the source space into the destination space.

## CloneSpaceProject.ps1

The `CloneSpaceProject.ps1` is a new addition to this repository.  `CloneSpace.ps1` expects you to know exactly what you want to clone.  In a lot of cases, you won't know those details.  `CloneSpaceProject.ps1` was designed to fill in that gap.  It will loop through the list of projects you provide and it will walk the dependency tree and determine what items are required.  It will build up the `CloneSpace.ps1` parameters for you and call the script.

## ProjectSyncer.ps1

The `ProjectSyncer.ps1` script is a simplified version of the space cloner.  It allows you to keep projects in sync with one another in the same space.  This is useful when you have a template project and you make a modification to it and you want to update all the child projects.

## CloneSpace.ps1

The `CloneSpace.ps1` script is the workhorse of this repository.  It contains all the logic to perform the actual cloning.

## CloneTentacleInstance.ps1

The `CloneTentacleInstance.ps1` is designed to be run on deployment targets or workers you wish to clone to the new instance.  You'd run the script on each deployment target.  What it will do is pull all the information about the tentacle from the source system, it will then create a new tentacle instance and register itself with with the destination instance using all the settings from the source.  For example, there is polling tentacle pointing to `https://local.octopusdemos.app` for the environment `Test` and the role `MyRole`.  Running this script I can create a clone of that tentacle, point that new tentacle to `https://localeap.octopusdemos.app` with the same environment `Test` and role `MyRole`.

Because this is creating a new tentacle instance it **must** be run on the VM with the tentacle you wish to clone.  You can configure a runbook in Octopus to do this, or leverage the script console.  You cannot run this script on any computer like you can with the other scripts.

## What will it clone
The script `CloneSpace.ps1` will clone the following:

- Accounts
- Build Information
- Certificates
    - Will only copy when a new certificate is found or the certificate thumbprints are different
- Environments
- External Feeds
- Library Variable Sets
- Lifecycles
- Machine Policies
- Packages
- Project Groups
- Projects
    - Settings
    - Deployment Process
    - Runbooks
    - Variables
    - Project Versioning Strategy 
    - Project Automatic Release Creation 
- Script Modules
- Step Templates (both community and custom step templates)
- Teams
- Tenants
- Tenant Variables
- Tenant Tags
- Targets (no polling tentacles)
- Worker Pools
- Workers (no polling tentacles)

### What won't it clone
The script `CloneSpace.ps1` will not clone the following items:
- Releases
- Deployments
- User Roles
- Users
- External Auth Providers
- Server Settings (folders, SMTP, JIRA, etc)

This script assumes the user for the destination has `Space manager` rights.  Some of those items, users, roles, and creating spaces, cannot be copied over because the space manager does not have permissions to do so.

Several of those items cannot be copied because the space cloner uses Octopus API.  It doesn't hit the database directly.  Creating a release would create a snapshot, and doing a deployment would do an actual deployment.  Those items would occur when you ran the script, not when they actually occurred on the source space.

## The Space Has to Exist
The space on the source and destination must exist prior to running the script.  The script will fail if the destination space doesn't exist.  It doesn't create a space for you.

## What the script leaves in place
This script was designed to be run multiple times with the same parameters.  It isn't useful if the script is overwriting/removing values each time you run it.  It will not overwrite the following:

- Community Step Templates (match by name)
- Environments (match by name)
- Feeds (match by name)
- Infrastructure Accounts (match by name)
- Library Variable variables and Tenant variables (see below)
- Packages (match by package name and version)
- Project Items
    - Channels (match by name)
    - Deployment Process steps (match by name)    
    - Variable Set (match by name)        
    - Runbook Process steps (match by name)    
- Worker Pools (match by name)
- Workers (match by name)
- Teams (match by name)
- Targets (match by name)
- Tenants (match by name) -> it will add missing projects to the tenant

## Scope Matching
Imagine if your source instance had the environments `Development` and `Test` while the destination only had `Production`.  You have a step scoped to only run on `Development`.  When that step is cloned over what should it do?  See more how this works in the [How Scope Cloning Works Documentation](HowScopeCloningWorks.md).

## Variable Matching
Variable matching is very complex as variables can have a variety of scoping associated with them.  See how [Variable Matching Works](HowVariableMatchingWorks.md).

## Limitations
Because this is hitting the Octopus Restful API, it cannot decrypt items from the Octopus Database.  To decrypt items from the Octopus database, you'll need access to the master key and the database.  This script was designed to run on an Octopus Cloud instance.  You, the user, do not have access to that information.  

Please see the [sensitive variables page](SensitiveVariables.md) for more information on the script handles sensitive variables.

## Simple Relationship Management
The process does not attempt to walk a tree of dependencies.  It loads up all the necessary data from the source and destination.  It will attempt to find the corresponding ID in the destination space when it comes across an ID in the source space.  If it cannot find a matching item, it removes that binding.  

## Process Cloning
This script assumes that when you clone a deployment process, you want to add missing steps but leave existing steps.

I have a deployment process on my source, where I added a new step.

![](../img/process-source-added-step.png)

My destination deployment process has a new step on the end that is not in the source.

![](../img/destination-deployment-process-before-sync.png)

After the sync is finished, the new step was added, and the additional step was left as is.

![](../img/destination-deployment-process-after-sync.png)

The rules for cloning a deployment process are:

- Clone steps not found in the destination process
- Leave existing steps as is
- The source process is the source of truth for step order.  It will ensure the destination deployment process order matches.  It will then add additional steps found in the deployment process not found in the source to the end of the deployment process.

### Override Default Process Cloning Behavior

A new parameter has been added to the process cloner, `ProcessCloningOption`.  That allows you to overwrite the default behavior.  The options are `KeepAdditionalDestinationSteps` or `SourceOnly`.  The default is `KeepAdditionalDestinationSteps`.  Setting this parameter to `SourceOnly` will result in any steps in the destination not on the source to be removed.

## Targets and Workers

The script will clone your targets and workers.  However, there are a few key items you should know.

If you are cloning from one instance to another, the tentacle will not trust the destination instances's thumbprint.  You will need to run `Tentacle configure --trust="YOUR SERVER THUMBPRINT"` on the server itself for the tentacle to trust the new server.  See [documentation](https://octopus.com/docs/octopus-rest-api/tentacle.exe-command-line/configure) for more details.

Secondly, the clone script only supports a subset of all targets.  The targets supported are:

- Listening Tentacle
- K8s Cluster (not using a token or cert to auth with)
- Cloud Regions
- Azure Web Apps

The `CloneSpace.ps1` script cannot clone polling tentacles from one instance to another due to how polling tentacles work.  The polling tentacles won't know about the switch.  You will need to set up a new polling tentacle instance on the server. 

Another option is to run the script `CloneTentacleInstance.ps1` on the VMs you wish to copy over to the destination instance.  This script works with both polling and listening tentacles.

## Teams and role scoping

The script provides an option to clone teams.  It follows the following rules:

- Only space-specific teams will be cloned.  Any system teams, such as `Everyone`, `Octopus Administrators`, etc. will _**NOT**_ be cloned. 
- It will assign users who already exist in the destination instance.  It will _**NOT**_ create new users.
- The clone will only create the team.  After that, it will leave the team as is.  
- Teams that are created have the external groups cleared.  
- For team scoping, the roles must exist on both the destination and the source.  This script will _**NOT**_ create new roles.  It only leverages existing roles.  
- If the destination team already has roles scoped to it, the script will skip it.

## Certificates

The process for cloning certificates is different than other items.  This is due to the fact we have a reliable means of comparing certificates (thumbprint) and some certificates have passwords.  

The logic for cloning certificates is to only clone a certificate when:

- The certificate is not present on the destination.
- The source and destination certificate thumbprints do not match.
- The destination certificate was archived.

You can tell the space cloner to clone the certificate all day long, but unless one of those conditions are met, the certificate will not be cloned.

Unlike the other parameters, the certificate parameter does not support "all" or wild-card matching.  This is to allow you to submit a password.  You must match the certificate name exactly.  The format for the certificate parameter is `[CertificateName1]::[Password01],[CertificateName2]::[Password02]`, for example `MyCert::Password!`.  