# Use Case: keeping instances in sync

It is not recommended, but we have seen companies split their projects across multiple Octopus Deploy instances, one for dev/test and another for staging/production.  Keeping the processes in sync between the instances can be a massive pain.  That also means the targets, workers, and connection strings are very different.

In other cases, there are two Octopus Deploy instances; they are mirror images of one another, except they deploy to different data centers.  Just like with Dev/Test and Staging/Prod split, that means the targets, workers, and connection strings are very different.

These are the use cases the space cloner was designed for.  However, it wasn't designed to determine all project dependencies (environments, variable sets, lifecycles, etc).

Please refer to the [how it works page](HowItWorks.md#what-will-it-clone) to get a full list of items cloned and not cloned.

# Gotchas
The process does not attempt to walk a tree of dependencies.  It loads up all the necessary data from the source and destination.  When it comes across an ID in the source space, it will attempt to find the corresponding ID in the destination space.  If it cannot find a matching item, it removes that binding.  

## Excluded bindings

If that binding on a specific object is required, the script will fail.  

Let's use environment scoping as an example.  In my source space, I have a variable set called `Global`.  That variable set has an environment scoped to environments.

![](../img/source-global-variables-environment-scoping.png)

In my destination space, I only have three of those four environments, `Test`, `Staging`, and `Production`.  As a result, the cloned variable set still has the `Development` value, but it doesn't have a scope associated with it.

![](../img/destination-global-variables-environment-scoping-missing-env.png)

# Example - Initial Clone

For the initial clone, I would leverage the [Octopus Migrator](https://octopus.com/docs/administration/data/data-migration) this copy everything (including sensitive variables) over to another instance.  

This should be done once; after that, the space cloner should be used or subsequent projects and changes.  

# Example - Dev/Test Instance and Staging/Prod instance

This example will clone a specific project, but it will exclude all environments, accounts, external feeds, tenants, and lifecycles, as those differences will likely be differences between the two instances.  

Please refer to the [Parameter reference page](ParameterReference.md) for more details on the parameters.

The other options are:
- `OverwriteExistingVariables` - set to `false` to keep the differences preserved.  Any new variable found will be added.
- `OverwriteExistingCustomStepTemplates` - Set to `True` so the step templates are kept in sync. You might have made some recent changes to the step template.  It is important to keep them up to date.
- `AddAdditionalVariableValuesOnExistingVariableSets` - set to `false` to skip new variables values found for the same variable name.  
- `OverwriteExistingLifecyclesPhases` - Set to `false` as the two instances will have different phases.
- `CloneProjectChannelRules` - set to `true` as you'll want to include the channel rules with the project.
- `CloneTeamUserRoleScoping` - set to `true` as you'll want to include all the scoped permissions with the teams.
- `CloneProjectVersioningReleaseCreationSettings` - set to `false` as you'll want to exclude the release creation settings.

```PowerShell
CloneSpace.ps1 -SourceOctopusUrl "https://instance1.yoursite.com" `
    -SourceOctopusApiKey "SOME KEY" `
    -SourceSpaceName "My Space Name" `
    -DestinationOctopusUrl "https://instance2.yoursite.com" `
    -DestinationOctopusApiKey "My Key" `
    -DestinationSpace Name "My Space Name" `    
    -WorkerPoolsToClone "AWS*" `
    -ProjectGroupsToClone "all" `
    -TenantTagsToClone "all" `    
    -StepTemplatesToClone "all" `    
    -ScriptModulesToClone "all" `    
    -MachinePoliciesToClone "all" `
    -SpaceTeamsToClone "all" `
    -LibraryVariableSetsToClone "AWS*,Global,Notification,SQL Server" `
    -ProjectsToClone "Redgate - Feature Branch Example" `    
    -OverwriteExistingVariables "false" `
    -AddAdditionalVariableValuesOnExistingVariableSets "False" `
    -OverwriteExistingCustomStepTemplates "true" `
    -OverwriteExistingLifecyclesPhases "false"
    -CloneProjectChannelRules "true" `
    -CloneTeamUserRoleScoping "true" `
    -CloneProjectVersioningReleaseCreationSettings "true"
```

# Example - Mirrored Instances

This example will clone a specific project between a mirrored instance.

Please refer to the [Parameter reference page](ParameterReference.md) for more details on the parameters.

The other options are:
- `OverwriteExistingVariables` - set to `false` to keep the differences preserved.  Any new variable found will be added.
- `OverwriteExistingCustomStepTemplates` - Set to `True` so the step templates are kept in sync. You might have made some recent changes to the step template.  It is important to keep them up to date.
- `AddAdditionalVariableValuesOnExistingVariableSets` - set to `false` to skip variables values found for the same variable name.  
- `OverwriteExistingLifecyclesPhases` - Set to `false` as the two instances will have different phases.
- `CloneProjectChannelRules` - set to `true` as you'll want to include the channel rules with the project.
- `CloneTeamUserRoleScoping` - set to `true` as you'll want to include all the scoped permissions with the teams.
- `CloneProjectVersioningReleaseCreationSettings` - set to `true` as you'll want to include the release creation settings.

```PowerShell
CloneSpace.ps1 -SourceOctopusUrl "https://instance1.yoursite.com" `
    -SourceOctopusApiKey "SOME KEY" `
    -SourceSpaceName "My Space Name" `
    -DestinationOctopusUrl "https://instance2.yoursite.com" `
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
    -LibraryVariableSetsToClone "AWS*,Global,Notification,SQL Server" `
    -LifeCyclesToClone "all" `
    -ProjectsToClone "Redgate - Feature Branch Example" `
    -TenantsToClone "all" `
    -SpaceTeamsToClone "all" `
    -OverwriteExistingVariables "false" `
    -AddAdditionalVariableValuesOnExistingVariableSets "False" `
    -OverwriteExistingCustomStepTemplates "true" `
    -OverwriteExistingLifecyclesPhases "true"
    -CloneProjectChannelRules "true" `
    -CloneTeamUserRoleScoping "true"
```


