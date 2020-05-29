# Use Case: parent-child projects
It is easy to clone a project in Octopus Deploy.  However, once that is done, keeping the child project's process in sync with the parent project is very painful.  You have to go into each child project and update it manually.  The space cloner script was designed with this use case in mind. 

Please refer to the [how it works page](HowItWorks.md#what-will-it-clone) to get a full list of items cloned and not cloned.

## Runbooks

Right now, the runbook clone is very simple.  You tell it to sync the runbooks, or you tell it to skip the runbooks.  

# Example - Parent / Child Projects

This example is syncing the parent project in the same space.  

Please refer to the [Parameter reference page](ParameterReference.md) for more details on the parameters.

Options:
- `OverwriteExistingVariables` - set to `false` to keep the differences preserved.  Any new variable found will be added still.
- `AddAdditionalVariableValuesOnExistingVariableSets` - set to `True` to add new variables values found for the same variable name.  
- `OverwriteExistingCustomStepTemplates` - Set to `false` as its the same space instance, and this makes no sense to rune.
- `OverwriteExistingLifecyclesPhases` - Set to `false` as its the same space in the same instance, and this makes no sense to run.
- `CloneProjectChannelRules` - set to `false` as its the same space in the same instance, and this makes no sense to rune.
- `CloneTeamUserRoleScoping` - set to `false` as its the same space in the same instance, and this makes no sense to run.
- `CloneProjectVersioningReleaseCreationSettings` - set to `false` as you'll want to exclude the release creation settings.

```PowerShell
CloneSpace.ps1 -SourceOctopusUrl "https://instance1.yoursite.com" `
    -SourceOctopusApiKey "SOME KEY" `
    -SourceSpaceName "My Space Name" `
    -DestinationOctopusUrl "https://instance1.yoursite.com" `
    -DestinationOctopusApiKey "My Key" `
    -DestinationSpaceName "My Space Name" `        
    -ParentProjectName "Redgate - Feature Branch Example" `
    -ChildProjectsToSync "Redgate - Child*" `   
    -OverwriteExistingVariables "false" `
    -AddAdditionalVariableValuesOnExistingVariableSets "true" `
    -OverwriteExistingCustomStepTemplates "false" `
    -OverwriteExistingLifecyclesPhases "false" `
    -CloneProjectChannelRules "false" `
    -CloneTeamUserRoleScoping "false" `
    -CloneProjectVersioningReleaseCreationSettings "false"
```