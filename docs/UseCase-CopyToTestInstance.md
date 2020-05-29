# Use Case: copying to and from test instance

Many customers like to stand up a test instance to verify upgrades.  They want a set of projects that mimic the common deployment processes as their production instance.  

This use case is supported in with the Space Cloner script.

Please refer to the [how it works page](HowItWorks.md#what-will-it-clone) to get a full list of items cloned and not cloned.

# Example

In this use case, you probably want to copy everything, but only include a handful of projects.  The example script below will copy everything in a space plus a set of specific projects.  It will only copy targets and workers related to the projects you wish to clone.

Please refer to the [Parameter reference page](ParameterReference.md) for more details on the parameters.

The other options are:
- `OverwriteExistingVariables` - set to `True`, so variables are always overwritten (except for sensitive variables).
- `AddAdditionalVariableValuesOnExistingVariableSets` - set to `True` to add new variables values found for the same variable name.  
- `OverwriteExistingCustomStepTemplates` - Set to `True` so the step templates are kept in sync. You might have made some recent changes to the step template.  It is important to keep them up to date.
- `OverwriteExistingLifecyclesPhases` - Set to `True` since this is a full clone the overwrite existing lifecycle phases has been set to true as well.
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
    -ScriptModulesToClone "all" `
    -InfrastructureAccountsToClone "all" `
    -LibraryVariableSetsToClone "all" `
    -LifeCyclesToClone "all" `
    -ProjectsToClone "Redgate - Feature Branch Example,DBUp SQL Server" `
    -TenantsToClone "all" `
    -WorkersToCLone "AWS*" `
    -TargetsToClone "AWS*" `
    -MachinePoliciesToClone "all" `
    -SpaceTeamsToClone "all" `   
    -OverwriteExistingVariables "true" `
    -AddAdditionalVariableValuesOnExistingVariableSets "true" `
    -OverwriteExistingCustomStepTemplates "true" `
    -OverwriteExistingLifecyclesPhases "true" `
    -CloneProjectChannelRules "true" `
    -CloneTeamUserRoleScoping "true" `
    -CloneProjectVersioningReleaseCreationSettings "true"
```