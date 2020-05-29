# Use Case: migrating from self-hosted to the cloud

The space cloner will not do a full migration to the cloud.  It will help you clone all your projects, variable sets, accounts, and so on.  Also, it is a cloner, not a migrator; it will leave the destination space as is.  It will be up to you to deactivate that instance when you see fit.

## Prep Work

The following steps will help ensure the cloner runs as smoothly as possible.

1. Create a cloud instance
2. Create a space in the cloud instance you want to clone to.  If something goes sideways, you can delete that space and try again.
3. Decide how you want Octopus Cloud to connect to your tentacles.  
    - If you want to use listening tentacles hosted in your data center, you'll need to open up port 10933 in your firewall as well as create public DNS entries (or public IP addresses) for those servers.  
    - If you want to use listening tentacles hosted in a cloud provider, you'll need to ensure port 10933 is open in the security groups or network policies.  The servers will also need a public IP address assigned to them.
    - You will need to create new polling tentacle instances on your tentacles if you want to use polling tentacles.

# Examples

Here are some example scripts to help get you started.

## Clone Everything

This example will clone everything the script is allowed to clone from the local instance to your cloud instance.  Please see Please refer to the [how it works page](HowItWorks.md#what-will-it-clone) to get a full list of items cloned and not cloned.

Please refer to the [Parameter reference page](ParameterReference.md) for more details on the parameters.

The other options are:
- `OverwriteExistingVariables` - set to `true` to match your local instance.  Any new variable found will be added.
- `OverwriteExistingCustomStepTemplates` - Set to `true` so all step templates are cloned from the source instance.
- `AddAdditionalVariableValuesOnExistingVariableSets` - set to `true` to add all variables.  
- `OverwriteExistingLifecyclesPhases` - Set to `true` to keep the lifecycles in sync.
- `CloneProjectChannelRules` - set to `true` as you'll want to include the channel rules with the project.
- `CloneTeamUserRoleScoping` - set to `true` as you'll want to include all the scoped permissions with the teams.
- `CloneProjectVersioningReleaseCreationSettings` - set to `true` as you'll want to include the release creation settings.

```PowerShell
CloneSpace.ps1 -SourceOctopusUrl "https://instance1.yoursite.com" `
    -SourceOctopusApiKey "SOME KEY" `
    -SourceSpaceName "My Space Name" `
    -DestinationOctopusUrl "https://instance2.octopus.app" `
    -DestinationOctopusApiKey "My Key" `
    -DestinationSpaceName "My Space Name" `  
    -EnvironmentsToClone "all" `
    -WorkerPoolsToClone "all" `
    -ProjectGroupsToClone "all" `
    -TenantTagsToClone "all" `
    -ExternalFeedsToClone "all" `
    -StepTemplatesToClone "all" `
    -InfrastructureAccountsToClone "all" `
    -MachinePoliciesToClone "all" `
    -LibraryVariableSetsToClone "all" `
    -LifeCyclesToClone "all" `
    -ProjectsToClone "all" `
    -TenantsToClone "all" `
    -TargetsToClone "all" `
    -WorkersToClone "all" `
    -SpaceTeamsToClone "all" `
    -OverwriteExistingVariables "true" `
    -AddAdditionalVariableValuesOnExistingVariableSets "true" `
    -OverwriteExistingCustomStepTemplates "true" `
    -OverwriteExistingLifecyclesPhases "true" `
    -CloneProjectChannelRules "true" `
    -CloneTeamUserRoleScoping "true" `
    -CloneProjectVersioningReleaseCreationSettings "true"
```

## Clone Everything But Environments, Workers, and Targets

Chances are you did a lot of prep work to get targets and workers registered on your cloud instance.  To do that, you needed to create environments, worker pools, workers, and targets.  This example will exclude those items but clone everything else the clone is allowed to do.  Please see Please refer to the [how it works page](HowItWorks.md#what-will-it-clone) to get a full list of items cloned and not cloned.

Please refer to the [Parameter reference page](ParameterReference.md) for more details on the parameters.

The other options are:
- `OverwriteExistingVariables` - set to `true` to match your local instance.  Any new variable found will be added.
- `OverwriteExistingCustomStepTemplates` - Set to `true` so all step templates are cloned from the source instance.
- `AddAdditionalVariableValuesOnExistingVariableSets` - set to `true` to add all variables.  
- `OverwriteExistingLifecyclesPhases` - Set to `true` to keep the lifecycles in sync.
- `CloneProjectChannelRules` - set to `true` as you'll want to include the channel rules with the project.
- `CloneTeamUserRoleScoping` - set to `true` as you'll want to include all the scoped permissions with the teams.
- `CloneProjectVersioningReleaseCreationSettings` - set to `true` as you'll want to include the release creation settings.

```PowerShell
CloneSpace.ps1 -SourceOctopusUrl "https://instance1.yoursite.com" `
    -SourceOctopusApiKey "SOME KEY" `
    -SourceSpaceName "My Space Name" `
    -DestinationOctopusUrl "https://instance2.octopus.app" `
    -DestinationOctopusApiKey "My Key" `
    -DestinationSpaceName "My Space Name" `  
    -WorkerPoolsToClone "all" `
    -ProjectGroupsToClone "all" `
    -TenantTagsToClone "all" `
    -ExternalFeedsToClone "all" `
    -StepTemplatesToClone "all" `
    -InfrastructureAccountsToClone "all" `    
    -LibraryVariableSetsToClone "all" `
    -LifeCyclesToClone "all" `
    -ProjectsToClone "all" `
    -TenantsToClone "all" `
    -SpaceTeamsToClone "all" `
    -OverwriteExistingVariables "true" `
    -AddAdditionalVariableValuesOnExistingVariableSets "true" `
    -OverwriteExistingCustomStepTemplates "true" `
    -OverwriteExistingLifecyclesPhases "true" `
    -CloneProjectChannelRules "true" `
    -CloneTeamUserRoleScoping "true" `
    -CloneProjectVersioningReleaseCreationSettings "true"
``` 