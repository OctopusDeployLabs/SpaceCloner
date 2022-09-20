# Space Cloner
PowerShell script to help you clone a space using the Octopus Deploy Restful API.

# The cloning process won't cover all use cases
This script was developed internally by the Customer Solutions Team at Octopus Deploy to solve specific use cases we encounter each day.  We are sharing this script to help other users of Octopus Deploy.  It won't cover all use cases, and that is by design.  It is limited by the fact it is a CLI tool going against a REST API.  It doesn't have direct DB acces.

> **Note:** if you have questions on how to use this script please reach out to advice@octopus.com

This repository is [licensed](license) under the Apache license.  While it covers a variety of use cases, we know it can't cover every last hyper-specific use case. As such, we encourage you to fork it, test it out on an empty space or empty instance, look at the results and modify the script to meet your needs.  If you feel your change can benefit the community, please submit a pull request!

## Issues and Feature Requests

Issues, bugs, and feature requests are accepted.  Please create an issue in this repo and we will address it when we can.  We will do our best to accomodate your request, however, this tool was written for specific use cases in mind and it might not match your specific use case.  It is licensed under the [apache](license) license, you are free to fork the repository and fix any issues or add any features you think is useful.

The Customer Solutions Team at Octopus Deploy plans on keeping this tool up to date with the latest version of Octopus Deploy.  If you do fork this repo, you might want to keep up to date on the latest changes.

## Support

The space cloner is not shy about logging.  Everything it does is logged into the log.txt file.  We encourage you to review the logs before submitting an issue.  Often times it is a missing command line option or a mis-spelling.  For example, you might be getting a 400 bad request when trying to create a lifecycle, but that is a result of a missing environment for a phase.

If you do need help, please zip up your log files and send them to advice@octopus.com along with a description on what you are trying to do with the tool.  

## Pull Requests

Pull Requests are accepted on this repository.  See [Contributing guidelines](docs/Contributing.md).

## Tested Octopus Deploy Versions

This script has been tested against the following versions of Octopus Deploy:

- `2020.1.x`
- `2020.2.x`
- `2020.3.x`
- `2020.4.x`
- `2020.5.x`
- `2020.6.x`
- `2021.1.x`
- `2021.2.x`
- `2021.3.x`
- `2022.1.x`
- `2022.2.x`
- `2022.3.x`
- `2022.4.x`

It should work with `3.4.x`+ release of Octopus Deploy.  The script will run some version checks to ensure it doesn't call the wrong API endpoint.  There is a far better chance the script will work using a `2020.x` or higher release of Octopus Deploy.

The source instance and the destination instance **must** be running the same major/minor (2020.1, 2020.2) release.  The script will check the version of the source instance and destination instance to ensure this rule is met.  It is possible to override that requirement by setting the `IgnoreVersionCheckResult` to `$true`, however you run the risk of something not working or cloning correctly.

# Just Get Me Going!

This repository contains multiple scripts:

- [CloneSpace.ps1](docs/CloneSpaceParameterReference.md) - The script to clone a set of items from space to another.
- [CloneSpaceProject.ps1](docs/CloneSpaceProjectParameterReference.md) - Will perform a reverse lookup and determine all the items it needs to clone for you.
- [CloneLibraryVariableSet.ps1](docs/CloneLibraryVariableSetParameterReference.md) - To be used when you want to copy a library variable set in the same space or different spaces.
- [ProjectSyncer.ps1](docs/ProjectSyncerParameterReference.md) - Will sync a parent project with 1 to N child projects in the same space on the same instance.
- [CloneTentacleInstance.ps1](docs/CloneTentacleInstanceParameterReference.md) - Run this script on deployment targets or workers and it will create a cloned tentacle instance pointing to the destination

The fastest way to get started is to run this command.  It will clone everything in a space for you.

```PowerShell
CloneSpaceProject.ps1 -SourceOctopusUrl "https://samples.octopus.app" `
    -SourceOctopusApiKey "SOME KEY" `
    -SourceSpaceName "Target - SQL Server" `
    -DestinationOctopusUrl "https://samples.octopus.app" `
    -DestinationOctopusApiKey "My Key" `
    -DestinationSpaceName "Redgate Space" `    
    -ProjectsToClone "all"
```
**Note**: The destination space should be created before running the clone scripts. 

# What If Mode

It can be scary to run a random script off the internet.  All the scripts in this repository include a `WhatIf` parameter.  Set that parameter to `$true` and the scripts will do everything up to the point of making changes to your destination.

All the changes the script will do (or has done) is saved to the `ChangeLog.txt` file in the root directory.

# Use cases
Space Cloner was written to cover the following use cases.

- As a user, I want to split my one massive default space into [multiple spaces on the same instance](docs/UseCase-BreakUpSpace.md).
- As a user, I have two Octopus Deploy instances.  One for dev/test deployments.  Another for staging/prod deployments.  I have the [same set of projects I want to keep in sync](docs/UseCase-KeepInstancesInSync.md).
- As a user, I want to clone a set of projects to a test instance to [verify an upgrade](docs/UseCase-CopyToTestInstance.md).
- As a user, I have a set of "parent" projects.  I clone from that project when I need to create a new project.  However, when the process on the "parent" project is updated, I would like to [update the existing "child" projects](docs/UseCase-ParentChildProjects.md).
- As a user, I would like to copy my projects from [self-hosted Octopus to Octopus Cloud](docs/UseCase-MigrateFromSelfHostedToCloud.md).
- As a user, I would like to [create a copy an existing variable set in the same space](docs/UseCase-CopyLibraryVariableSet.md).
- As a user, I would like to [copy existing tentacles to point to a new instance](docs/UseCase-CopyExistingTentacles.md)

The Space Cloner leverages the Octopus Deploy API.  That limits what it can and cannot do.
-  It cannot clone deployments or releases.  If it did a POST to copy over a release all the audit records would show the release was created at the time the space cloner ran not the original release date on the source.  A POST to the deployment API would perform an actual deployment, not copy over deployment information such as task logs, artifacts, etc.
-  It cannot clone sensitive variables, accounts, or anything else encrypted in the database.  Those are never returned in the API anyway.

## Possible but not recommended
- As a user, I want to merge multiple Octopus Deploy instances into the same space on a new instance.  That scenario, merging multiple disparate instances into one massive space, is not recommended.  The chance of overwriting something meaningful is very high.  Just like steering a car with your knees, while possible, it is not recommended.

## Unsupported
The use cases for the space cloner is centered around repeately running the cloning script.  However, it wasn't intended to keep two instances fully in sync.  

It won't clone:
- Users 
- User Roles
- Server Settings (folders, JIRA, auth options, etc).  
- Releases, Deployments, Runbook Snapshots, and Runbook Runs.

That is due to a few reasons.
- Octopus Deploy REST API Limits
    - Sensitive values, such as passwords, are not returned from the REST API.
    - Creating releases and runbook snapshots snapshots the process and variables as it exists today.  That means it cannot copy a release created six months ago on the source instance.
    - Task logs, artifacts, and task history cannot be cloned, they are created during a runbook run or deployment.
    - Creating a deployment or runbook run will cause an actual runbook run or deployment to occur.
- Security Concerns
    - Server Manager or higher permissions are required to create users, user roles and modify server settings.  Server managers can also modify any space or project.  That means sharing an API key of a user who has that permission, which is not recommended.


# How the space cloner works
Please see the [how it works page](docs/HowItWorks.md).

# How matching works
Please see the [how matching works page](docs/HowMatchingWorks.md).

# Sensitive variables
Please see the page [sensitive variables](docs/SensitiveVariables.md) to see how sensitive variables are handled.

# Debugging and logging
Please see the [debugging and logging page](docs/Debugging.md).

# Reference
Please see [parameter reference page](docs/ParameterReference.md).

# Examples
Please see the [example page](docs/Examples.md).

# FAQ
Below are questions and answers to common questions we've gotten about this project.

### Why was this script created?
The Customer Solutions Team at Octopus Deploy team developed this script.  We use it to clone items for our [samples instance](https://samples.octopus.app).

### Can I use this to migrate from self-hosted to the cloud?
Yes.  However, this script is not a full migration.  It will jump-start your migration.  This script hits the API, meaning it won't have access to your sensitive variables.  it will not clone releases or deployments.  See the [how it works](docs/HowItWorks.md) page for details on what it will and won't clone.  

### Is this the space migration / self-hosted to Octopus Cloud migrator tool that has been teased in the past?
No.  It was designed for specific use cases, and the limits placed on it were intentional.  For example, it can't access your Master Key, and without that, it cannot decrypt your sensitive data.  It should get you 80-90% of the way there.  You are free to fork this repo to modify the scripts to help get you another 5% of the way there.   

### Can I use this script to migrate from 2018.10 to 2020.2?
By default, no.  The script compares the major and minor versions of the source and destination.  

**Unless the source and destination [major].[minor] versions are the same; the script will not proceed.**

That can be overridden by setting the parameter `IgnoreVersionCheckResult` to `true`.  That should only be set to `true` when cloning to test spaces or test instances.  Setting it to `true` when cloning to production instances is asking for trouble.  This parameter was added to make it easier for the Octopus Advisory Team to set up test instances of Octopus Deploy with EAP versions.

### What permissions should the users tied to the API keys have?
For the source instance, a user with read-only permissions to all objects copied is required.  It will never write anything back to the source.

For the destination instance, we recommend a user with `Space Manager` or higher.  You can go through and lock down permissions as you see fit, but `Space Manager` will get you going.

### Can I use this in an Octopus Deploy runbook?
Yes!  It is a PowerShell script.  It calls the APIs, so you should be fine in using it in an Octopus Deploy runbook.

### Why doesn't this script create the destination space?
Honestly, it's a security concern.  There are two built-in roles that provide the space create permission, `System Manager` and `System Administrator`.  We recommend using the API key of a [service account user](https://octopus.com/docs/security/users-and-teams/service-accounts) when running the script.  That service account user would either need to be added to `Octopus Managers` or `Octopus Administrators` teams.  That user would also have permissions to create users and update other settings on your instance.  We want you to feel comfortable using the script as-is.  Requiring elevated permissions is a concern, and it isn't something we felt good about asking our users to do.

Yes, you can create a custom role and assign the service account user to that role.  The goal of this script is it should "just work" with a minimal amount of configuration on your end.  Once you start diving into permissions and custom roles, it is going to be much harder to get working.  

### Does the script clone users, teams, and roles?
This script does _**NOT**_ clone users, roles, or system teams.  You can tell it to clone space-specific teams only. 

When it attempts to set up scoping for a team, it will skip any missing roles on the destination.  

Teams that are created have the external groups cleared.  

In other words, the clone team functionality will only assign existing users and roles to space teams.  This is an intentional decision, as creating anything new might compromise your security on the destination instance.  

### It doesn't appear like all my variables were cloned, what gives?

The cloner defaults to leaving variables on the destination instance as-is.  

On your source space you have the variable `Testing.Variable` and it is set to `Test`.  On the destination instance that same variable exists and it is set to `Super Test`.  By default the cloner will leave the value on the destination instance as `Super Test`.  To update that value to match the source you will have to set the parameter `OverwriteExistingVariables` to `$true`.  

**The default for the paramter `OverwriteExistingVariables` is `$false`.**

The space cloner will never overwrite a sensitive variable.  

The space cloner matches variables by comparing:
- Names
- Sensitive Values vs Non Sensitive Values
- Environment Scoping
- Channel Scoping
- Process Scoping
- Machine Scoping
- Step Scoping
- Role Scoping

If you add a scope, the space cloner will see that as a new variable value and add it.  Same is true for changing from sensitive to non-sensitive or vice versa.

### What if I have dev and test in one instance and production in another and I have variable scoped to dev

By default the space cloner will skip that variable.  The space cloner allows you to throw an error on mismatch, skip unless everything is matched, throw an error unless there is a partial match, skip unless there is a partial match, or ignore the mismatch and clone whatever is there.  

You have flexibility with each scoping option.

- Deployment Process (both runbook and deployment process)
    - Environments
    - Channels
- Variables (both project and library variable set)
    - Environments
    - Channels
    - Process Owners (deployment process or runbook)
    - Deployment Process Steps
    - Deployment Targets
    - Accounts
    - Certificates
- Infrastructure (targets and certificates)
    - Environments
    - Tenants

### Why doesn't the space cloner clone deployments and releases?

It is a limitation of the space cloner going through the API.  You might have releases `1.1.0`, `1.2.1`, and `1.4.5` all created months apart.  If the space cloner were to clone those releases it would snapshot the existing deployment process and variables as they exist today AND set the release creation date to be today.  It wouldn't be a true clone.

For deployments, Octopus would do the actual deployment.  Which means it would first deploy `1.1.0`, then `1.2.1` and then `1.4.5`, but each one would use the deployment process and variables as they exist today.  

In a nutshell, it would be a big mess and not an accurate representation of your releases or deployments.
